# Changelog

## v1.0.0 — 2026-06-27

Initial release. Full implementation of the LLM Wiki v2 pattern.

### Schema

- Multi-domain wiki (DOMAIN_1/2/3 placeholders — personal or team use)
- Works as personal wiki or shared team wiki — structure identical
- Co-evolution model: schema is code, maintained alongside the wiki

### Memory lifecycle

- Confidence scoring (0.0–1.0) on all knowledge pages
- Per-tier decay: working −0.05, episodic −0.04, semantic −0.03, procedural −0.02 per 30 days
- `last_confirmed` — decay clock; reset by access, corroborating source, or crystallize
- Supersession: contradicted claims marked stale with `superseded_by`
- `## Sources` list on knowledge pages — backing references + implicit count for tier promotion
- Memory tiers: working → episodic → semantic → procedural

### Knowledge graph

- Typed relationships: uses, depends_on, contradicts, caused, fixed, supersedes, owns, impacts
- Entity types: person, org, product, place, regulation, tool, system, project, file, decision, library
- Entity Graph section in `wiki/index.md` — updated at ingest and crystallize
- Source authority: primary | secondary | informal — used for contradiction resolution priority

### Page structure

- `sources/SLUG.md` — immutable summaries, no tier/confidence
- `concepts/NAME.md`, `entities/NAME.md`, `research/threads/THREAD.md` — knowledge pages with full tier/confidence/decay
- `observations/` per domain — episodic pages produced by DIGEST
- `wiki/overview.md` and per-domain `wiki/DOMAIN/overview.md` — cross-domain and per-domain synthesis

### Operations

- INGEST: PII strip, entity extraction, corroboration/contradiction with priority resolution, overview updates, qmd embed
- QUERY: hybrid wiki-search (qmd or fallback), access updates `last_confirmed`, auto-file well-structured answers, log all
- DIGEST: compresses session exports into episodic observations under `observations/`
- CRYSTALLIZE: distills work threads, feeds confidence back into existing pages
- LINT: orphan healing, authority-priority contradiction resolution, quality flagging, tier-rate decay
- CONSOLIDATE: tier promotion working→episodic→semantic→procedural
- Session start: reads log.md tail, domain overviews, active threads for context

### Session automation

- Session export: PreCompact, SessionEnd hooks via Claude Code
- SQLite FTS5 index (`sessions.db`) — BM25-ranked session search via `recall.sh`
- `sweep-sessions.py` — recovery for missed session exports
- `wire-project.py` — wires any project repo to central wiki session index
- Scheduled maintenance: `scheduled-maintenance.py` with WIKI_ROOT guard
  - SessionEnd checks if lint overdue → writes sentinel
  - SessionStart prints overdue ops to LLM
  - Default schedule: lint every 7d, consolidate every 14d (configurable, gitignored)

### Wiki page search

- `wiki-search.sh` — hybrid BM25 + vector via qmd when installed, grep fallback
- `setup.sh` auto-detects qmd, adds `wiki/` collection
- `> wiki: [terms]` operation in schema

### Agent adapters

- Claude Code: full hook integration (PreCompact, SessionEnd, SessionStart, UserPromptSubmit)
- Codex: full schema with manual session export
- Cursor: full `.cursorrules` with all v2 mechanics
- Generic: `WIKI.md` for any agent that reads markdown

### Personal wiki integration

- `.claude/personal-wiki-path` (gitignored, per person) — loads `wiki/*/preferences/*.md` at session start
- `load-personal-prefs.py` — silent on all failure modes, WIKI_ROOT guarded
- Team pattern: each member runs own private wiki repo, links via personal-wiki-path

### Confidentiality

- Sentinel file (`no-export`), `.exportignore`, GPG encryption for confidential sessions
- All session exports, maintenance state, and personal paths are gitignored
