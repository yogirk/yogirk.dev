---
title: "Hugo Content Sections"
date: 2026-03-24
draft: false
tags: ["hugo", "blogging"]
description: "Hugo uses directory structure under content/ to define content sections, each with its own templates and behavior."
---

Hugo organizes content into **sections** based on the directory structure under `content/`. Each top-level directory becomes a section:

```
content/
├── posts/    → section "posts"
├── til/      → section "til"
└── pages/    → section "pages"
```

Each section can have its own:
- List template (`layouts/{section}/list.html`)
- Single template (`layouts/{section}/single.html`)
- Archetype (`archetypes/{section}.md`)

The `mainSections` config parameter controls which sections appear on the homepage. This is how you can have TILs live alongside posts without mixing them in the main feed.
