#!/bin/bash
# wiki-search.sh — LLM Wiki
# ==========================
# Search wiki pages by query.
# Uses qmd (hybrid BM25 + vector search) when available.
# Falls back to grep over wiki/ when qmd is not installed.
#
# Usage:
#   bash .claude/scripts/wiki-search.sh "your query"
#   bash .claude/scripts/wiki-search.sh "your query" --files   # filenames only
#
# Requirements:
#   qmd (optional) — https://github.com/tobi/qmd
#     Install: npm install -g qmd
#     Index wiki: qmd collection add wiki wiki/
#   grep (fallback, always available)

set -euo pipefail

QUERY="$*"
FILES_ONLY=0

# Parse --files flag
ARGS=()
for arg in "$@"; do
  [ "$arg" = "--files" ] && FILES_ONLY=1 || ARGS+=("$arg")
done
QUERY="${ARGS[*]:-}"

if [ -z "$QUERY" ]; then
  echo "Usage: wiki-search.sh <query> [--files]"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIKI_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PERSONAL_WIKI_PATH_FILE="$WIKI_ROOT/.claude/personal-wiki-path"
PERSONAL_WIKI_ROOT=""
if [ -f "$PERSONAL_WIKI_PATH_FILE" ]; then
  PERSONAL_WIKI_ROOT="$(cat "$PERSONAL_WIKI_PATH_FILE" | tr -d '[:space:]')"
fi

# Load collection names from config; fall back to defaults if missing
WIKI_COLLECTIONS=()
CONFIG_FILE="$WIKI_ROOT/.claude/wiki-search-config"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi
if [ "${#WIKI_COLLECTIONS[@]}" -eq 0 ]; then
  WIKI_COLLECTIONS=("wiki")
  [ -n "$PERSONAL_WIKI_ROOT" ] && WIKI_COLLECTIONS+=("personal-wiki")
fi

# ── qmd path ──────────────────────────────────────────────────────────────────
if command -v qmd &>/dev/null; then
  COLLECTION_FLAGS=""
  for c in "${WIKI_COLLECTIONS[@]}"; do
    COLLECTION_FLAGS="$COLLECTION_FLAGS -c $c"
  done
  if [ "$FILES_ONLY" = "1" ]; then
    qmd query "$QUERY" $COLLECTION_FLAGS --files 2>/dev/null
  else
    qmd query "$QUERY" $COLLECTION_FLAGS -n 8 2>/dev/null
  fi
  exit 0
fi

# ── Fallback: grep over wiki/ ─────────────────────────────────────────────────
echo "⚠️  qmd not found — using grep fallback (no semantic search)"
echo "   Install qmd for hybrid search: npm install -g qmd"
echo ""

SEARCH_DIRS="$WIKI_ROOT/wiki/"
if [ -n "$PERSONAL_WIKI_ROOT" ] && [ -d "$PERSONAL_WIKI_ROOT/wiki" ]; then
  SEARCH_DIRS="$SEARCH_DIRS $PERSONAL_WIKI_ROOT/wiki/"
fi

RESULTS=$(grep -rl "$QUERY" $SEARCH_DIRS 2>/dev/null | head -8)

if [ -z "$RESULTS" ]; then
  echo "No results for: $QUERY"
  exit 0
fi

if [ "$FILES_ONLY" = "1" ]; then
  echo "$RESULTS"
  exit 0
fi

echo "$RESULTS" | while read -r f; do
  echo "📄 $f"
  grep -m 2 -i "$QUERY" "$f" 2>/dev/null | head -c 200
  echo ""
done
