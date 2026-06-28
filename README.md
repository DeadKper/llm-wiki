# LLM Wiki

A knowledge base template built on the LLM Wiki v2 pattern.
The LLM writes and maintains the wiki. You source documents and ask questions.

## What's different about this template

- **v2 memory mechanics** — confidence scoring, memory tiers (working → episodic → semantic → procedural), typed relationships, supersession, and confidence decay
- **Agent-agnostic** — wiki files are plain markdown; adapters in `adapters/` handle agent-specific hooks and schema files
- **Claude Code native** — full hook integration for session export, FTS5 search, and session recall

## Quick start

```bash
# 1. Clone and set up
git clone https://github.com/DeadKper/llm-wiki.git my-wiki
cd my-wiki
bash scripts/setup.sh

# 2. Open Claude Code
claude

# 3. Customize your domains
> customize

# 4. Bootstrap directory structure
> bootstrap

# 5. Initialize git
git init && git add -A && git commit -m "init wiki"
```

## Structure

```
llm-wiki/
├── raw/                  # Immutable source documents (you add, LLM reads)
│   ├── DOMAIN_1/
│   ├── DOMAIN_2/
│   └── assets/
│
├── wiki/                 # LLM-maintained knowledge
│   ├── index.md          # Master catalog (updated on every ingest)
│   ├── log.md            # Append-only operation log
│   ├── DOMAIN_1/
│   ├── DOMAIN_2/
│   └── shared/           # Cross-domain pages
│
├── sessions/             # Auto-exported session transcripts
│   ├── exports/          # Markdown exports (gitignored)
│   └── confidential/     # Encrypted (gitignored)
│
├── adapters/
│   ├── claude-code/      # CLAUDE.md + .claude/settings.json
│   ├── codex/            # AGENTS.md stub
│   ├── cursor/           # .cursorrules stub
│   └── generic/          # WIKI.md stub
│
└── scripts/              # Setup and maintenance scripts
```

## Core operations

| Command | What it does |
|---------|-------------|
| `> ingest [domain] raw/path/file.md` | Read source, extract entities, update wiki |
| `> [question]` | Search wiki + sessions, synthesize answer |
| `> recall: [terms]` | Search past session exports |
| `> digest sessions` | Extract knowledge from undigested sessions |
| `> crystallize [title]` | Distill a completed work thread into wiki pages |
| `> lint` | Health-check: orphans, contradictions, stale claims |
| `> consolidate` | Promote pages up memory tier ladder |
| `> stale-check [domain]` | Re-fetch `manual` sources + any `auto` sources not checked recently |
| `> update [domain] [path]` | Update a page from chat (no raw file needed) |
| `> customize` | Interactive setup for domain names and conventions |
| `> bootstrap` | Create directory structure and seed pages |

## Memory tiers

Every wiki page carries a `memory_tier` and `confidence` score:

| Tier | Description | Confidence threshold |
|------|-------------|---------------------|
| `working`    | Recent observation (default) | Decay: −0.05/30d |
| `episodic`   | Session-level fact           | Decay: −0.04/30d |
| `semantic`   | 2+ sources confirmed         | Decay: −0.03/30d |
| `procedural` | 3+ sources, stable pattern   | Decay: −0.02/30d |

Higher tiers decay slower. Corroborating sources and crystallize sessions raise confidence +0.05 and reset the decay clock.

## Session memory

Every Claude Code session is auto-exported to `sessions/exports/` via hooks.
Sessions are indexed in SQLite FTS5 for fast full-text search.

```bash
bash scripts/recall.sh "search terms"
bash scripts/recall.sh --recent 5
bash scripts/recall.sh --date 2026-06
```

## Wiki page search

Wiki pages are searched via `wiki/index.md` by default. For larger wikis (100+ pages),
install [qmd](https://github.com/tobi/qmd) for hybrid BM25 + vector search:

```bash
npm install -g qmd
qmd collection add wiki wiki/
qmd embed                          # generate vector embeddings (run once, then after ingests)
```

Once installed, `wiki-search.sh` uses qmd automatically:

```bash
bash .claude/scripts/wiki-search.sh "auth flow redesign"
```

Without qmd, the same script falls back to grep. Setup detects qmd and adds the
collection automatically if present.

## Confidential sessions

```bash
touch .claude/no-export           # skip export (auto-removes after session)
# or say "this session is confidential" at first prompt
```

## Agent compatibility

| Agent | Schema file | Location |
|-------|-------------|----------|
| Claude Code | CLAUDE.md | `adapters/claude-code/CLAUDE.md` |
| Codex | AGENTS.md | `adapters/codex/AGENTS.md` |
| Cursor | .cursorrules | `adapters/cursor/.cursorrules` |
| Any | WIKI.md | `adapters/generic/WIKI.md` |

Copy the appropriate file to your wiki root to activate that agent.

## Wiring other projects

```bash
python3 scripts/wire-project.py ~/code/my-project
```

Installs hooks in any project repo so sessions from that project also export
to this wiki's session index.

## Further reading

- `SETUP-GUIDE.md` — detailed setup for all platforms
- `QUICK-REFERENCE.md` — daily cheat sheet
- `adapters/claude-code/CLAUDE.md` — full schema with all operations
- `examples/personal-wiki/` — domain configs and use cases for personal wikis
- `examples/team-wiki/` — domain configs and use cases for team wikis
- `docs/` — Obsidian setup, SQLite explainer, cross-project wiring

---

## Acknowledgements

This template builds on three prior works:

**[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)** by Andrej Karpathy — the original pattern: three-layer architecture (raw sources, wiki, schema), ingest/query/lint operations, and the core insight that LLMs eliminate the bookkeeping bottleneck that makes wikis rot. The foundation everything here is built on.

**[LLM Wiki v2](https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2)** by Rohit Ghumare — production lessons from building [agentmemory](https://github.com/rohitg00/agentmemory): memory lifecycle (confidence scoring, supersession, per-tier decay), typed knowledge graph, automation hooks, quality controls, and crystallization. The v2 mechanics in this template come directly from that spec.

**[llm-wiki-template](https://github.com/bashiraziz/llm-wiki-template)** by Bashir Aziz — the reference implementation that proved the pattern works in practice: Claude Code hook integration, SQLite FTS5 session indexing, multi-device workflow, and the adapter/schema structure this template inherits.

---

*MIT License.*
