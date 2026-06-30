# AGENTS.md — LLM Wiki Schema
# [YOUR WIKI NAME] · Codex / OpenAI adapter
#
# 1. Replace DOMAIN_1, DOMAIN_2, DOMAIN_3 with your actual domain names
# 2. Fill in Domain Conventions below
# 3. No automatic hooks — export sessions manually after each session
# ══════════════════════════════════════════════════════════════

---

## Overview

A **multi-domain LLM Wiki** — persistent, compounding knowledge base.
You (the LLM) do all writing, filing, cross-referencing, and bookkeeping.
The human sources documents and asks questions.

Active domains:

| Domain ID  | Name             | Root folder        |
|------------|------------------|--------------------|
| `DOMAIN_1` | [Domain 1 Name]  | `wiki/DOMAIN_1/`   |
| `DOMAIN_2` | [Domain 2 Name]  | `wiki/DOMAIN_2/`   |
| `DOMAIN_3` | [Domain 3 Name]  | `wiki/DOMAIN_3/`   |

Add, rename, or remove domains freely. Cross-domain connections create pages under `wiki/shared/`.

---

## Session export (manual)

Codex has no automatic hooks. At end of each session:
```bash
python3 scripts/export-session.py --trigger manual
bash scripts/index-sessions.sh
```

Add `wikiexit` to your shell profile for convenience (see SETUP-GUIDE.md).

## Session start behavior

At the start of every session, before answering any questions:
1. Read `wiki/log.md` tail to understand recent activity: `grep "^## \[" wiki/log.md | tail -10`
2. Identify which domains were active recently
3. Note open research threads (`research/threads/` with `status: active`)

Skip steps 2–3 if the wiki is empty or this is a bootstrap session.

---

## Core rules

1. On every ingest: extract entities with typed relationships, confidence-score claims, check for supersessions. Typically 8–15 pages touched per source.
2. On every query: traverse typed relationships, not just keyword search.
3. Always update `wiki/index.md`, the relevant `wiki/[domain]/[subdir]/index.md`, `wiki/[domain]/[subdir]/log.md`, `wiki/[domain]/log.md`, and `wiki/log.md` on every ingest.
4. Supersede, don't overwrite: when new info contradicts old, set `superseded_by` on the old page.

---

## Operations

### `> ingest [domain] raw/path/to/file.md`
1. Read source, strip sensitive data (API keys, tokens, PII)
2. Brief 2–3 sentence takeaway
3. Extract entities with typed relationships (`uses` / `depends_on` / `contradicts` / `caused` / `fixed` / `supersedes` / `owns` / `impacts`)
4. Create `wiki/[domain]/sources/SLUG.md` — no `confidence` or `memory_tier` on source pages
5. For each existing entity/concept page this source touches:
   - Corroborates claim: add to `## Sources` list, raise `confidence` by 0.05 (cap 1.0), update `last_confirmed`
   - Contradicts claim: determine weaker by priority — (1) `source_authority`, (2) sources list length, (3) `last_confirmed`, (4) `confidence`; `superseded_by` on weaker page, mark stale, log supersede line
6. Update `wiki/index.md`
7. Update `wiki/[domain]/[subdir]/index.md` — add new entry, update entity graph if relationships changed
8. Append to `wiki/[domain]/[subdir]/log.md` and `wiki/[domain]/log.md`
9. Check cross-domain connections → `wiki/shared/`
10. If this source meaningfully shifts the domain's picture, update `wiki/[domain]/overview.md`; if it shifts cross-domain synthesis, update `wiki/overview.md`
11. If qmd is available, run `qmd update` to re-index the new pages (then `qmd embed` if vector index is in use); always keep `wiki/index.md` up to date regardless
12. Append to `wiki/log.md`; report: files touched, entities extracted, corroborations, supersessions

### `> [question]` — query
1. Check sessions: `bash scripts/recall.sh "[keywords]"`
2. Find relevant wiki pages:
   - If qmd available: use `qmd search` (exact terms) or structured `qmd query` with `intent:`/`lex:`/`vec:` fields; pass collection name(s) via `-c <name>`. Collection names come from `.claude/wiki-search-config` (`WIKI_COLLECTIONS`); default to the wiki's own collection.
   - Otherwise: read `wiki/index.md` then the relevant `wiki/[domain]/[subdir]/index.md` to narrow the path before reading any page
3. Drill into pages, traverse typed relationships
4. Update `last_confirmed` to today on each page read (access resets decay clock; does not raise confidence)
   - For any source page with `stale_check: auto`: compare `last_modified` or `content_hash` against the live source via its MCP gateway. If changed, re-fetch and re-ingest that source before synthesizing — the answer must reflect current data.
5. Synthesize with citations: `[[wiki/domain/path]]`
6. If answer is well-structured and cites sources → file automatically as wiki page. If borderline → ask. If purely conversational → skip.
7. Log: `## [YYYY-MM-DD] query | [domain or "shared"] | [question summary]` — always. Use `shared` when query spans multiple domains.

### `> recall: [terms]`
```bash
bash scripts/recall.sh "terms"
bash scripts/recall.sh --recent 5
bash scripts/recall.sh --date 2026-03
```

### `> digest sessions`
Compress raw session exports into episodic observations. This promotes raw session content to the `episodic` memory tier.
1. Scan `sessions/exports/` for undigested sessions
2. Compress each session into structured observations: work done, findings, decisions, dead ends
3. File as wiki pages (`memory_tier: episodic`):
   - Path: `wiki/[domain]/observations/YYYY-MM-DD-[topic-slug].md`
   - Domain: infer from content; use `shared` if spans multiple domains
   - Include `confidence`, `memory_tier`, `last_confirmed` — these are knowledge claims, not source summaries
4. For each existing page corroborated: raise `confidence` by 0.05, update `last_confirmed`
5. For each existing page contradicted: flag for supersession; observation pages have no `source_authority` — prefer existing primary/secondary-backed claims unless confidence gap is large
6. Move processed files to `sessions/wiki-digests/`
7. Log: `## [YYYY-MM-DD] digest | sessions | N sessions → M pages (K episodic)`

### `> crystallize [title]`
Distill a completed work thread:
1. Question / goal, findings / decisions, entities involved
2. Lessons as standalone facts → confidence-scored claims on new or existing pages
3. Existing pages confirmed by session: raise `confidence` by 0.05, update `last_confirmed`
4. Existing pages challenged by session: propose supersession or flag contradiction
5. Promote memory tier where evidence warrants
6. Log: `## [YYYY-MM-DD] crystallize | [domain] | [title]`

### `> lint [domain]`
Find and fix:
- Orphan pages → link or flag
- Contradictions → propose winner in priority order: (1) `source_authority` of backing sources (primary > secondary > informal), (2) sources list length, (3) `last_confirmed` recency, (4) `confidence`; supersede weaker claim; ask human if top factors are tied
- Low-quality pages → check `quality` score; skip pages with `quality ≥ 0.8`; auto-fix structural issues on `quality 0.5–0.8`; flag for human review `quality < 0.5`; recompute score after fixes
- Missing stubs, missing cross-references → create/add
- Sessions >7 days undigested → trigger digest
- Pages where `last_confirmed` >30 days ago → decay `confidence` by tier rate (working: 0.05, episodic: 0.04, semantic: 0.03, procedural: 0.02); floor 0.0

### `> consolidate`
Promote: `working` → `episodic` (first digest); `episodic` → `semantic` (≥0.7, 2+ sources in `## Sources`); `semantic` → `procedural` (≥0.9, 3+ sources in `## Sources`).

### `> stale-check [domain]`
Re-fetch MCP-sourced wiki pages to detect and ingest changed content. Domain optional — omit to check all domains.

1. Collect candidates: `stale_check: manual` sources always; `stale_check: auto` sources if `last_fetched` >7 days. Skip `stale_check: skip`.
2. For each source, read frontmatter: `source_url`, `source_mcp`, `last_modified`, `content_hash`.
3. Fetch via MCP (`source_mcp` field) and compare:
   - `last_modified` set → compare to stored value
   - `last_modified` null → compute sha256 of content; compare to `content_hash`
   - **Unchanged** → update `last_fetched` to today only
   - **Changed** → run full INGEST for that source
4. Update `last_fetched` on every checked source.
5. Log: `## [YYYY-MM-DD] stale-check | [domain] | N checked, M stale`
6. Report: sources checked, stale count, which re-ingested, which unreachable.

Sources unreachable (MCP unavailable, bad URL) → skip silently, log as `unreachable`.

### `> update [domain] [path]`
Update a wiki page from chat. For corrections, meeting notes, decisions.

### `> customize`
Replace DOMAIN_1/2/3 placeholders, configure domain conventions and page formats.

### `> bootstrap`
Create full directory structure, seed skeleton pages, initialize `sessions.db`:
- `raw/DOMAIN_N/` per domain
- `wiki/DOMAIN_N/{sources,observations,concepts,entities}/` per domain
- `wiki/DOMAIN_N/research/threads/` if needed
- `wiki/DOMAIN_N/overview.md` and `wiki/overview.md` — seeded with `type: overview` frontmatter + placeholder body
- `wiki/DOMAIN_N/index.md` + `wiki/DOMAIN_N/log.md` — seed empty at domain level
- `wiki/DOMAIN_N/{subdir}/index.md` + `wiki/DOMAIN_N/{subdir}/log.md` — seed empty in every subdirectory

---

## Memory Tiers

| Tier         | Description                          | Promoted when                    | Decay / 30 days |
|--------------|--------------------------------------|----------------------------------|-----------------|
| `working`    | Recent observation (default)         | On ingest                        | −0.05           |
| `episodic`   | Session-level fact                   | After first digest/crystallize   | −0.04           |
| `semantic`   | Confirmed by 2+ sources              | confidence ≥ 0.7, 2+ sources    | −0.03           |
| `procedural` | Stable pattern, 3+ sources           | confidence ≥ 0.9, 3+ sources    | −0.02           |

Decay: applied per tier rate every 30 days since `last_confirmed`. Floor 0.0.
Reinforcement: access resets `last_confirmed`. Sources/crystallize also raise confidence (+0.05, cap 1.0).

---

## Typed Relationships

Required at ingest and for cross-domain connections. Use in `## Relationships` blocks.

| Type | Meaning |
|------|---------|
| `uses` | A calls or depends on B |
| `depends_on` | A cannot function without B |
| `contradicts` | A conflicts with B |
| `caused` | A is root cause of B |
| `fixed` | A resolved or repaired B |
| `supersedes` | A replaces B |
| `owns` | Person/team A is responsible for B |
| `impacts` | A affects behavior/health of B |

---

## Page Formats

### sources/SLUG.md
Source pages are immutable summaries. No `memory_tier` or `confidence` — those belong on
concept/entity pages that aggregate claims from multiple sources.

```markdown
---
type: source
title: "Source Title"
domain: DOMAIN_1 | DOMAIN_2 | DOMAIN_3
date_ingested: YYYY-MM-DD
source_type: article | paper | book_chapter | podcast | video | memo | report | other
source_authority: primary | secondary | informal
tags: []
raw_path: raw/DOMAIN/filename.md
source_url: null              # canonical URL or resource ID used to fetch this source
source_mcp: null              # MCP gateway name used at ingest time, or null for static sources
last_fetched: YYYY-MM-DD      # date content was last pulled from the live source
last_modified: null           # last-modified timestamp from the source system, if the gateway provides one
content_hash: null            # sha256 of raw content — used when last_modified is unavailable
stale_check: auto             # auto | manual | skip — auto=re-fetch at query time when this source is consulted; manual=human-triggered; skip=static/immutable docs
---
## Summary
## Key Claims
## Key Entities Mentioned
## Contradictions / Open Questions
## Wiki Pages Updated
```

`source_authority`: `primary` = official docs, original research, direct measurement. `secondary` = analysis/summary of primary. `informal` = blog posts, hearsay, unverified notes. Used by LINT to resolve contradictions.

### concepts/NAME.md
```markdown
---
type: concept
title: "Concept Name"
domain: DOMAIN_1 | DOMAIN_2 | DOMAIN_3 | shared
last_updated: YYYY-MM-DD
last_confirmed: YYYY-MM-DD
confidence: 0.0–1.0
memory_tier: working | episodic | semantic | procedural
superseded_by: null
quality: 0.0–1.0
---
## Definition
## Why It Matters
## Sources
- [[sources/slug]] — how it supports this page
## Relationships
## Related Concepts
## Open Questions
```

### entities/NAME.md
```markdown
---
type: entity
title: "Entity Name"
entity_type: person | org | product | place | regulation | tool | system | project | file | decision | library
domain: DOMAIN_1 | DOMAIN_2 | DOMAIN_3 | shared
last_updated: YYYY-MM-DD
last_confirmed: YYYY-MM-DD
confidence: 0.0–1.0
memory_tier: working | episodic | semantic | procedural
superseded_by: null
quality: 0.0–1.0
---
## What / Who
## Relevance
## Key Facts
## Sources
- [[sources/slug]] — how it supports this page
## Relationships
```

---

## Domain Conventions

> Replace placeholder text with your actual domain configuration.

### `DOMAIN_1` — [Domain 1 Name]
**Purpose**: [What this domain covers]
**Key concept pages to seed early**: [Concept 1], [Concept 2]
**Domain-specific page types**: [Custom formats]
**Special rules**: [What the LLM should always check]

### `DOMAIN_2` — [Domain 2 Name]
**Purpose**: [What this domain covers]
**Key concept pages to seed early**: [Concept 1], [Concept 2]
**Domain-specific page types**: [Custom formats]
**Special rules**: [Domain-specific behavior]

### `DOMAIN_3` — [Domain 3 Name]
**Purpose**: [What this domain covers]
**Key concept pages to seed early**: [Concept 1], [Concept 2]
**Domain-specific page types**: [Custom formats]
**Special rules**: [Domain-specific behavior]

---

## Cross-Domain Connections

### DOMAIN_1 ↔ DOMAIN_2
- [Shared concepts, entities, or dependencies]

### DOMAIN_1 ↔ DOMAIN_3
- [Shared concepts, entities, or dependencies]

### DOMAIN_2 ↔ DOMAIN_3
- [Shared concepts, entities, or dependencies]

---

## Co-Evolution Note

This schema is a starting point. Update it as the wiki grows — change conventions that
aren't working, add domains, add page formats. Note changes in `wiki/log.md`.

---

*LLM Wiki · MIT License*
