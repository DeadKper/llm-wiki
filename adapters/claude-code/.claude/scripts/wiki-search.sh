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

# ── qmd path ──────────────────────────────────────────────────────────────────
if command -v qmd &>/dev/null; then
  if [ "$FILES_ONLY" = "1" ]; then
    qmd query "$QUERY" --collection wiki --files 2>/dev/null
  else
    qmd query "$QUERY" --collection wiki -n 8 2>/dev/null
  fi
  exit 0
fi

# ── Fallback: grep over wiki/ ─────────────────────────────────────────────────
echo "⚠️  qmd not found — using grep fallback (no semantic search)"
echo "   Install qmd for hybrid search: npm install -g qmd"
echo ""

RESULTS=$(grep -rl "$QUERY" wiki/ 2>/dev/null | head -8)

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
  grep -m 2 -i "$QUERY" "$f" | head -c 200
  echo ""
done
