---
title: "Why I build things"
date: 2026-04-04
draft: false
description: "Building is how I learn. The tools are often a side effect; the real output is domain understanding."
tags: ["Building", "Personal"]
categories: ["Essays"]
summary: "Using a tool teaches you the tool. Building your own teaches you the domain. That is why I keep making things, even when something usable already exists."
toc: false
---
## We shall not cease from exploration...! 
I ran into [emdash](https://emdashcms.com/) yesterday on HN. I am neutral about the product itself, never did like Wordpress way of doing things before. However, I found their [Learning in Public](https://emdashcms.com/posts/learning-in-public) post and it articulated something I had already been feeling for a while.

I feel the same way about building.

That post made me ask a parallel question: why do I build things at all? Right off the bat, one important part of the answer is that now, thanks to Gen AI, there is much less friction to the act of building. That is a catalyst, but not the cause.

In the last few months, I have built [Ravana](https://github.com/yogirk/ravana) (multi-AI desktop app), [TGCP](https://github.com/yogirk/tgcp) (terminal GCP explorer), [Cascade](https://github.com/yogirk/cascade) (data engineering agent), [Selecta](https://github.com/yogirk/selecta) (NL analytics), [Pulijoodam](https://github.com/yogirk/pulijoodam) (board game), and [agent-council](https://github.com/yogirk/agent-council) (a terminal-based agent council skill). Cascade might turn into something long-term and more serious, but back to the main question: most of these things have alternatives, so **why build?**

The answer is: building your own thing _is_ the learning. The thing itself is a side effect. The process is the point. Using an existing tool teaches you the tool. Building your own version teaches you the domain.

## Below the surface
Taken together, these projects all follow the same pattern. In every case, something usable already existed. A browser already gives me tabs. GCP already has a console and a CLI. Analytics tools already turn data into charts. Board games already exist as apps. That was never the point. The point was that building them forced me below the surface.

- [Ravana](https://github.com/yogirk/ravana) taught me that “just wrap websites in a desktop app” is not actually simple once you care about session isolation, persistent login, and tab state. 
- [TGCP](https://github.com/yogirk/tgcp) taught me more about GCP APIs, caching, pagination, and terminal UX than the official console ever could. Some of what I learned building TGCP helped me build Cascade with more clarity. 
- [Cascade](https://github.com/yogirk/cascade) is teaching me what it actually means to build an agent, not just use one: tool registries, permission models, context compaction, streaming execution, risk classification. 
- [Selecta](https://github.com/yogirk/selecta) taught me how text-to-SQL, streaming responses, and chart rendering actually work under the hood. 
- [Pulijoodam](https://github.com/yogirk/pulijoodam) taught me game AI, WebRTC state sync, and the difference between playing a game and understanding how one is constructed.

That is the recurring pattern for me. Using a thing gives you the surface area. Building it forces you to confront the internals. You stop seeing software as magic and start seeing the moving parts: state, trade-offs, protocols, failure modes, constraints, taste.

## The deeper argument

Using a tool teaches you the tool. Building your own teaches you the domain.

If you use Metabase for a year, you learn Metabase: its query builder, its dashboard model, its configuration, its limits. If you build [Selecta](https://github.com/yogirk/selecta), you learn text-to-SQL, streaming architecture, agent design, Vega-Lite, and SSE. The tool is almost a side effect. The domain knowledge is the real output.

Same with everything else. If you use a browser, you learn tabs as a user. If you build [Ravana](https://github.com/yogirk/ravana), you learn session isolation, persistent login, and why tab state is harder than it looks. If you use the GCP Console, you learn where things are. If you build [TGCP](https://github.com/yogirk/tgcp), you learn how GCP APIs actually behave: pagination quirks, caching trade-offs, error handling, latency, and all the little inconsistencies that polished UIs hide from you.

This is probably why the Feynman line gets quoted so much: "What I cannot create, I do not understand." Whether or not he meant it in the exact way people use it now, the underlying idea is still right. Building forces you to confront detail. When you use a terminal UI, you do not think about cursor movement, alternate screen buffers, raw mode input, or clipboard weirdness. When you build one, you do.

That is why I keep coming back to this. The payoff is double. I learn the domain, and I end up with a tool shaped around exactly what I wanted. It may not be as polished as the incumbent. It may not even be finished. But the understanding is real.

## What this is not

This is not [NIH syndrome](https://en.wikipedia.org/wiki/Not_invented_here). NIH is when you refuse to use an existing tool in a context where you obviously should, usually because you are too attached to the idea of building your own. That is ego. I am talking about something else: choosing to build on personal time because building is itself the method of learning. At work, I would rather use the best tool that already exists. Outside work, I am often more interested in understanding the problem space than in maximizing immediate efficiency.

It is also not necessary for the project to beat the existing tool, or even to fully ship. [TGCP](https://github.com/yogirk/tgcp) has releases. [Ravana](https://github.com/yogirk/ravana) has published builds. [Pulijoodam](https://github.com/yogirk/pulijoodam) is playable. [Cascade](https://github.com/yogirk/cascade) is still becoming whatever it will become. But even if a project stalls halfway, the learning does not evaporate with it. That part stays.

## So I will keep building

I do not have a grand conclusion beyond that.

I have more ideas than I can realistically execute. More half-formed instincts than time. More enthusiasm than discipline, on some days. But that is fine. I do not think I need to force a master plan out of it.

For now, the goal is simpler: keep my head down, keep building, keep learning. Follow the ideas that refuse to leave me alone. Let some of them die. Let some of them turn into tools I use every day. And maybe, somewhere in that process, something truly good will present itself.

Until then, the work is still worth doing.
