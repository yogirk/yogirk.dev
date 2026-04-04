---
title: "Why Terminal TUI Apps Can't Have Both Scroll and Text Selection"
date: 2026-03-24
draft: false
description: ""
tags: ["Terminal", "TUI", "Bubbletea", "Go", "UX", "Cascade"]
categories: ["Engineering"]
summary: ""
toc: true
---
## The Background
I am currently building [Cascade](https://github.com/yogirk/cascade), AI-native terminal agent for GCP data engineering. Think Claude Code and Cortex CLI - but for GCP data engineering. However, this is still pre-alpha and I might end up scrapping the current project completely, in favour of some other stack in future, depending on what I learn while building this. However, as things stand today - Cascade is a Go terminal app, built on [Bubble Tea v2](https://github.com/charmbracelet/bubbletea), styled with [Lip Gloss](https://github.com/charmbracelet/lipgloss) and I am also using the Charm ecosystem in general for components like viewports, keymaps, and terminal mouse handing. The first time I got to explore this stack was when I was building another TUI app for GCP called, well, [TGCP](https://github.com/yogirk/tgcp) :) 

We will talk more about Cascade, as we go along - but I wanted to document a specific problem I ran into while building this, and what I learnt from it. 

## The Problem
Cascade is a wannabe Claude Code or Codex with GCP data engineering super powers. While building, I ran into an interesting scenario. Enabling trackpad/mouse scroll broke text selection and fixing text selection broke scroll. Every fix for one resulted in regression in the other. I initially thought it was a Bubble Tea bug or a Lip Gloss limitation, or maybe I am not using these things the right way. Turns out, it's not. It's a 40 year old terminal protocol constraint 

Let me explain

## The Investigation

### What we tried (and failed)

- **`MouseModeCellMotion` + filtering only wheel events** — We set xterm mode 1002, then in our `OnMouse` handler only processed wheel events and ignored clicks. Scroll worked. But text selection was still broken because the *terminal* never sees the click events — Bubble Tea intercepts them at the protocol level before the terminal can use them for selection.
- **Different viewport configurations** - We tried disabling viewport's built-in mouse handling, tried custom scroll handlers. The problem was same: mouse mode is set at the terminal level, not at the component level. 
- **Troubleshooting Loop** - Each time we fixed the scroll, selection broke. Fix selection, scroll broke. 

### And the root cause was
 The xterm mouse protocol (from the 1980s) has these following modes

| Mode            | Code     | What It Captures                          |
| --------------- | -------- | ----------------------------------------- |
| X10             | 9        | Button presses only                       |
| Normal          | 1000     | Button press + release                    |
| **ButtonEvent** | **1002** | Button press + release + drag + **wheel** |
| AnyEvent        | 1003     | Everything including hover                |

The wheel events are bundled with the button events in mode 1002. So, you can not get wheel events without capturing clicks and drags. 

When mode 1002 is active:
- Your app gets wheel events (scroll works)
- Your app gets click/drag events (intercepts the terminal's normal drag-selection path)
- Unmodified drag selection no longer works the way it does in a plain terminal buffer
- Many terminal emulators provide a modifier-key bypass such as Option+drag or Shift+drag for selection

When no mouse mode is active (mode 0):
- The terminal handles everything (text selection works perfectly)
- Your app gets no mouse events (no wheel scroll)
- Scrolling must be keyboard-only (arrow keys, PgUp/PgDn)

### Bubble Tea's options 
Bubble Tea V2 exposes exactly what the protocol allows

```go
MouseModeNone       // No mouse events. Terminal handles everything.
MouseModeCellMotion // Mode 1002: wheel + click + drag. Steals selection.
MouseModeAllMotion  // Mode 1003: everything including hover. Even worse.
```
No `MouseModeWheelOnly` because the terminal protocol doesn't support it.

### It gets interesting 

At this point, I had the immediate answer: the direct cause of the problem is mouse reporting, not Bubble Tea itself. But that still leaves a bigger question. Why does this trade-off feel so painful in apps like Cascade, while in normal terminal workflows text selection and scrolling feel effortless? That is where the alternate screen enters the picture.

## The Deeper Insight: Mouse Mode Is the Direct Cause, Alt Screen Shapes the UX

The direct reason text selection gets intercepted is mouse mode. If you enable mode `1002` to get wheel or trackpad scroll events, the terminal stops handling normal drag selection the way it does in a plain terminal buffer. But alt screen changes the interaction model around that constraint.

When your app runs in the normal terminal buffer:
- the terminal keeps scrollback
- native text selection works naturally
- scrolling is mostly the terminal's job

When your app runs in the alternate screen:
- there is no normal terminal scrollback for the app session
- the app is expected to manage more of its own viewport behavior
- enabling mouse mode becomes much more tempting if you want trackpad-style scrolling inside the UI

So alt screen is not the direct cause of the selection problem. Mouse reporting is.

Alt screen just makes you run into the problem much faster. Once you are building a full-screen terminal app, you stop relying on the terminal's native scrolling model and start wanting app-managed scrolling. The moment you want that smooth trackpad or wheel-based scrolling inside the app, you reach for mouse mode `1002`, and that is when normal terminal drag selection gets intercepted.

That was the part I missed initially. I thought I was dealing with a component-level issue in Bubble Tea, maybe something around the viewport or mouse handler configuration. But the problem sits one layer lower, in the terminal protocol itself.

## Why this feels different from Claude Code or Codex
This also explains why tools like Claude Code and Codex feel fundamentally different.

They live in the normal terminal buffer. Output streams into the terminal like any other CLI session, so:
- the terminal keeps the scrollback
- text selection works the way users already expect
- mouse-driven scrolling is handled by the terminal emulator, not by the app

A full-screen TUI like Cascade is making a different trade-off. It gives you a more controlled interface, but it also means you inherit more responsibility for things the terminal normally does for free.

That is why this is not just a small implementation detail. It is a product decision.

## How do we solve it in Cascade? 

Cascade currently runs with alt screen enabled and `MouseModeCellMotion` turned on. That means:
- trackpad scroll works
- normal drag selection is intercepted
- terminal-emulator bypasses like `Option+drag` on macOS or `Shift+drag` on some Linux terminals can still work

So the current behavior is not "selection is impossible." It is more specific than that: normal terminal-native drag selection is no longer the primary path.

And this is where I decided to look at [crush](https://github.com/charmbracelet/crush) (from Charmbracelet ecosystem) to see how they solve it. It was an apt choice because it is built using similar stack as Cascade. Turns out, they **implemented their own app-level text selection and clipboard copy inside the TUI**. That's so simple, I didn't think of it before.

The constraint is not that a full-screen TUI can never support both scrolling and selection. The actual constraint is narrower:
- you cannot have wheel scrolling and terminal-native drag selection through the same xterm mouse reporting path
- but you can keep wheel scrolling and build your own selection model inside the app

That is exactly why `crush` can support drag-to-select without falling back to `Shift+drag`, even though it is making the same low-level mouse mode choice.

## How do we decide? 

```text
Is your app mostly conversational?
  -> Stay in the normal buffer and let the terminal handle scrollback and selection

Is your app a full-screen dashboard or workspace?
  -> Use alt screen and accept that terminal-native selection gets more complicated

Do you want full-screen UI and drag-to-select?
  -> You probably need to implement app-level selection yourself
```

That was the real takeaway for me.

The problem was not "Bubble Tea cannot do both." The problem was that I was mixing up terminal-native behavior with app-managed behavior. Once I understood that, I realized the trade-off was much clearer. I might just end up imitating crush :) 