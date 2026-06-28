#!/usr/bin/env python3
"""
load-personal-prefs.py — LLM Wiki
===================================
Loads preference pages from a personal wiki repo (separate repo, separate git)
into the current session context at SessionStart.

Called by the SessionStart hook. Fails silently at every step — if the personal
wiki is not configured, not found, or has no preferences, this script exits 0
and prints nothing. Never blocks the session.

Configuration:
  Create .claude/personal-wiki-path containing the absolute path to the
  personal wiki root. This file is gitignored (local only).

  echo "/home/you/my-personal-wiki" > .claude/personal-wiki-path

Personal wiki structure expected (but not required):
  <personal-wiki>/
  └── wiki/
      └── <any-domain>/
          └── preferences/
              └── *.md     ← these get loaded
"""

import sys
import glob
import os
import pathlib

_wiki_root = pathlib.Path(os.environ.get("WIKI_ROOT", "."))
CONFIG_FILE = _wiki_root / ".claude" / "personal-wiki-path"
MAX_PREFS = 5


def main() -> None:
    # No config → silent exit
    if not CONFIG_FILE.exists():
        return

    try:
        personal_root = pathlib.Path(CONFIG_FILE.read_text().strip())
    except Exception:
        return

    # Path configured but doesn't exist → warn once, then exit
    if not personal_root.exists():
        print(f"[personal-wiki] Path not found: {personal_root}", flush=True)
        print("[personal-wiki] Update .claude/personal-wiki-path or remove it to silence this.", flush=True)
        return

    # Find preference files anywhere under wiki/*/preferences/
    pattern = str(personal_root / "wiki" / "*" / "preferences" / "*.md")
    pref_files = sorted(glob.glob(pattern))

    if not pref_files:
        return

    print(f"[personal-wiki] Loaded {len(pref_files)} preference(s) from {personal_root.name}", flush=True)
    print("", flush=True)

    for path in pref_files[:MAX_PREFS]:
        try:
            content = pathlib.Path(path).read_text(encoding="utf-8").strip()
            if content:
                print(content, flush=True)
                print("", flush=True)
        except Exception:
            continue


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # never crash the session
    sys.exit(0)
