# Contributing

## Most needed

- **New agent adapters** — Gemini, Aider, Zed, Continue.dev, Windsurf
  - Start from `adapters/generic/WIKI.md`
  - Add hook configuration for the tool
  - Add `adapters/TOOLNAME/README.md`

- **Script improvements**
  - `index-sessions.py` — Python port of `index-sessions.sh` (Windows compatibility)
  - `recall.py` — Python port of `recall.sh`

## Adapter requirements

A complete adapter must have:
1. Schema file (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, or `WIKI.md`)
2. Hook or manual export instructions
3. `README.md` with setup notes

The schema file must document:
- Domain table with DOMAIN_1/2/3 placeholders
- Session start behavior (read log.md, overviews, active threads)
- Core operations: ingest, query, crystallize, digest, lint, consolidate
- Memory tiers with per-tier decay rates (working −0.05, episodic −0.04, semantic −0.03, procedural −0.02)
- Typed relationships: uses, depends_on, contradicts, caused, **fixed**, supersedes, owns, impacts
- Entity types: person, org, product, place, regulation, tool, system, **project, file, decision, library**
- `source_authority` on source pages (primary | secondary | informal)
- `## Sources` list on knowledge pages (concepts, entities, threads, observations)
- `last_confirmed` frontmatter on knowledge pages
- Source pages have no confidence/memory_tier/last_confirmed
- Index format: source pages use `-` in tier/confidence columns
- `observations/` subdirectory for digest-origin episodic pages
- wiki search: use `qmd search`/`qmd query -c <collection>` if qmd available (collections from `.claude/wiki-search-config`), fall back to grep + index.md; `wiki/index.md` always kept current

## File naming

- Adapters: `adapters/TOOLNAME/` + schema file + `README.md`
- Docs: `docs/TOPIC.md`

## Testing

1. `bash scripts/setup.sh ADAPTERNAME`
2. Verify directories created (including `observations/`)
3. Verify schema copied to wiki root
4. Test ingest (check source page has no tier/confidence; entity page has Sources list)
5. Test query (check last_confirmed updated on read pages)
6. Test lint (check decay uses tier-specific rates)
7. Verify no personal/individual content bleeds into shared wiki domains

## License

MIT.
