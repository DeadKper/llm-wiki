# SQLite FTS5 Session Index

Session exports are indexed in a local SQLite database (`sessions.db`) using FTS5 — SQLite's full-text search extension with BM25 ranking.

## Why SQLite FTS5

- No API calls, no embeddings, no vector database
- BM25 ranking built-in (same algorithm as Elasticsearch/Lucene)
- Runs entirely on local disk
- `sessions.db` is gitignored — local only

## Schema

```sql
CREATE TABLE sessions_raw (
  id           INTEGER PRIMARY KEY,
  filename     TEXT UNIQUE,
  session_id   TEXT,
  export_date  TEXT,
  trigger      TEXT,
  content      TEXT
);

CREATE VIRTUAL TABLE sessions_fts
  USING fts5(
    filename, session_id, export_date, trigger, content,
    content=sessions_raw, content_rowid=id
  );
```

## Useful queries

```bash
# Count indexed sessions
sqlite3 sessions.db "SELECT COUNT(*) FROM sessions_raw;"

# Search with BM25 ranking
sqlite3 sessions.db "
  SELECT filename, snippet(sessions_fts, 4, '>>>', '<<<', '...', 30)
  FROM sessions_fts
  WHERE sessions_fts MATCH 'redis caching'
  ORDER BY rank
  LIMIT 5;"

# Sessions by date
sqlite3 sessions.db "
  SELECT export_date, COUNT(*) FROM sessions_raw
  GROUP BY export_date
  ORDER BY export_date DESC
  LIMIT 10;"
```

## Re-index from scratch

```bash
rm sessions.db
bash .claude/scripts/index-sessions.sh
```

## Scaling beyond index.md

FTS5 covers session exports. Wiki pages are searched via `wiki/index.md` — this works up to ~100 pages. Beyond that, install [qmd](https://github.com/tobi/qmd):

```bash
npm install -g @tobilu/qmd
qmd collection add wiki/ --name my-wiki
qmd embed                  # run once, then after batches of ingests
```

qmd provides hybrid BM25 + vector search with LLM reranking. The agent uses it directly with `-c <collection>` flags from `.claude/wiki-search-config`. Note: `qmd query` (vector + reranking) is slow without GPU — use `qmd search` (BM25 only) for fast lookups. `wiki/index.md` is always kept current as a fallback.
