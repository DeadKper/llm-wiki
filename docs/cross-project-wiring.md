# Cross-Project Wiring

Wire any project repo so its sessions export to this central wiki's session index.

## Wire a project

```bash
python3 scripts/wire-project.py ~/code/my-app
```

Installs `.claude/settings.json` hooks in `my-app` pointing to this wiki's scripts.
All sessions from `my-app` then appear in `recall.sh` results.

## Wire multiple projects

```bash
for d in ~/code/*/; do
    python3 scripts/wire-project.py "$d" 2>/dev/null && echo "wired: $d"
done
```

## WIKI_ROOT

Set `export WIKI_ROOT="$HOME/path/to/my-wiki"` in your shell profile.
Scripts resolve wiki root via: `--wiki-dir flag → WIKI_ROOT env → cwd`.
With this set, wired projects work without hardcoded paths.
