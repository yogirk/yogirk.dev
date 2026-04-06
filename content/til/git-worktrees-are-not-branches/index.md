---
title: "Git Worktrees Are Not Branches"
date: 2026-04-06T17:33:22+05:30
draft: false
tags: ["Git", "TIL", "Developer Tools", "Architecture"]
description: ""
---

Today I ran into a scenario where using Git worktree would have avoided a lot of work. Close to 2K lines of reconciliation, because I was trying to redesign the deliberation report viewer for [agent-council](https://github.com/yogirk/agent-council) in 2 different branches, with 2 different agents - Claude, Gemini/Stitch. So I ended up with 2 versions of `viewer.ts`.  

The reflog tells the story. This is from branch#1 

```bash
HEAD@{13}  checkout: main → v0.3.0-epistemic-debugger
HEAD@{12}  commit 230ed90: v0.3.0 (big feature commit, touches viewer.ts)
HEAD@{11}  commit f4623ce: "10 design audit fixes for viewer"
HEAD@{10}  reset: moving to HEAD
HEAD@{9}   rebase (start): checkout origin/main
HEAD@{8}   rebase (continue): → produces 64c6778
HEAD@{7}   rebase (finish)
```
Meanwhile [PR#5](https://github.com/yogirk/agent-council/pull/5), from a different branch was also the redesign that I finally wanted to stick with. This was merged first and then the `v0.3.0-epistemic-debugger` got rebased onto the updated main immediately after. The damage of the collision is that the diff between pre-rebase and post-rebase, there was 2258 lines changes in viewer.ts alone, which was just reconciliation from the rebase - not feature work. Claude Code handled the rebase, but still - not efficient. 

## Worktree would have helped
This is when I was researching to understand what we could have done better and it gave me an opportunity to understand things with more clarity. With worktree, it would have looked like this:

```bash
~/Projects/building/agentcouncil/          → v0.3.0-epistemic-debugger (feature work)
~/Projects/building/agentcouncil-viewer/   → claude/dazzling-wiles (viewer redesign)
```
Both running simultaneously, both viewers open in a browser, compared side-by-side. If there overlap, it gets caught _before_ either PR lands instead of being discovered at rebase time. In this case, the extra lines of work becomes a deliberate merge than a careful rebase. 

### Branch vs Worktree
- A branch in git is just a pointer, it's a small file that holds a commit hash. When you run `git checkout my-awesome-branch`, git just rewrites the files in the working directory to match that branch. So, any given point in time, we only have one set of files on the disk. 
- This can become a problem, when you are building something on `branch1` with uncommitted changes, and you need to review a PR on `branch2`. You have to either commit incomplete work or stash it, switch branches, do your review, switch back and unstash. Again, agents can do this without any issue - but is this the most efficient way? 
- A worktree on the otherhand, gives you a second or many more working directories that share the same `.git` repository. Each worktrees will have its own checked-out branch and its own set of files on disk but they all have common commit history, refs and object store. In a way, the normal repo is already a worktree. Just that its the "main" worktree. Git doesn't allow you to have two worktrees with same branch checkout, though. This avoids conflicting index states. 

## What did we learn?
When two branches touch the same set of files (in our case, the agent deliberation report viewer `viewer.ts`), and both branches are in-flight simultaneously, worktree is probably more efficient. For everything else, if you build in sequential phases and ad-hoc fixes, normal branches are fine. Worktree isn't use-always tool - if you have two trains heading for the same track, use worktrees.
