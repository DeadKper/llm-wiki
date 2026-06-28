# Team Wiki: Single Domain

One shared knowledge area. Good for a small team owning one system or product.

---

## CLAUDE.md domain table

```markdown
| Domain ID  | Name   | Root folder      |
|------------|--------|------------------|
| `DOMAIN_1` | [Name] | `wiki/DOMAIN_1/` |
```

Delete DOMAIN_2 and DOMAIN_3 rows.

---

## What to ingest

Runbooks, architecture docs, design decisions, incident postmortems, meeting notes,
external articles relevant to the team's systems.

---

## Page types

- `sources/NAME.md` — one per ingested document
- `concepts/NAME.md` — systems, patterns, frameworks
- `entities/NAME.md` — services, people, teams
- `runbooks/NAME.md` — ops procedures (add to domain conventions)
- `decisions/NAME.md` — architectural/team decisions

See `examples/team-wiki/domains/systems-domain.md` for full page format templates.

---

## Git setup

```bash
git init && git add -A && git commit -m "init team wiki"
git remote add origin git@github.com:your-org/team-wiki.git && git push -u origin main
```

---

## Personal preferences

Individual preferences stay out of this repo. Each team member runs a private
companion wiki and points to it via `.claude/personal-wiki-path` (gitignored).
See `examples/team-wiki/domains/personal-companion.md`.
