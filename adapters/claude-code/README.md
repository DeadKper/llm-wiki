# Claude Code Adapter

Full integration: automatic session export, FTS5 search, personal wiki preferences.

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Wiki schema — copy to wiki root |
| `.claude/settings.json` | Hook configuration |
| `.claude/scripts/` | All hook scripts |

Run `bash scripts/setup.sh` to install everything automatically.

## Hooks

**SessionStart** — indexes new exports, shows last 3 sessions, loads personal preferences if configured.

**PreCompact** — exports session before `/compact`.

**SessionEnd** — exports session on exit (skips if PreCompact already ran).

**UserPromptSubmit** — creates `.claude/no-export` sentinel if first prompt is "this session is confidential".

## Troubleshooting

```bash
cat .claude/hooks.log                                    # hook invocation log
bash .claude/scripts/index-sessions.sh                   # re-index
python3 .claude/scripts/sweep-sessions.py --days 7       # recover missed sessions
```
