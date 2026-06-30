# WIKI.md — LLM Wiki Schema (Generic Adapter)
#
# Use this file with any LLM agent that can read markdown.
# For full schema and Claude Code integration, see adapters/claude-code/CLAUDE.md.

---

## Overview

You are maintaining an LLM Wiki — a persistent, compounding knowledge base
built from markdown files. The human sources documents and asks questions.
You do all the writing, filing, cross-referencing, and bookkeeping.

Active domains:

| Domain ID  | Name   | Root folder      |
|------------|--------|------------------|
| `DOMAIN_1` | [Name] | `wiki/DOMAIN_1/` |
| `DOMAIN_2` | [Name] | `wiki/DOMAIN_2/` |
| `DOMAIN_3` | [Name] | `wiki/DOMAIN_3/` |

> Replace DOMAIN_1/2/3 with your actual domain names via `> customize`.

---

## Core rules

1. **Ingest = extract + score + link.** Every source produces: a summary page, entity extraction
   with typed relationships, confidence scores, and wiki updates. Typically 8–15 pages touched.
   Sources that corroborate existing claims raise `confidence` by 0.05 and update `last_confirmed`.

2. **Reserved filenames + update trigger.** `index.md`, `log.md`, `overview.md` are reserved — no `type` field. Whenever a wiki page is added, removed, or body-changed: update index.md + log.md at all 3 levels (root/domain/subdir). Update overview.md only when domain or cross-domain picture meaningfully shifts. Frontmatter-only changes → log.md only. Log files: append-only, newest row on top, never edit past entries.

3. **Log everything.** Append to `wiki/log.md` on every operation — ingest, query, crystallize, lint, consolidate.

4. **Score every claim and page.** All pages carry `confidence` (0.0–1.0), `memory_tier`, `last_confirmed`, and `quality` (0.0–1.0). Concepts/entities/threads also maintain a `## Sources` list.
   Decay: per-tier rate every 30 days since `last_confirmed` (working −0.05, episodic −0.04, semantic −0.03, procedural −0.02). Reinforcement resets `last_confirmed`; sources/crystallize also raise confidence +0.05.
   Quality scoring at write time: +0.3 all required sections present, +0.3 Sources≥1, +0.2 Relationships≥1 typed link, +0.2 no unresolved contradictions. Recompute on every update.

5. **Supersede, don't overwrite.** When new info contradicts old, set `superseded_by` on the
   old page and mark it stale. Resolve by priority: `source_authority` (primary > secondary > informal), then sources list length, then `last_confirmed`, then `confidence`.

6. **Check staleness at query time.** For any source page referenced with `stale_check: auto`, compare `last_modified` or `content_hash` against the live source via its MCP gateway. If changed, re-fetch and re-ingest that source before synthesizing — the answer must reflect current data.
7. **File good answers.** After a query, if the answer is well-structured and cites sources → file it as a wiki page automatically. Update `last_confirmed` on every page read during the query (access resets the decay clock). Always log the query regardless.

7. **Load context at session start.** Read `wiki/log.md` tail to identify recently active domains. Read `wiki/index.md` then `wiki/[domain]/index.md` for those domains. Note open research threads.

---

## Memory tiers

| Tier | Promoted when | Decay / 30 days |
|------|---------------|-----------------|
| `working`    | Default on ingest             | −0.05 |
| `episodic`   | First digest/crystallize      | −0.04 |
| `semantic`   | confidence ≥ 0.7, 2+ sources | −0.03 |
| `procedural` | confidence ≥ 0.9, 3+ sources | −0.02 |

Decay: per-tier rate every 30 days since `last_confirmed`. Floor 0.0.
Reinforcement: access resets `last_confirmed`. Sources/crystallize also raise confidence (+0.05, cap 1.0).

---

## Typed relationships

Use these in `## Relationships` blocks on entity and concept pages:

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

## Operations

| Command | Steps |
|---------|-------|
| `> ingest [domain] raw/path/file.md` | Read → strip PII → extract entities → create source page (no tier/confidence) → update entity/concept pages (add to `## Sources`, raise confidence) → update index → check cross-domain → log |
| `> [question]` | Check sessions → read `wiki/index.md` then `wiki/[domain]/index.md` then `wiki/[domain]/[subdir]/index.md` → traverse relationships → update `last_confirmed` on read pages → for `stale_check: auto` sources: compare `last_modified`/`content_hash` via MCP, re-ingest if changed → synthesize answer → auto-file if well-structured → log |
| `> crystallize [title]` | Distill completed work into structured page, extract lessons as facts |
| `> lint` | Find orphans, contradictions, stale claims, decay confidence, suggest missing pages; skip `quality≥0.8`, auto-fix `0.5–0.8`, flag `<0.5` |
| `> consolidate` | Promote pages up tier ladder based on evidence |
| `> digest sessions` | Compress session exports into episodic observations → file under `wiki/[domain]/observations/` |
| `> stale-check [domain]` | Re-fetch `manual` MCP sources + `auto` sources older than 7 days → compare `last_modified` or sha256 → re-ingest if changed → update `last_fetched` on all checked → log `N checked, M stale` → skip `stale_check: skip` and unreachable sources silently |

---

## Page frontmatter

**Knowledge pages** (concepts, entities, threads) must include:
```yaml
---
type: concept | entity | thread | observation
title: "Page Title"
domain: DOMAIN_1 | DOMAIN_2 | DOMAIN_3 | shared
confidence: 0.0–1.0
memory_tier: working | episodic | semantic | procedural
last_updated: YYYY-MM-DD
last_confirmed: YYYY-MM-DD
superseded_by: null | [[path/to/newer-page]]
quality: 0.0–1.0
---
```

These pages also include a `## Sources` section listing all sources that back the page — used for tier promotion (2+ for semantic, 3+ for procedural) and as quick references to backing material.

**Reserved pages** (`index.md`, `log.md`, `overview.md`) — no `type` field required.

**Source pages** (`sources/SLUG.md`) are immutable summaries — no `confidence`, `memory_tier`, or `last_confirmed`. They require:
```yaml
type: source
source_authority: primary | secondary | informal
raw_path: raw/DOMAIN/filename.md
source_url: null              # canonical URL or resource ID used to fetch this source
source_mcp: null              # MCP gateway name used at ingest time, or null for static sources
last_fetched: YYYY-MM-DD      # date content was last pulled from the live source
last_modified: null           # last-modified timestamp from the source system, if the gateway provides one
content_hash: null            # sha256 of raw content — used when last_modified is unavailable
stale_check: auto             # auto | manual | skip — auto=re-fetch at query time when this source is consulted; manual=human-triggered; skip=static/immutable docs
```
`primary` = official docs, original research, direct measurement.
`secondary` = analysis or summary of primary sources.
`informal` = blog posts, hearsay, unverified notes.
