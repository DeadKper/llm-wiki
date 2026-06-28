# Obsidian Setup

1. Open Obsidian → "Open folder as vault" → select `wiki/`
2. Settings → Files and links:
   - Attachment folder path: `../raw/assets`
   - Use wikilinks: on
3. Optional plugins (Community):
   - **Dataview** — query frontmatter (tier, confidence, dates)
   - **Graph analysis** — visualize typed relationships
   - **Marp** — generate slide decks from wiki content

## Useful views

- Graph View — see wiki shape: hubs, orphans, clusters
- Dataview query for low-confidence pages:
  ```dataview
  TABLE confidence, memory_tier, last_updated
  FROM "wiki"
  WHERE confidence < 0.5
  SORT confidence ASC
  ```

- Dataview query for stale pages:
  ```dataview
  TABLE last_updated, memory_tier
  FROM "wiki"
  WHERE last_updated < date(today) - dur(30 days)
  SORT last_updated ASC
  ```

## Image downloads

Settings → Hotkeys → search "Download attachments" → bind to Ctrl+Shift+D.
After clipping a web article, hit the hotkey to download all images locally to `raw/assets/`.
