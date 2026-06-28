# Personal Wiki: Multi-Domain

Multiple knowledge areas for one person. Common pattern: personal context + work knowledge
+ one or more learning/interest areas.

---

## CLAUDE.md domain table

```markdown
| Domain ID  | Name     | Root folder       |
|------------|----------|-------------------|
| `me`       | Personal | `wiki/me/`        |
| `work`     | Work     | `wiki/work/`      |
| `learning` | Learning | `wiki/learning/`  |
```

Adjust to what you actually track. Some people add `reading`, `health`, `side-projects`.
If you want preferences tracked separately from this wiki entirely, keep `me` out
and use the companion wiki pattern instead of adding a `me` domain here.

---

## Domain roles

**`me`** — preferences, projects, career context. Loaded at session start if linked as
a companion wiki from elsewhere. See `examples/personal-wiki/domains/personal-domain.md`.

**`work`** — your perspective on work topics. Not canonical docs (those live in the team
wiki if one exists) — your notes, questions, onboarding learnings, personal decisions.

**`learning`** — anything you're actively studying. Papers, courses, books, experiments.

---

## Cross-domain connections

```markdown
### me ↔ work
- Learning goals tied to work systems
- Personal notes on colleagues or teams

### me ↔ learning
- Interests that overlap with personal projects
- Skills you're building toward career goals

### work ↔ learning
- Papers or courses directly applicable to work problems
- Techniques learned and applied at work
```

---

## Workflow

```
> ingest me raw/me/journal-entry.md
> ingest work raw/work/meeting-notes.md
> ingest learning raw/learning/paper.md
> crystallize [title]       # after finishing a thread
> digest sessions            # weekly
> lint                       # monthly
```

---

## Git

```bash
git init && git add -A && git commit -m "init wiki"
```

Keep private. If `me` domain contains truly sensitive content and you want it
separate from the rest, see the companion wiki pattern in
`examples/personal-wiki/domains/personal-domain.md`.
