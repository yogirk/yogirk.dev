---
title: "Why I Gave Up on Remote-Controlling Gemini CLI (With a Working Prototype)"
date: 2026-04-01
draft: false
description: ""
tags: ["Gemini CLI", "Claude Code", "Architecture", "MCP", "PWA", "Developer Tools"]
categories: ["Engineering"]
summary: ""
toc: true
---
This was in my drafts for far too long. Things are changing rapidly, with the Claude Code codebase leak this week and these tools evolving daily holding it any longer risks making the learnings dated. I will start with a disclaimer Gemini CLI is probably last in my lineup of preferred agent harnesses — behind Claude Code, Codex, pi.dev, opencode. But that's one of the reasons why I chose it for this exercise. I wanted to understand _why_ some of these tools feel fast and some don't, _why_ Claude Code's remote control feels native while no equivalent exists (yet) for Gemini. Building the thing myself felt like the best way to find out. So when Claude remote was first announced a few weeks ago, I started building the equivalent for Gemini CLI. This post is mainly about how I failed and what I learned along the way 

## The Insight - It's Not About Code, It's About Architecture
Claude Code's remote control is not a feature bolted on the side, it works because of the underlying architectural decisions that were made long before remote control became a feature. 

1. Claude Code uses `api.anthropic.com` as a message relay between the cli on your laptop and the phone UI. Both the cli and the phone talk to Anthropic's servers over https. There is no need for tunnels, port forwarding, ephemeral URLs. It just works through firewalls and NATs. 

2. Claude Code is built on React/Ink. Its internal state is already a structured component tree - Prompts, tool calls, diffs, status updates etc. The relay sends these as high-level JSON messages and the web UI at claude.ai/code renders them natively because it was built to understand that exact protocol

3. This is killer. The CLI polls for the remote input even when it is idle. There is a separate thread that continuously polls `api.anthropic.com ` for messages from the phone. Remote prompts and local terminal input feed into the same internal async queue. Basically the agent loop is input/source agnostic. It doesn't care whether a message came from your keyboard or your phone. 

So the most important lesson is - these are the things that can not be added by mere extension. These are architecture choices. 

## So, What I had to Build Instead? (And Why It Was a Failure)
Without a centralized relay, structured message emission, and idle polling - here is what I duct-taped together:

### 1. No relay -> Cloud Flare Quick Tunnels
Since Google doesn't provide   `api.google.com` relay, I used `untun` (Cloudflare Quick Tunnels). I considered ngrok first, but I had used it in the past while building another Gemini extension - [gemini-callme](https://github.com/yogirk/gemini-callme) and the experience has not been good with the free version. The ngrok process lingers on and each time I had to ps -ef to kill it. So with `untun` I ran into the following issues 
- **The URL changes every time**: This is not a persistent endpoint, every session restart means a new QR code scan.
- **SSE is broken**: Cloudflare Quick Tunnels buffer server-sent events until connection close, completely defeating the purpose. I confirmed this from their docs and from cloudflared [issue #1449](https://github.com/cloudflare/cloudflared/issues/1449). 
- **Websocket works, sort of**: 100-second idle timeout requires ping/pong keepalives. Periodic `close 1006` disconnections from Cloudflare edge deployments. Phone sleep kills the connection. 
- **No SLA**: Well, this is a free service

In Claude code - all you need to do is HTTPS to `api.anthropic.com`. And you are good to go. No tunnel management, no transport quirks. 

### 2. No structured messages -> Hook event reconstruction
This was most interesting discovery for me. Gemini CLI doesn't emit structured conversation events to extensions. Instead, I intercepted lifecycle hooks

```
LLM generates chunk → AfterModel hook fires → shell script POSTs to sidecar → sidecar pushes via WebSocket → PWA appends to bubble
```

This *works*, but it's fundamentally different from what Claude Code does. I'm kind of reconstructing the conversation from event fragments rather than receiving authoritative structured messages from the source. Every hook invocation means a new shell process and `curl`, which adds ~5-10ms overhead per chunk streamed. The events are incomplete, basically. The alternative without hooks is terminal emulation with xterm.js, which defeats the purpose of the remote plugin / extension altogether. It's terrible on phones, no responsive layout etc. 

### 3. The idle problem (the killer)
This is the one that made me stop. 

Claude Code's CLI polls for remote messages on a separate thread, even when sitting at the input prompt doing nothing. A message from your phone enters the same queue as a message from your keyboard - the agent doesn't know the difference. Gemini CLI hooks **only fire during active model turns**. When the CLI is idle at the stdin prompt waiting for you to type, **nothing fires**. No hooks, no events, no way in. 

I tried to find alternative ways. 
- **AfterAgent hook injection** - when the model finishes a turn, check for queued remote prompts and inject them via `{decision: "deny", reason: "<prompt>"}`. Works ~80% of the time (any time the model is active).
- **MCP tool fallback** — instruct the model in GEMINI.md to call `check_remote_queue` before going idle. But I don't think it's reliable — the model ignores it whenever it wants.

So the remaining 20% of the time, when you pick up your phone, the CLI is sitting idle, and you want to type - "hey, let's ship now" , this simply won't work because the prompt sits in a queue until *something else* triggers a hook. There is an open issue - [#15338](https://github.com/google-gemini/gemini-cli/issues/15338) requesting daemon server mode that would fix this. Good news is that there is an approved PR for this and hope it gets merged. 

### 4. Stderr suppression
Another smaller but telling example. I wanted to print the QR code to stderr on startup so the user could scan it. Gemini CLI suppresses stderr output from MCP servers. Now the QR code is invisible :) My workaround was - expose a `get_connection_info` MCP tool and instruct the model in GEMINI.md to call it on session start, then display the connection URL and QR code to the user. This is a hack, not a real solution. 

## The Constraints

Looking back, we have 3 types of problems. 

- **Fixable by me** (with the help of agents, of course): Transport reliability (solved), Authentication - QR + JWT (solved), event buffering and catch-up(solved), PWA UI and mobile UX (kind of solved)
- **Fixable by Gemini CLI maintainers** Idle prompt injection (needs daemon mode or relay), Stderr suppression from MCP, Inability to trigger model turns from extensions 
- **Architectural** -  No centralized relay, CLI emits terminal output, not conversation events, no web UI counterpart 


The lesson is that you can't bolt on first-party quality with third-party tools. Might as well wait for Gemini CLI to implement it natively. It's just that the journey towards that conclusion has been educational :) 

