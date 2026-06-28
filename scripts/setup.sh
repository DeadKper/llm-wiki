#!/bin/bash
# setup.sh — LLM Wiki
# ====================
# One-time setup. Run once after cloning.
# Creates directory structure, copies adapter files, initializes the database.
#
# Usage:
#   bash scripts/setup.sh [adapter]
#
#   adapter: claude-code (default) | codex | cursor | generic
#
# Examples:
#   bash scripts/setup.sh
#   bash scripts/setup.sh codex

set -euo pipefail

ADAPTER="${1:-claude-code}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "LLM Wiki — Setup"
echo "════════════════"
echo "Adapter : $ADAPTER"
echo "Location: $REPO_ROOT"
echo ""

cd "$REPO_ROOT"

# ── Step 1: Prerequisites ─────────────────────────────────────────────────────
echo "Step 1/6 — Checking prerequisites..."

MISSING=()
command -v python3 &>/dev/null || MISSING+=("python3")
command -v sqlite3 &>/dev/null || MISSING+=("sqlite3")
command -v git    &>/dev/null || MISSING+=("git")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "  Missing: ${MISSING[*]}"
  echo "  Mac:   brew install ${MISSING[*]}"
  echo "  Linux: sudo apt install ${MISSING[*]}"
  exit 1
fi

command -v gpg &>/dev/null && \
  echo "  python3, sqlite3, git, gpg — all found" || \
  echo "  python3, sqlite3, git — found (gpg optional, for encrypted sessions)"

# ── Step 2: Directory structure ───────────────────────────────────────────────
echo ""
echo "Step 2/6 — Creating directory structure..."

mkdir -p raw/assets
mkdir -p wiki/shared
mkdir -p sessions/{exports,confidential,wiki-digests}
touch raw/.gitkeep

echo "  raw/, wiki/, sessions/ created"

# ── Step 3: Copy adapter ──────────────────────────────────────────────────────
echo ""
echo "Step 3/6 — Copying adapter: $ADAPTER..."

case "$ADAPTER" in
  claude-code)
    if [ -d "adapters/claude-code" ]; then
      cp adapters/claude-code/CLAUDE.md ./CLAUDE.md
      mkdir -p .claude/scripts
      cp adapters/claude-code/.claude/settings.json .claude/settings.json
      cp scripts/export-session.py .claude/scripts/
      cp scripts/index-sessions.sh .claude/scripts/
      cp scripts/recall.sh .claude/scripts/
      cp scripts/sweep-sessions.py .claude/scripts/
      cp scripts/wire-project.py .claude/scripts/
      cp scripts/load-personal-prefs.py .claude/scripts/
      cp scripts/scheduled-maintenance.py .claude/scripts/
      cp scripts/wiki-search.sh .claude/scripts/
      chmod +x .claude/scripts/*.sh .claude/scripts/*.py
      cat > .claude/maintenance-state.json << 'JSON'
{
  "last_lint": null,
  "last_consolidate": null
}
JSON
      cat > .claude/maintenance-schedule.json << 'JSON'
{
  "lint_days": 7,
  "consolidate_days": 14
}
JSON
      echo "  CLAUDE.md + .claude/ installed"
    else
      echo "  adapters/claude-code/ not found"
      exit 1
    fi
    ;;
  codex)
    [ -d "adapters/codex" ] && cp adapters/codex/AGENTS.md ./AGENTS.md && echo "  AGENTS.md copied" || echo "  adapters/codex/ not found"
    ;;
  cursor)
    [ -d "adapters/cursor" ] && cp adapters/cursor/.cursorrules ./.cursorrules && echo "  .cursorrules copied" || echo "  adapters/cursor/ not found"
    ;;
  generic)
    [ -f "adapters/generic/WIKI.md" ] && cp adapters/generic/WIKI.md ./WIKI.md && echo "  WIKI.md copied" || echo "  adapters/generic/WIKI.md not found"
    ;;
  *)
    echo "  Unknown adapter: $ADAPTER. Valid: claude-code, codex, cursor, generic"
    exit 1
    ;;
esac

# ── Step 4: Core wiki files ───────────────────────────────────────────────────
echo ""
echo "Step 4/6 — Seeding wiki/index.md and wiki/log.md..."

[ -f "wiki/index.md" ] || cat > wiki/index.md << 'MD'
# Wiki Index

> Master catalog. Updated on every ingest. LLM reads this first on every query.
> Format: `| [[path]] | description | domain | tier | confidence | date |`

---

## DOMAIN_1

| Page | Description | Domain | Tier | Confidence | Date |
|------|-------------|--------|------|------------|------|

---

## DOMAIN_2

| Page | Description | Domain | Tier | Confidence | Date |
|------|-------------|--------|------|------------|------|

---

## DOMAIN_3

| Page | Description | Domain | Tier | Confidence | Date |
|------|-------------|--------|------|------------|------|

---

## Shared (cross-domain)

| Page | Description | Domains | Tier | Date |
|------|-------------|---------|------|------|

---

## Entity Graph

> Typed relationships between key entities. Updated at ingest and crystallize.

```
(no entities yet)
```
MD

[ -f "wiki/log.md" ] || cat > wiki/log.md << 'MD'
# Wiki Log

> Append-only. Never edit past entries.
> Parseable: `grep "^## \[" wiki/log.md | tail -10`

---

MD

echo "  wiki/index.md and wiki/log.md seeded"

# ── Step 5: .exportignore ─────────────────────────────────────────────────────
echo ""
echo "Step 5/6 — Creating .exportignore..."

if [ ! -f ".exportignore" ]; then
  cat > .exportignore << 'EXPORTIGNORE'
# .exportignore — LLM Wiki
# Patterns matched against export filenames.
# Matched files are excluded from the SQLite FTS5 search index.
# They remain on disk but are never searchable.

*_confidential_*.md
*_personal_*.md
*_nda_*.md
*_client_*.md
EXPORTIGNORE
  echo "  .exportignore created"
else
  echo "  .exportignore already exists"
fi

# ── Step 6: Initialize SQLite + optional qmd ─────────────────────────────────
echo ""
echo "Step 6/6 — Initializing session index..."

SCRIPTS_DIR=".claude/scripts"
[ "$ADAPTER" != "claude-code" ] && SCRIPTS_DIR="scripts"
bash "$SCRIPTS_DIR/index-sessions.sh" || true

# qmd: index wiki/ if available
if command -v qmd &>/dev/null; then
  echo ""
  echo "  qmd detected — adding wiki/ as a search collection..."
  qmd collection add wiki wiki/ 2>/dev/null && \
    echo "  qmd collection 'wiki' added (hybrid search enabled)" || \
    echo "  qmd collection add failed — run: qmd collection add wiki wiki/"
else
  echo "  qmd not found — wiki page search will use index.md + grep fallback"
  echo "  To enable hybrid search: npm install -g qmd && qmd collection add wiki wiki/"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════"
echo "Setup complete!"
echo ""
echo "Next steps:"
echo ""
if [ "$ADAPTER" = "claude-code" ]; then
  echo "  1. Edit CLAUDE.md — replace DOMAIN_1/2/3 with your domains"
  echo "     See examples/personal-wiki/ or examples/team-wiki/ for reference"
  echo ""
  echo "  2. Push to a private GitHub repo:"
  echo "     git init && git add . && git commit -m 'init wiki'"
  echo "     git remote add origin git@github.com:YOU/my-wiki.git"
  echo "     git push -u origin main"
  echo ""
  echo "  3. Open Claude Code and bootstrap:"
  echo "     cd $(pwd) && claude"
  echo "     > customize    <- interactive domain setup"
  echo "     > bootstrap    <- create wiki structure"
  echo ""
  echo "  4. Open wiki/ in Obsidian as a vault"
  echo ""
  echo "  5. Start ingesting:"
  echo "     > ingest DOMAIN_1 raw/DOMAIN_1/first-doc.md"
  echo ""
  echo "  Scheduled maintenance:"
  echo "    .claude/maintenance-state.json  — tracks last lint/consolidate (gitignored)"
  echo "    .claude/maintenance-schedule.json — configure cadence (default: lint 7d, consolidate 14d)"
  echo "    SessionEnd checks if lint is due; SessionStart reminds LLM to run overdue ops."
  echo "    After running, LLM updates maintenance-state.json with today's date."
else
  echo "  1. Edit schema file — replace DOMAIN_2, DOMAIN_3"
  echo "  2. Push to a private GitHub repo"
  echo "  3. Open your LLM tool and run: bootstrap"
  echo "  4. See adapters/$ADAPTER/README.md for tool-specific notes"
fi
echo ""
echo "Full instructions: SETUP-GUIDE.md"
echo ""
