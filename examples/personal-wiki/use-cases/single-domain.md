# Personal Wiki: Single Domain

One knowledge area alongside personal context. Good for someone focused on one
thing — a deep research project, a side business, a skill you're building.

---

## CLAUDE.md domain table

```markdown
| Domain ID  | Name     | Root folder      |
|------------|----------|------------------|
| `me`       | Personal | `wiki/me/`       |
| `research` | Research | `wiki/research/` |
```

Or single-purpose with no personal domain:

```markdown
| Domain ID  | Name    | Root folder     |
|------------|---------|-----------------|
| `reading`  | Reading | `wiki/reading/` |
```

---

## What to ingest

Articles, books, papers, notes, journal entries, podcast transcripts — whatever
feeds the knowledge area you're tracking.

---

## Page types

- `sources/NAME.md` — one per ingested document
- `concepts/NAME.md` — ideas, frameworks, mental models
- `entities/NAME.md` — people, tools, orgs
- `me/preferences/NAME.md` — LLM interaction rules (if using personal domain)

---

## Git

```bash
git init && git add -A && git commit -m "init wiki"
```

Keep the repo private. Session exports are gitignored — local only.
