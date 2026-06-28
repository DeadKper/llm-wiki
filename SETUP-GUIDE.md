# Setup Guide

## Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| python3 | Yes | Session export scripts |
| sqlite3 | Yes | FTS5 session search |
| git | Yes | Version history |
| gpg | Optional | Encrypted confidential sessions |
| Obsidian | Optional | Browse wiki with graph view |
| qmd | Optional | Hybrid BM25 + vector search over wiki pages |

```bash
# Mac
brew install sqlite3 gnupg

# Linux
sudo apt install sqlite3 gnupg

# Windows — see docs/windows-setup.md

# qmd (optional, any platform)
npm install -g qmd
```

---

## Part 1 — Initial setup

```bash
git clone https://github.com/DeadKper/llm-wiki.git my-wiki
cd my-wiki
bash scripts/setup.sh          # Claude Code (default)
bash scripts/setup.sh codex    # Codex
bash scripts/setup.sh cursor   # Cursor
bash scripts/setup.sh generic  # Any other agent
```

Setup creates directories, copies adapter files, and initializes the SQLite index.

Open Claude Code and finish setup:

```
> customize    # replace DOMAIN_1/2/3, configure conventions, choose personal content strategy
> bootstrap    # create directory structure, seed pages
```

Then commit:

```bash
git init && git add -A && git commit -m "init wiki"
git remote add origin git@github.com:YOUR-ORG/team-wiki.git
git push -u origin main
```

---

## Part 2 — Domain setup

Domains are knowledge areas: `backend`, `research`, `reading`, `ops`, `learning`, etc.
This wiki works for a single person or a team — structure is the same.

For team wikis, see `examples/team-wiki/` for domain patterns and the personal
companion repo pattern. For personal wikis, see `examples/personal-wiki/`.

---

## Part 3 — Obsidian

Open Obsidian → "Open folder as vault" → select `wiki/`.

- Settings → Files and links → Attachment folder path: `../raw/assets`
- Useful plugins: **Dataview** (query frontmatter), **Graph analysis** (visualize relationships)
- See `docs/obsidian-setup.md` for Dataview query examples.

---

## Part 4 — Session memory

Sessions auto-export to `sessions/exports/` and index to `sessions.db`.

Add shell aliases to `~/.zshrc` or `~/.bashrc`:

```bash
export WIKI_ROOT="$HOME/path/to/my-wiki"

wikiexit()  { python3 "$WIKI_ROOT/.claude/scripts/export-session.py" --trigger manual
              python3 "$WIKI_ROOT/.claude/scripts/sweep-sessions.py" --days 7; }
wikisweep() { python3 "$WIKI_ROOT/.claude/scripts/sweep-sessions.py"; }
```

Windows: see `docs/windows-setup.md`.

---

## Part 5 — Multi-device

Wiki content syncs via git (`sessions/` is gitignored — local only).

On a second machine: `git clone`, then `bash scripts/setup.sh`.

---

## Part 6 — Confidentiality

```bash
touch .claude/no-export         # skip export this session (auto-deletes)
# or say "this session is confidential" at first prompt
```

Add patterns to `.exportignore` to archive sessions but exclude from search.

GPG-encrypt a session: `python3 .claude/scripts/export-session.py --trigger manual --label confidential`

---

## Part 7 — Wiring other projects

```bash
python3 scripts/wire-project.py ~/code/my-app
```

Installs hooks in `my-app/.claude/settings.json` so sessions from that repo also
export to this wiki's session index. See `docs/cross-project-wiring.md`.

---

## Part 8 — Personal wiki integration

Load preferences from a separate wiki repo at session start:

```bash
echo "/path/to/companion-wiki" > .claude/personal-wiki-path
```

Gitignored. Loads `wiki/*/preferences/*.md` from that repo. Silent if not configured
or path not found.

**Personal wiki:** link a companion private repo to keep preferences separate from
main content.

**Team wiki:** each person sets their own path pointing to their private repo —
preferences load per-person without being committed to the shared repo.

---

## Part 9 — Switching agents

```bash
cp adapters/codex/AGENTS.md ./AGENTS.md        # Codex
cp adapters/cursor/.cursorrules ./.cursorrules  # Cursor
cp adapters/generic/WIKI.md ./WIKI.md           # Generic
```

All adapters share `wiki/`, `raw/`, `sessions/`.

---

## Troubleshooting

**Sessions not exporting?** `cat .claude/hooks.log`

**Index stale?** `bash .claude/scripts/index-sessions.sh`

**Missed sessions?** `python3 .claude/scripts/sweep-sessions.py --days 30`

**SQLite empty?** `sqlite3 sessions.db "SELECT COUNT(*) FROM sessions_raw;"` — if 0, re-run index script.
