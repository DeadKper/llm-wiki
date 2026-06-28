# Domain: Personal (`me`)

Tracks you as a person — preferences, projects, notes, career context, LLM rules.
The foundation of any personal wiki. Usually named `me`, `personal`, or similar.

---

## CLAUDE.md entry

```markdown
| `me` | Personal | `wiki/me/` |
```

## Domain Conventions

```markdown
### `me` — Personal

**Purpose**: Everything about you as a person and individual contributor — LLM
interaction preferences, work style, personal projects, career context, goals.

**Key pages to seed early**:
- `preferences/tone.md` — how the LLM should communicate with you
- `preferences/depth.md` — how much context/explanation you want
- `projects/active.md` — what you're currently working on
- `concepts/mental-models.md` — frameworks you apply repeatedly

**Domain-specific page types**:
- `preferences/NAME.md` — LLM interaction rules (loaded at session start if linked)
- `projects/NAME.md` — personal or side project with status and stack

**Special rules**:
- Treat this domain as context for *how* to respond, not just *what* to respond with
- When the user states a preference mid-session, file it here
- High-trust — content reflects your own words; don't editorialize
```

---

## Directory structure

```
wiki/me/
├── overview.md
├── preferences/
│   ├── tone.md
│   ├── depth.md
│   └── response-format.md
├── projects/
│   └── NAME.md
├── concepts/
│   └── NAME.md
└── entities/
    └── NAME.md
```

---

## Example page: preferences/tone.md

```markdown
---
title: "Preference: Tone"
domain: me
category: tone
last_updated: YYYY-MM-DD
memory_tier: procedural
confidence: 1.0
---

## Rule
Terse. Drop articles and filler. Code over prose. No summaries at end of response.

## Why
I read fast and prefer signal density over hand-holding.

## Applies to
global
```

## Example page: projects/NAME.md

```markdown
---
title: "Project: [Name]"
domain: me
status: active | paused | archived
stack: []
started: YYYY-MM-DD
confidence: 0.9
memory_tier: semantic
---

## Goal

## Current State

## Key Decisions

## Related
- [[concepts/related]]
```

---

## Preference loading

If you link this wiki from another wiki, its `load-personal-prefs.py` hook will read
`wiki/me/preferences/*.md` (and any other `*/preferences/*.md`) at session start.

```bash
# in the other wiki (gitignored)
echo "/path/to/my-personal-wiki" > .claude/personal-wiki-path
```
