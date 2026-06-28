# Quick Reference

## Session flow

```
Session start  → hooks index new exports, show last 3 sessions
Working        → ingest sources, ask questions, explore
Session end    → hooks export transcript, index for search
```

## Daily commands

```
> ingest DOMAIN_1 raw/DOMAIN_1/doc.md     ingest into a domain
> [question]                               query the wiki
> recall: authentication changes           search past sessions
> update DOMAIN_2 wiki/DOMAIN_2/page.md   update a page directly
```

## Maintenance (weekly)

```
> digest sessions       extract knowledge from undigested sessions
> lint                  orphans, contradictions, stale claims
> consolidate           promote pages up memory tier ladder
```

## Wiki page search

```bash
qmd search "terms" -c my-wiki -n 8                   # BM25 (exact terms; no GPU needed)
qmd query $'intent: ...\nlex: ...\nvec: ...' -c my-wiki -n 8  # hybrid (slow without GPU)
grep -rl "terms" wiki/ | head -8                     # fallback without qmd
```

## Session export

```bash
bash scripts/recall.sh "search terms"     keyword search
bash scripts/recall.sh --recent 5         last 5 sessions
bash scripts/recall.sh --date 2026-06     sessions from June 2026
bash scripts/recall.sh --list             all indexed sessions
bash scripts/recall.sh --stats            index statistics
```

## Confidential sessions

```bash
touch .claude/no-export                   skip export (auto-removes after session)
# or say "this session is confidential" at first prompt
```

## Recovery

```bash
python3 .claude/scripts/sweep-sessions.py --days 7    recover last 7 days
python3 .claude/scripts/sweep-sessions.py             recover all time
```

## Memory tiers

| Tier | Promoted when | Decay / 30 days |
|------|--------------|-----------------|
| working    | Default on ingest             | −0.05 |
| episodic   | First digest/crystallize      | −0.04 |
| semantic   | ≥ 0.7, 2+ sources            | −0.03 |
| procedural | ≥ 0.9, 3+ sources            | −0.02 |

Decay: per-tier rate every 30 days since `last_confirmed`. Floor 0.0.
Reinforcement: access resets clock. Source/crystallize also raises confidence +0.05.

## Typed relationships (use in page bodies)

```markdown
## Relationships
- uses [[entities/redis]]
- depends_on [[concepts/auth-pattern]]
- supersedes [[concepts/old-approach]]
- owns [[entities/my-service]]
- impacts [[entities/downstream-system]]
```

## Bootstrap sequence (first time only)

```
> customize          replace DOMAIN_1/2/3 placeholders
> bootstrap          create directory structure
git init && git add -A && git commit -m "init wiki"
```

## Wire another project

```bash
python3 scripts/wire-project.py ~/code/my-other-project
```

## Personal wiki integration

```bash
# Configure (gitignored — each person sets their own)
echo "/path/to/your/personal-wiki" > .claude/personal-wiki-path

# Disable
rm .claude/personal-wiki-path
```

Loads `wiki/*/preferences/*.md` from personal wiki at session start.
Silent if not configured or path not found.

