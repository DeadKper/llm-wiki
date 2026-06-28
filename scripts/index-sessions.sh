#!/bin/bash
# index-sessions.sh — LLM Wiki Template
# ========================================
# Indexes session export markdown files into a SQLite FTS5 database.
# Safe to run repeatedly — skips already-indexed files.
# Respects .exportignore patterns.
#
# Usage:
#   bash scripts/index-sessions.sh
#
# Run automatically at SessionStart (Claude Code) or manually before searching.
#
# Requirements:
#   sqlite3 (brew install sqlite3 / apt install sqlite3)
#   python3 (for JSON escaping)

set -euo pipefail

# Resolve wiki root: WIKI_ROOT env var takes precedence over CWD
if [ -n "${WIKI_ROOT:-}" ]; then
  cd "$WIKI_ROOT"
fi

DB="sessions.db"
EXPORT_DIR="sessions/exports"

if [ ! -f "CLAUDE.md" ] && [ ! -f "AGENTS.md" ] && [ ! -f "WIKI.md" ] && [ ! -f ".cursorrules" ]; then
  echo "⚠️  Run from your wiki root directory (where CLAUDE.md / AGENTS.md / WIKI.md lives), or set WIKI_ROOT."
  exit 1
fi

if ! command -v sqlite3 &> /dev/null; then
  echo "⚠️  sqlite3 not found."
  echo "    Mac:   brew install sqlite3"
  echo "    Linux: sudo apt install sqlite3"
  exit 1
fi

sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS sessions_raw (
  id           INTEGER PRIMARY KEY,
  filename     TEXT UNIQUE,
  session_id   TEXT,
  export_date  TEXT,
  trigger      TEXT,
  content      TEXT
);

CREATE VIRTUAL TABLE IF NOT EXISTS sessions_fts
  USING fts5(
    filename,
    session_id,
    export_date,
    trigger,
    content,
    content=sessions_raw,
    content_rowid=id
  );

CREATE TRIGGER IF NOT EXISTS sessions_ai
  AFTER INSERT ON sessions_raw BEGIN
    INSERT INTO sessions_fts(rowid, filename, session_id, export_date, trigger, content)
    VALUES (new.id, new.filename, new.session_id, new.export_date, new.trigger, new.content);
  END;
SQL

INDEXED=0
SKIPPED=0
ERRORS=0

mkdir -p "$EXPORT_DIR"

for f in "$EXPORT_DIR"/*.md; do
  [ -f "$f" ] || continue

  BASENAME=$(basename "$f")

  IGNORED=0
  if [ -f ".exportignore" ]; then
    while IFS= read -r pattern || [ -n "$pattern" ]; do
      [[ "$pattern" =~ ^[[:space:]]*$ ]] && continue
      [[ "$pattern" =~ ^# ]] && continue
      # shellcheck disable=SC2254
      case "$BASENAME" in
        $pattern) IGNORED=1; break ;;
      esac
    done < ".exportignore"
  fi

  if [ "$IGNORED" = "1" ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  ALREADY=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sessions_raw WHERE filename='$BASENAME';")
  [ "$ALREADY" = "0" ] || continue

  # filename format: YYYY-MM-DD_HHMMSS_sessionid_trigger.md
  SESSION_ID=$(echo "$BASENAME" | grep -oE '[a-f0-9]{8}' | head -1 || echo "unknown")
  EXPORT_DATE=$(echo "$BASENAME" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "unknown")
  TRIGGER=$(echo "$BASENAME" | grep -oE '(precompact|sessionend|manual)' | head -1 || echo "unknown")

  python3 - "$DB" "$f" "$BASENAME" "$SESSION_ID" "$EXPORT_DATE" "$TRIGGER" <<'PYEOF' 2>/dev/null \
    && INDEXED=$((INDEXED + 1)) || ERRORS=$((ERRORS + 1))
import sys, sqlite3 as sq
db, fpath, fname, sid, edate, trig = sys.argv[1:]
content = open(fpath, encoding='utf-8', errors='replace').read()
con = sq.connect(db)
con.execute(
    "INSERT OR IGNORE INTO sessions_raw (filename, session_id, export_date, trigger, content) VALUES (?,?,?,?,?)",
    (fname, sid or 'unknown', edate, trig, content)
)
con.commit(); con.close()
PYEOF

done

TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sessions_raw;" 2>/dev/null || echo "?")

[ "$INDEXED" -gt 0 ] && echo "📚 Indexed $INDEXED new session(s) → sessions.db (total: $TOTAL)"
[ "$SKIPPED" -gt 0 ] && echo "🔒 Skipped $SKIPPED session(s) excluded by .exportignore"
[ "$ERRORS"  -gt 0 ] && echo "⚠️  $ERRORS error(s) during indexing — check file encoding"
[ "$INDEXED" -eq 0 ] && [ "$SKIPPED" -eq 0 ] && [ "$ERRORS" -eq 0 ] && \
  echo "✓  sessions.db up to date ($TOTAL session(s) indexed)"

exit 0
