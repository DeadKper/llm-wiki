# CLAUDE.md — LLM Wiki Schema
# [YOUR WIKI NAME] · Maintained by Claude Code
#
# 1. Replace DOMAIN_1, DOMAIN_2, DOMAIN_3 with your actual domain names
# 2. Fill in Domain Conventions for each domain
# 3. Delete page formats you don't need
# 4. Run `> customize` then `> bootstrap` to set up
#
# Works as a personal wiki or a shared team wiki — structure is the same.
# examples/personal-wiki/ — personal wiki patterns and use cases
# examples/team-wiki/    — team wiki patterns and use cases
# ══════════════════════════════════════════════════════════════

---

## Overview

A **multi-domain LLM Wiki** — persistent, compounding knowledge base maintained
entirely by you (the LLM). The human sources documents and asks questions.
You do all writing, filing, cross-referencing, and bookkeeping.

Active domains:

| Domain ID  | Name             | Root folder        |
|------------|------------------|--------------------|
| `DOMAIN_1` | [Domain 1 Name]  | `wiki/DOMAIN_1/`   |
| `DOMAIN_2` | [Domain 2 Name]  | `wiki/DOMAIN_2/`   |
| `DOMAIN_3` | [Domain 3 Name]  | `wiki/DOMAIN_3/`   |

Add, rename, or remove domains freely. Single-domain setups are valid.
Cross-domain connections create pages under `wiki/shared/`.

For non-Claude agents, see `adapters/` — wiki files are agent-agnostic.

---

## Directory Structure

```
llm-wiki/
├── raw/                          # IMMUTABLE. Source documents — never modify.
│   ├── DOMAIN_1/
│   ├── DOMAIN_2/
│   ├── DOMAIN_3/
│   └── assets/
├── wiki/                         # LLM-maintained. Create and update freely.
│   ├── index.md                  # Master catalog — update on EVERY ingest
│   ├── log.md                    # Append-only operation record
│   ├── overview.md               # Cross-domain synthesis — reserved
│   ├── DOMAIN_1/
│   │   ├── index.md              # Domain index + entity graph — update on EVERY ingest
│   │   ├── log.md                # Domain-level append-only log — update on EVERY ingest
│   │   ├── overview.md           # Domain synthesis — reserved
│   │   ├── sources/              # Ingested raw source summaries (no tier/confidence)
│   │   │   ├── index.md          # Sources listing — update on EVERY ingest
│   │   │   └── log.md
│   │   ├── observations/         # Digested session observations (episodic, have tier/confidence)
│   │   │   ├── index.md
│   │   │   └── log.md
│   │   ├── concepts/
│   │   │   ├── index.md
│   │   │   └── log.md
│   │   ├── entities/
│   │   │   ├── index.md          # Entity listing + entity graph — update on EVERY ingest
│   │   │   └── log.md
│   │   ├── research/threads/     # Active research threads (optional)
│   │   │   ├── index.md
│   │   │   └── log.md
│   │   └── [DOMAIN_1_SUBDIR]/    # Additional domain-specific subdirs
│   │       ├── index.md
│   │       └── log.md
│   ├── DOMAIN_2/ ...
│   ├── DOMAIN_3/ ...
│   └── shared/
│       ├── index.md
│       └── log.md
├── sessions/
│   ├── exports/                  # Auto-exported transcripts (gitignored)
│   ├── confidential/             # Encrypted exports (gitignored)
│   └── wiki-digests/
├── .claude/
│   ├── settings.json
│   ├── personal-wiki-path        # Optional — gitignored, set per person
│   ├── maintenance-state.json    # Last lint/consolidate dates — gitignored, per person
│   ├── maintenance-schedule.json # Cadence config — gitignored, per person
│   ├── maintenance-due           # Transient sentinel — gitignored
│   ├── no-export                 # Sentinel: skip export for this session
│   └── scripts/
│       ├── export-session.py
│       ├── index-sessions.sh
│       ├── load-personal-prefs.py
│       ├── recall.sh
│       ├── scheduled-maintenance.py
│       ├── sweep-sessions.py
│       └── wire-project.py
├── adapters/
├── .exportignore
├── .gitignore
├── sessions.db                   # SQLite FTS5 index (gitignored)
└── CLAUDE.md
```

---

## Session Export System

Every session is exported to markdown before context compresses. Indexed in SQLite
FTS5 — searchable with no API calls, no embeddings. Just markdown and SQL.

### Hooks

**PreCompact** — fires on manual `/compact`. Does not fire on automatic compression.

**SessionEnd** — fires on normal exit. Exports session, then runs `scheduled-maintenance.py --trigger sessionend` to check if lint is overdue and write a reminder sentinel.

**SessionStart** — indexes new exports, prints last 3 sessions, loads personal prefs if configured, runs `scheduled-maintenance.py --trigger sessionstart` to print any overdue ops, then:

**At session start, the LLM should:**
1. Read `wiki/log.md` tail (`grep "^## \[" wiki/log.md | tail -10`) to understand recent activity
2. Identify which domains were active in recent operations
3. Note any open threads (`research/threads/` with `status: active`) in those domains

This gives the session context without reading the entire wiki. Skip steps 2–3 if the wiki is empty or this is a bootstrap session.

### Personal wiki integration

Load preferences from a separate personal wiki repo at session start:

```bash
# gitignored — set per person (or once, if this is a personal wiki with a companion repo)
echo "/path/to/your/personal-wiki" > .claude/personal-wiki-path
```

Loads `wiki/*/preferences/*.md` from the personal repo at session start.
Silent if not configured, path missing, or no preference files found.
Only preferences are loaded — nothing else from the personal repo is touched.

See `examples/personal-wiki/domains/personal-domain.md` for the personal wiki pattern.
For team use, see `examples/team-wiki/domains/personal-companion.md`.

### Manual session recovery

```bash
python3 .claude/scripts/sweep-sessions.py --days 7      # recover last 7 days
python3 .claude/scripts/sweep-sessions.py --dry-run     # preview only
python3 .claude/scripts/export-session.py --trigger manual \
  --transcript ~/.claude/projects/<slug>/<id>.jsonl      # single session
bash .claude/scripts/index-sessions.sh                   # re-index
```

Check `.claude/hooks.log` for a timestamped record of hook invocations.

### Shell aliases

```bash
# ~/.zshrc or ~/.bashrc
export WIKI_ROOT="$HOME/path/to/llm-wiki"

wikiexit()  { python3 "$WIKI_ROOT/.claude/scripts/export-session.py" --trigger manual
              python3 "$WIKI_ROOT/.claude/scripts/sweep-sessions.py" --days 7; }
wikisweep() { python3 "$WIKI_ROOT/.claude/scripts/sweep-sessions.py"; }
```

Windows: see `docs/windows-setup.md`.

### Confidentiality controls

```bash
touch .claude/no-export            # skip export; auto-deletes after session
# or say "this session is confidential" at first prompt
```

> Use the exact phrase — common words like "private" appear naturally in content
> and will silently block all exports if used as the trigger.

`.exportignore` — export to disk but exclude from search index.

```bash
python3 .claude/scripts/export-session.py --trigger manual --label confidential
# → GPG-encrypted to sessions/confidential/
```

---

## Page Formats

### sources/SLUG.md
Source pages are immutable summaries of ingested documents. They are not promoted knowledge
claims — they don't have `memory_tier` or `confidence`. Those fields belong on concept and
entity pages that aggregate claims across multiple sources.

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
source_url: null              # canonical URL or MCP resource ID used to fetch this source
source_mcp: null              # MCP gateway name used at ingest time, or null for static sources
last_fetched: YYYY-MM-DD      # date content was last pulled from the live source
last_modified: null           # last-modified timestamp from the source system, if the gateway provides one
content_hash: null            # sha256 of raw content — used when last_modified is unavailable
stale_check: auto             # auto | manual | skip — auto=re-fetch at query time when this source is consulted; manual=human-triggered; skip=static/immutable docs
---

## Summary
2–4 sentence summary.

## Key Claims
- Claim 1
- Claim 2 (note contradictions with [[existing pages]])

## Key Entities Mentioned
- [[Entity Name]] — role in this source

## Contradictions / Open Questions

## Wiki Pages Updated
```

`source_authority` values:
- `primary` — direct measurement, official docs, original research, first-hand account
- `secondary` — summary, analysis, or commentary on primary sources
- `informal` — blog posts, hearsay, unverified notes, personal observations

Used by LINT contradiction resolution: claims backed by higher-authority sources win ties.

### concepts/NAME.md
```markdown
---
type: concept
title: "Concept Name"
domain: DOMAIN_1 | DOMAIN_2 | DOMAIN_3 | shared
tags: []
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
- uses [[entities/name]] — reason
- depends_on [[entities/name]] — reason

## Related Concepts
- [[concepts/related]] — connection

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
- Fact (confidence: 0.N)

## Sources
- [[sources/slug]] — how it supports this page

## Relationships
- uses [[entities/name]] — reason
- depends_on [[entities/name]] — reason
- owns [[entities/name]] — reason
- impacts [[entities/name]] — reason
```

### research/threads/THREAD.md
```markdown
---
type: thread
title: "Thread: [Question]"
domain: DOMAIN_1 | DOMAIN_2 | DOMAIN_3
status: active | paused | closed
started: YYYY-MM-DD
last_confirmed: YYYY-MM-DD
confidence: 0.0–1.0
memory_tier: working | episodic | semantic | procedural
quality: 0.0–1.0
---

## The Question

## What We Know So Far

## Sources
- [[sources/slug]] — how it supports this thread

## Open Sub-Questions

## Next Steps
```

> Add domain-specific page formats in the Domain Conventions section below.

---

## Special Files

**Quality scoring** — Set `quality` on every concept/entity/thread page at write time (ingest, crystallize, query-file, update):
- +0.3 if all required sections present (Definition/What/Question, Sources, Relationships)
- +0.3 if `## Sources` has ≥1 entry
- +0.2 if `## Relationships` has ≥1 typed link
- +0.2 if content is consistent with related pages (no unresolved contradictions)
- Score is 0.0–1.0. Recompute whenever page is updated.

**wiki/index.md** — Navigation map. Updated on every ingest. Contains one section per domain with:
- Link to `[domain]/index.md` for the full catalog
- **Key entities** (procedural/semantic only, by name)
- **Key concepts** (by name)
- Pointer to `[domain]/sources/index.md` with source count
- Compact Entity Graph (cross-domain relationships + core typed edges)

LLM reads this first on every query to orient, then drills into domain/subdir indexes.
Do NOT list every page here — that is the job of domain and subdir indexes.

**Index hierarchy — read order:**
1. `wiki/index.md` — orient (nav map, key entities by name, entity graph)
2. `wiki/[domain]/index.md` — all entities + concepts + observations for that domain
3. `wiki/[domain]/[subdir]/index.md` — full file listing for that specific directory
4. Individual page — read only after the index confirms it is the right one

**wiki/overview.md** — High-level synthesis across all domains. **Reserved filename** — no `type` field. Update after any ingest or crystallize that meaningfully shifts the overall picture. Not every ingest triggers an update — only when the cross-domain synthesis changes. Seed this during `> bootstrap`.

**wiki/DOMAIN/overview.md** — Per-domain synthesis. **Reserved filename** — no `type` field. Update when a domain's architecture, key patterns, or entity map changes. Seed during `> bootstrap`.

**Reserved filenames** — `index.md`, `log.md`, and `overview.md` at any directory level are reserved. They MUST NOT be used for concept/entity pages and do NOT require a `type` field.

**Update trigger rule** — `index.md`, `log.md`, and `overview.md` at all three levels (root / domain / subdir) MUST be updated whenever a wiki page is **added**, **removed**, or has a **meaningful content change** (body change — not frontmatter-only). This applies regardless of which operation caused the change: ingest, update, crystallize, digest, supersede, lint. Frontmatter-only changes (confidence bumps, `last_confirmed` resets) do NOT trigger index/overview updates — only `log.md` gets an entry.

**wiki/[domain]/[subdir]/index.md** — Directory-level catalog. OKF §6 format: no frontmatter, grouped bullet lists, Entity Graph section at end. Update whenever a file in this directory is added, removed, or has a meaningful content change.
```markdown
# <Subdir> Index

## <Group Heading>

* [Title](filename.md) - one-line description

## Entity Graph

> Types: uses | depends_on | impacts | owns | supersedes
A → uses → B
```

**wiki/[domain]/[subdir]/log.md** — Directory-scoped append-only log. Same format as root `log.md`, scoped to files in that directory. Append on every operation that touches a file here.

**wiki/[domain]/index.md** — Domain-level catalog: all subdirectory groups + full domain entity graph. Update whenever any file in the domain is added, removed, or content-changed.

**wiki/[domain]/log.md** — Domain batch summaries. Collapse same-date ingests into one line. Keep lint/consolidate/crystallize verbatim. Header names the subdir logs.

**Log hierarchy — write rule:**
- `wiki/log.md` — cross-domain activity timeline. One summary per domain per date. Keep lint/consolidate/crystallize/digest/supersede verbatim.
- `wiki/[domain]/log.md` — domain batch summaries + lint/consolidate/crystallize verbatim.
- `wiki/[domain]/[subdir]/log.md` — full per-file detail, one entry per page touched.
On every ingest: full detail → subdir log; batch summary → domain log; count summary → root log.
On supersede/delete: remove from subdir index; append `supersede` to subdir/domain/root logs.
On update (content change): update subdir + domain index entries; append `update` to all log levels.
On crystallize/digest (new observation): add to observations/index + domain index; append to all log levels.

**wiki/log.md** — Cross-domain activity timeline. Append-only, newest entry on top. Never edit past entries.
```
## [YYYY-MM-DD] ingest       | DOMAIN_1   | N sources ingested; see DOMAIN_1/log.md
## [YYYY-MM-DD] lint         | all        | N orphans, M contradictions, K decays
## [YYYY-MM-DD] consolidate  | all        | N working→episodic, M episodic→semantic
## [YYYY-MM-DD] crystallize  | DOMAIN_1   | Title → M facts
## [YYYY-MM-DD] digest       | sessions   | N sessions → M wiki pages
## [YYYY-MM-DD] supersede    | DOMAIN_2   | old → new
## [YYYY-MM-DD] stale-check  | DOMAIN_1   | N checked, M stale
```
Parseable at any level: `grep "^## \[" wiki/log.md | tail -10`

---

## Operations

### INGEST — `> ingest [domain] raw/path/to/file.md`
1. Read source from `raw/`
2. Strip sensitive data (API keys, tokens, passwords, PII)
3. Brief 2–3 sentence takeaway
4. Extract entities with typed relationships (`uses` / `depends_on` / `contradicts` / `caused` / `fixed` / `supersedes` / `owns` / `impacts`)
5. Create `wiki/[domain]/sources/SLUG.md` — no `confidence` or `memory_tier` on source pages; those belong on the concept/entity pages that aggregate claims from this source
   - Set `source_url` to the URL or resource ID used to fetch the content, if known
   - Set `source_mcp` to the gateway name if fetched via MCP, otherwise `null`
   - Set `last_fetched` to today; `last_modified` to the source's modification timestamp if the gateway provides one, otherwise `null`
   - Set `content_hash` to sha256 of raw content when `last_modified` is unavailable and `stale_check: auto`
   - Set `stale_check: auto` for live MCP sources; `skip` for static files, pasted text, or local documents
6. For each existing entity/concept page this source touches:
   - If source **corroborates** an existing claim: add to `## Sources` list, raise `confidence` by 0.05 (cap 1.0), update `last_confirmed`
   - If source **contradicts** an existing claim: determine the weaker claim by priority — (1) `source_authority`, (2) sources list length, (3) `last_confirmed`, (4) `confidence`; set `superseded_by` on the weaker claim, mark it stale; log a supersede entry
7. Update `wiki/index.md` — add new entity to Key entities if procedural/semantic; update entity graph if relationships changed
8. Update `wiki/[domain]/[subdir]/index.md` — add entry; update entity graph if relationships changed
9. Update `wiki/[domain]/index.md` — add to relevant group; update entity graph if relationships changed
10. Append to `wiki/[domain]/[subdir]/log.md` and `wiki/[domain]/log.md`
11. Append to `wiki/log.md` — count summary; one supersede line per supersession
12. Check domain-specific implications (Domain Conventions below)
13. Check cross-domain connections → `wiki/shared/`
14. If this source meaningfully shifts the domain's picture, update `wiki/[domain]/overview.md`; if it shifts the cross-domain synthesis, update `wiki/overview.md`
15. If qmd skill available, run `qmd update` to re-index new pages; always keep indexes current regardless
16. Report: files touched, entities extracted, corroborations, contradictions, supersessions

A single ingest typically touches 12–20 wiki pages (source page, entity pages, subdir index/log, domain index/log, root log, possibly overviews).

### QUERY — `> [question]`
1. `bash .claude/scripts/recall.sh "[keywords]"` — check past sessions
2. Find relevant wiki pages:
   - If qmd skill available: read `.claude/wiki-search-config` to get `WIKI_COLLECTIONS`; default to the wiki's own collection name plus `personal-wiki` if `.claude/personal-wiki-path` is set. Run `qmd search` (exact terms/names) or structured `qmd query` with `intent:`/`lex:`/`vec:` fields, passing each collection as a `-c <name>` flag.
   - Otherwise: read `wiki/index.md` then the relevant `wiki/[domain]/[subdir]/index.md` to narrow the path before reading any page
3. Read pages, traverse typed relationships; update `last_confirmed` to today on each page read (access counts as reinforcement — it resets the decay clock without raising confidence)
   - For any source page referenced with `stale_check: auto`: check if the source has changed by comparing `last_modified` or `content_hash` against the live source via MCP. If changed, re-fetch the content and run a full ingest for that source before synthesizing the answer — the answer should reflect current data.
4. Synthesize with inline citations: `[[wiki/domain/path]]`
5. Assess the answer: if it is well-structured, cites sources, and is consistent with the wiki → file it automatically as a new wiki page. If borderline, ask. If low-quality or purely conversational, skip.
6. Log: `## [YYYY-MM-DD] query | [domain or "shared"] | [question summary]` — always, whether filed or not. Use `shared` when the query spans multiple domains.

### RECALL — `> recall: [terms]`
```bash
bash .claude/scripts/recall.sh "terms"
bash .claude/scripts/recall.sh --recent 5
bash .claude/scripts/recall.sh --date 2026-03
```
BM25-ranked FTS5 search over all indexed sessions. Falls back to grep.

### WIKI SEARCH — `> wiki: [terms]`
Searches wiki pages. Use when `wiki/index.md` grows large or for semantic queries.

**With qmd skill** (preferred): read `.claude/wiki-search-config` to get `WIKI_COLLECTIONS`; default to the wiki's own collection plus `personal-wiki` if `.claude/personal-wiki-path` is set. Pass each collection as `-c <name>`:
```bash
# Exact terms/names/symbols → BM25
qmd search "auth flow redesign" -c my-wiki -n 8

# Conceptual / indirect → structured query (write intent/lex/vec yourself)
qmd query $'intent: Find pages about auth flow, not general security.\nlex: auth flow login session token\nvec: user authentication redesign login session' \
  -c my-wiki -n 8
```

**qmd score = 0% or all equal (no GPU)**: BM25 on common/short terms collapses scores. In this case, rank results yourself using frontmatter:
1. `memory_tier`: procedural > semantic > episodic > working
2. `confidence`: higher wins ties within same tier
3. `last_confirmed`: more recent wins further ties
Source pages (`sources/`) have no tier/confidence — treat as supporting evidence, not primary ranked results.

**Without qmd skill**: grep over `wiki/` then read `wiki/index.md`.
```bash
grep -rl "term" wiki/ | head -8
```

Collections controlled by `.claude/wiki-search-config` (gitignored):
```bash
WIKI_COLLECTIONS=("my-wiki" "personal-wiki")
```
`wiki/index.md` must stay current regardless of whether qmd is used — update it on every ingest.

### DIGEST — `> digest sessions`
Compress raw session exports into episodic observations and file them as wiki pages.
This is what promotes raw session content to the `episodic` memory tier.

1. Scan `sessions/exports/` for undigested sessions
2. For each session, compress into structured observations: what was the work, what was found, what decisions were made, what dead ends were hit
3. File compressed observations as wiki pages (`memory_tier: episodic`):
   - Path: `wiki/[domain]/observations/YYYY-MM-DD-[topic-slug].md`
   - Domain: infer from session content; use `shared` if it spans multiple domains
   - These are knowledge claims, not raw source summaries — include `confidence`, `memory_tier`, `last_confirmed`
   - `source_authority` does not apply to observation pages; contradiction priority falls back to sources list length → `last_confirmed` → `confidence`
4. For each existing page corroborated by a session observation: raise `confidence` by 0.05, update `last_confirmed`
5. For each existing page contradicted: flag for supersession; observation pages have no `source_authority` — prefer existing claims backed by primary/secondary sources unless confidence gap is large
6. For each observation page filed:
   - Add entry to `wiki/[domain]/observations/index.md` and `wiki/[domain]/index.md`
   - Append to `wiki/[domain]/observations/log.md`, `wiki/[domain]/log.md`, `wiki/log.md`
7. Move processed session files to `sessions/wiki-digests/`
8. Log: `## [YYYY-MM-DD] digest | sessions | N sessions → M pages (K episodic)`

### CRYSTALLIZE — `> crystallize [title]`
Distill a completed work thread into wiki pages:
1. Question / goal
2. Findings / decisions
3. Files, systems, entities involved
4. Lessons as standalone facts → confidence-scored claims on new or existing pages
5. For each existing page whose claims are confirmed by the session: raise `confidence` by 0.05, update `last_confirmed`
6. For each existing page whose claims are challenged by the session: propose supersession or note contradiction
7. Promote memory tier where evidence warrants
8. For each new observation page filed:
   - Add entry to `wiki/[domain]/observations/index.md` and `wiki/[domain]/index.md`
   - Append to `wiki/[domain]/observations/log.md`, `wiki/[domain]/log.md`, `wiki/log.md`
9. If domain picture shifts: update `wiki/[domain]/overview.md`
10. Log: `## [YYYY-MM-DD] crystallize | [domain] | [title]`

### LINT — `> lint [domain]`
Auto-fix where possible. When scanning files with bash, skip reserved filenames:
```bash
for f in wiki/[domain]/**/*.md; do
  name=$(basename "$f")
  [[ "$name" == "index.md" || "$name" == "log.md" || "$name" == "overview.md" ]] && continue
  # checks here
done
```
- Orphan pages → add inbound link or flag for deletion
- Contradictions between pages → propose resolution in priority order: (1) `source_authority` of backing sources (primary > secondary > informal), (2) sources list length, (3) `last_confirmed` recency, (4) `confidence`; supersede the weaker claim; ask human to confirm if top factors are tied
- Stale claims → set `superseded_by`, link to newer claim
- Low-quality pages → check `quality` score; skip pages with `quality ≥ 0.8`; auto-fix structural issues on `quality 0.5–0.8`; flag for human review `quality < 0.5`; recompute score after fixes
- Missing page stubs → create them
- Missing cross-references → add typed relationship links
- Sessions >7 days undigested → trigger digest
- Pages where `last_confirmed` >30 days ago → decay `confidence` by tier rate (working: 0.05, episodic: 0.04, semantic: 0.03, procedural: 0.02); floor 0.0
- For each stub created: add entry to `wiki/[domain]/[subdir]/index.md` and `wiki/[domain]/index.md`; append to `wiki/[domain]/[subdir]/log.md`
- For each page deleted or marked superseded: remove from `wiki/[domain]/[subdir]/index.md`; append `supersede` entry to subdir/domain/root logs

### CONSOLIDATE — `> consolidate`
Promote pages up the tier ladder:
- `working` → `episodic`: after first digest/crystallize
- `episodic` → `semantic`: confidence ≥ 0.7, 2+ sources in `## Sources`
- `semantic` → `procedural`: confidence ≥ 0.9, 3+ sources in `## Sources`

### STALE-CHECK — `> stale-check [domain]`
Re-fetch all `manual` sources in the domain (or all domains if omitted). Also covers `auto` sources not yet checked at query time.

Trigger patterns: `> stale-check` (all domains), `> stale-check [domain]`.

1. Collect candidates:
   - `grep -rl "stale_check: manual" wiki/[domain]/sources/` — always re-fetched
   - `grep -rl "stale_check: auto" wiki/[domain]/sources/` — re-fetched if `last_fetched` is stale (>7 days)
   - Sources with `stale_check: skip` are never touched.
2. For each source, read frontmatter: `source_url`, `source_mcp`, `last_modified`, `content_hash`.
3. Fetch via MCP (`source_mcp` field): google → `mcp__google__get_doc_as_markdown`, jira → `mcp__jira__ai_tools_jira-get_issue`, etc.
4. Compare:
   - If `last_modified` is set: compare to stored value
   - If `last_modified` is null: compute sha256 of fetched content; compare to `content_hash`
   - If **unchanged**: update `last_fetched` to today, no re-ingest needed
   - If **changed**: re-fetch the content and run a full ingest for that source immediately — wiki pages updated to reflect current data
5. Update `last_fetched` on every checked source (changed or not).
6. Log: `## [YYYY-MM-DD] stale-check | [domain] | N checked, M stale`
7. Report: sources checked, stale count, which ones re-ingested, which unreachable.
8. Update `.claude/maintenance-state.json` if a `last_stale_check` key exists there.

Sources that cannot be reached (MCP unavailable, URL invalid) are skipped silently and logged as `unreachable`.

QUERY auto-triggers stale-check for individual sources consulted mid-query — this operation covers bulk/scheduled runs.

### UPDATE — `> update [domain] [path]`
Update a wiki page from chat. For corrections, meeting notes, conversation decisions.
1. Apply the change to the target page
2. If title or description changed: update entry in `wiki/[domain]/[subdir]/index.md` and `wiki/[domain]/index.md`
3. If entity relationships changed: update entity graph in `wiki/[domain]/[subdir]/index.md`, `wiki/[domain]/index.md`, and `wiki/index.md`
4. If domain picture shifts: update `wiki/[domain]/overview.md`; if cross-domain synthesis shifts: update `wiki/overview.md`
5. Append to `wiki/[domain]/[subdir]/log.md`, `wiki/[domain]/log.md`, `wiki/log.md`
After completing scheduled LINT or CONSOLIDATE, also update `.claude/maintenance-state.json`
(see Scheduled Maintenance section).

### CUSTOMIZE — `> customize`
1. Replace DOMAIN_1/2/3 placeholders with real names
2. Configure domain conventions and page formats
3. Ask: **"Do you want to keep personal content separate from this wiki?"**
   - **[s] Separate repo** — personal content lives in a different git repo entirely.
     Prompt for the path and write it to `.claude/personal-wiki-path` (gitignored).
     Loads `wiki/*/preferences/*.md` from that repo at session start.
   - **[i] Isolated domain** — personal content stays in this repo but in its own
     domain tracked as a git submodule (or a gitignored folder). Prompt for the
     domain name (e.g. `personal`) and note it in the Domain Conventions section.
   - **[n] No** — skip; all domains in this repo, no separation.
   If `[s]` chosen, save path to `.claude/personal-wiki-path` (gitignored).
   If `[i]` chosen, add the personal domain to the domains table and note it as
   isolated (submodule or gitignored) in Domain Conventions.

### BOOTSTRAP — `> bootstrap`
Create full directory structure, seed skeleton pages, install scripts, initialize `sessions.db`:
- `raw/DOMAIN_N/` — one per domain (immutable source storage)
- `wiki/DOMAIN_N/{sources,observations,concepts,entities}/` — one per domain
- `wiki/DOMAIN_N/research/threads/` — if the domain will use research threads
- `wiki/DOMAIN_N/overview.md` — seed with `title` + `domain` frontmatter + placeholder body (reserved — no `type` field)
- `wiki/overview.md` — seed with `title` + `domain` frontmatter + placeholder body (reserved — no `type` field)
- `wiki/DOMAIN_N/index.md` + `wiki/DOMAIN_N/log.md` — seed empty at domain level
- `wiki/DOMAIN_N/{subdir}/index.md` + `wiki/DOMAIN_N/{subdir}/log.md` — seed empty in every subdirectory
If separate repo (`[s]`) was chosen during customize, verify `.claude/personal-wiki-path` resolves.
If isolated domain (`[i]`) was chosen, create `wiki/DOMAIN_N/` structure for the personal domain too.

---

## Memory Tiers

Default on creation: `working`. Promoted as evidence accumulates.

| Tier         | Description                          | When promoted                    | Decay rate / 30 days |
|--------------|--------------------------------------|----------------------------------|----------------------|
| `working`    | Recent observation, unconfirmed      | Default on ingest                | −0.05                |
| `episodic`   | Session-level fact, seen once        | After first digest/crystallize   | −0.04                |
| `semantic`   | Confirmed by 2+ sources              | confidence ≥ 0.7, 2+ sources    | −0.03                |
| `procedural` | Stable pattern, seen repeatedly      | confidence ≥ 0.9, 3+ sources    | −0.02                |

**Decay**: Applied per tier rate every 30 days since `last_confirmed`. Floor 0.0.

**Reinforcement**: Access (query), corroborating source, or crystallize session resets `last_confirmed` to today. Only corroborating sources and crystallize raise confidence (+0.05, cap 1.0).

---

## Typed Relationships

Use in `## Relationships` blocks. Required at ingest and for cross-domain connections.
Plain wikilinks are fine for casual references.

| Type          | Meaning                                  |
|---------------|------------------------------------------|
| `uses`        | A calls or depends on B                  |
| `depends_on`  | A cannot function without B              |
| `contradicts` | A conflicts with B                       |
| `caused`      | A is root cause of B                     |
| `fixed`       | A resolved or repaired B                 |
| `supersedes`  | A replaces or invalidates B              |
| `owns`        | Person/team A is responsible for B       |
| `impacts`     | A affects behavior or health of B        |

```markdown
## Relationships
- uses [[entities/cache]] — read-through caching
- fixed [[entities/incident-42]] — root cause resolved
- supersedes [[concepts/old-approach]]
```

---

## Domain Conventions

> Replace placeholder text with your actual domain configuration.

### `DOMAIN_1` — [Domain 1 Name]

**Purpose**: [What this domain covers]

**Key concept pages to seed early**:
- [Concept 1]
- [Concept 2]

**Domain-specific page types**: [Custom formats beyond sources/concepts/entities]

**Special rules**: [What the LLM should always check or do for this domain]

---

### `DOMAIN_2` — [Domain 2 Name]

**Purpose**: [What this domain covers]

**Key concept pages to seed early**:
- [Concept 1]
- [Concept 2]

**Domain-specific page types**: [Custom formats]

**Special rules**: [Domain-specific behavior]

---

### `DOMAIN_3` — [Domain 3 Name]

**Purpose**: [What this domain covers]

**Key concept pages to seed early**:
- [Concept 1]
- [Concept 2]

**Domain-specific page types**: [Custom formats]

**Special rules**: [Domain-specific behavior]

---

## Cross-Domain Connections

> LLM watches for these and creates wiki/shared/ pages when found.

### DOMAIN_1 ↔ DOMAIN_2
- [Shared concepts, entities, or dependencies]

### DOMAIN_1 ↔ DOMAIN_3
- [Shared concepts, entities, or dependencies]

### DOMAIN_2 ↔ DOMAIN_3
- [Shared concepts, entities, or dependencies]

---

## Tone and Judgment

- Match the wiki owner's expertise level. Flag new or contradictory things; don't over-explain.
- Be direct about uncertainty. Surface contradictions — don't smooth them over.
- Precise claims age better than vague ones. Short pages with good links beat sprawling ones.
- Log and session exports are sacred — never edit history.

---

## Bootstrapping Sequence

```
> customize
> bootstrap
git init && git add wiki/ CLAUDE.md .exportignore .gitignore .claude/ && git commit -m "init wiki"
```

---

## Agent Compatibility

| Agent       | Schema file   | Location                         |
|-------------|---------------|----------------------------------|
| Claude Code | `CLAUDE.md`   | `adapters/claude-code/CLAUDE.md` |
| Codex       | `AGENTS.md`   | `adapters/codex/AGENTS.md`       |
| Cursor      | `.cursorrules`| `adapters/cursor/.cursorrules`   |
| Generic     | `WIKI.md`     | `adapters/generic/WIKI.md`       |

All adapters share `wiki/`, `raw/`, `sessions/`. Only schema file and hooks differ.
Copy the right adapter file to wiki root when switching agents.

---

## Co-Evolution Note

This schema is a starting point, not a final spec. As the wiki grows, update this
file — change conventions that aren't working, add new domains, add page formats.
Note changes in `wiki/log.md`. The schema is code; maintain it like a codebase.

## Scheduled Maintenance

Periodic lint and consolidate are tracked via `.claude/maintenance-state.json`
(gitignored, per person) and reminded via hooks:

- **SessionEnd**: checks if lint is overdue → writes sentinel
- **SessionStart**: checks if lint or consolidate is overdue → prints reminder to LLM

When the LLM sees the reminder, it runs the overdue operations during the session.
After completing, update the state file:

```bash
# After running lint:
python3 -c "
import json, pathlib, datetime
p = pathlib.Path('.claude/maintenance-state.json')
s = json.loads(p.read_text())
s['last_lint'] = str(datetime.date.today())
p.write_text(json.dumps(s, indent=2))
"

# After running consolidate:
python3 -c "
import json, pathlib, datetime
p = pathlib.Path('.claude/maintenance-state.json')
s = json.loads(p.read_text())
s['last_consolidate'] = str(datetime.date.today())
p.write_text(json.dumps(s, indent=2))
"
```

**Configure schedule** (`.claude/maintenance-schedule.json`, gitignored):
```json
{ "lint_days": 7, "consolidate_days": 14 }
```

Decay runs inside LINT — no separate schedule needed.
State and schedule are gitignored so each person runs on their own cadence.

---

*LLM Wiki · MIT License*
