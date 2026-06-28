# Domain: Team Systems (`backend`, `platform`, `ops`, etc.)

A domain covering systems the team owns or operates — architecture, runbooks,
incidents, decisions. The core domain type for any team wiki.

---

## CLAUDE.md entry

```markdown
| `backend` | Backend | `wiki/backend/` |
```

Rename to match your team's actual system boundary.

## Domain Conventions

```markdown
### `backend` — Backend

**Purpose**: Owned systems knowledge base. Architecture, runbooks, incidents,
decisions, and anything the team needs to operate and evolve the stack.

**Key pages to seed early**:
- Architecture overview (owned systems)
- Team decision log
- On-call runbook index

**Domain-specific page types**:
- `runbooks/NAME.md` — step-by-step operational procedure
- `decisions/NAME.md` — architectural or team decision with rationale
- `incidents/NAME.md` — post-incident analysis

**Special rules**:
- Strip credentials and internal tokens before ingesting source material
- Incidents must include: timeline, impact, root cause, action items
- Decisions must include: context, decision, rationale, consequences
- Authoritative source for owned systems — prefer this domain over adjacent ones
```

---

## Directory structure

```
wiki/backend/
├── overview.md
├── sources/
├── concepts/
├── entities/
├── runbooks/
├── decisions/
└── incidents/
```

---

## Example page formats

### runbooks/NAME.md

```markdown
---
title: "Runbook: [Alert or Procedure]"
domain: backend
service: [service-name]
last_verified: YYYY-MM-DD
confidence: 0.9
memory_tier: procedural
---

## Trigger
When this runbook applies.

## Steps
1. Step one
2. Step two

## Escalation
Who to contact if this doesn't resolve.

## Related
- [[concepts/related-system]]
```

### decisions/NAME.md

```markdown
---
title: "Decision: [Title]"
domain: backend
date: YYYY-MM-DD
status: proposed | accepted | superseded
confidence: 1.0
memory_tier: semantic
---

## Context
Why this decision was needed.

## Decision

## Rationale

## Consequences

## Supersedes
[[decisions/older]] (if applicable)
```

### incidents/NAME.md

```markdown
---
title: "Incident: [Title]"
domain: backend
date: YYYY-MM-DD
severity: p0 | p1 | p2
status: open | resolved
confidence: 1.0
memory_tier: episodic
---

## Timeline

## Impact

## Root Cause

## Action Items
- [ ] Item (owner: @person)

## Related
- [[entities/affected-system]]
```
