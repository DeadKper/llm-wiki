# Team Wiki: Multi-Domain

Multiple shared knowledge areas for a team that owns several concerns.

---

## CLAUDE.md domain table

```markdown
| Domain ID  | Name       | Root folder        |
|------------|------------|--------------------|
| `backend`  | Backend    | `wiki/backend/`    |
| `platform` | Platform   | `wiki/platform/`   |
| `ops`      | Operations | `wiki/ops/`        |
```

Adapt to your team's actual domain boundaries.

---

## Domain roles

**`backend`** — systems the team directly owns and operates.

**`platform`** — adjacent infrastructure the team depends on but doesn't own.
Captures the interface, not the implementation.

**`ops`** — incident guides, escalation paths, on-call knowledge. Cross-cuts backend
and platform.

See `examples/team-wiki/domains/systems-domain.md` for domain convention templates.

---

## Directory structure

```
wiki/
├── backend/     # sources, concepts, entities, runbooks, decisions, incidents
├── platform/    # sources, concepts, entities, dependencies
├── ops/         # incidents, guides
└── shared/      # cross-domain pages
```

---

## Cross-domain connections

```markdown
### backend ↔ platform
- Shared infrastructure — backend operates, platform owns
- Deployment dependencies

### backend ↔ ops
- Runbooks reference backend architecture
- Incidents link to affected systems

### platform ↔ ops
- Platform outages that impact backend — cross-team incidents
- Escalation paths to platform team
```

---

## Team workflow

| Activity | Frequency |
|----------|-----------|
| `> ingest [domain] raw/[domain]/doc.md` | Every new source |
| `> digest sessions` | Start of week |
| `> lint` | Mid-week |
| `> crystallize [title]` | After incidents or completed investigations |

---

## Git

```bash
git add wiki/ CLAUDE.md wiki/log.md wiki/index.md
git commit -m "wiki: [description]"
# sessions/ gitignored — stays local per person
```

---

## Personal preferences

Each team member runs a private companion wiki repo. Points to it via
`.claude/personal-wiki-path` (gitignored) — preferences load per-person at session
start without touching the shared repo.
See `examples/team-wiki/domains/personal-companion.md`.
