#!/usr/bin/env python3
"""
scheduled-maintenance.py — LLM Wiki
=====================================
Checks whether periodic wiki maintenance (lint, consolidate) is due and
writes a reminder to .claude/maintenance-due so the LLM sees it at the
next session start.

Called by two hooks:
  SessionEnd   — checks if lint is due (lighter check, flags for next session)
  SessionStart — checks if lint or consolidate is due, prints reminder to LLM

State is tracked in .claude/maintenance-state.json (gitignored, per person).

Schedule defaults (override in .claude/maintenance-schedule.json):
  lint:        every 7 days
  consolidate: every 14 days

Usage:
  python3 .claude/scripts/scheduled-maintenance.py --trigger sessionend
  python3 .claude/scripts/scheduled-maintenance.py --trigger sessionstart
"""

import argparse
import json
import os
import sys
from datetime import datetime, date
from pathlib import Path


DEFAULT_SCHEDULE = {
    "lint_days": 7,
    "consolidate_days": 14,
}


def resolve_wiki_root() -> Path:
    env = os.environ.get("WIKI_ROOT", "")
    if env:
        return Path(env).resolve()
    return Path(".").resolve()


def load_json(path: Path, default: dict) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def save_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def days_since(date_str: str) -> int:
    """Return days since a YYYY-MM-DD date string. Returns large number if unparseable."""
    try:
        last = date.fromisoformat(date_str)
        return (date.today() - last).days
    except Exception:
        return 9999


def is_wiki_root(path: Path) -> bool:
    """True only if path looks like the wiki root, not a wired project."""
    return (path / "wiki" / "index.md").exists() or (
        (path / "CLAUDE.md").exists() and (path / "wiki").is_dir()
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trigger", choices=["sessionend", "sessionstart"], required=True)
    parser.add_argument("--wiki-dir", default="")
    args = parser.parse_args()

    wiki_dir = Path(args.wiki_dir).resolve() if args.wiki_dir else resolve_wiki_root()

    # Guard: only run in the actual wiki root, not in wired project repos.
    # When WIKI_ROOT is set and the session cwd is a different project,
    # wiki_dir still resolves to WIKI_ROOT — which is correct.
    # When WIKI_ROOT is not set and cwd is a wired project, wiki_dir = cwd,
    # which won't have wiki/index.md — guard fires and exits silently.
    if not is_wiki_root(wiki_dir):
        sys.exit(0)

    claude_dir = wiki_dir / ".claude"
    state_path = claude_dir / "maintenance-state.json"
    schedule_path = claude_dir / "maintenance-schedule.json"
    due_path = claude_dir / "maintenance-due"

    schedule = load_json(schedule_path, DEFAULT_SCHEDULE)
    state = load_json(state_path, {"last_lint": None, "last_consolidate": None})

    lint_days = schedule.get("lint_days", DEFAULT_SCHEDULE["lint_days"])
    consolidate_days = schedule.get("consolidate_days", DEFAULT_SCHEDULE["consolidate_days"])

    lint_overdue = days_since(state.get("last_lint") or "2000-01-01") >= lint_days
    consolidate_overdue = days_since(state.get("last_consolidate") or "2000-01-01") >= consolidate_days

    if args.trigger == "sessionend":
        # At session end: write maintenance-due sentinel if lint is overdue.
        # Consolidate is only checked at session start (heavier operation).
        if lint_overdue:
            due_items = []
            if lint_overdue:
                due_items.append(f"lint (last: {state.get('last_lint') or 'never'}, due every {lint_days}d)")
            due_path.write_text("\n".join(due_items), encoding="utf-8")
        # No output at session end — runs silently after export

    elif args.trigger == "sessionstart":
        # At session start: read due sentinel + check consolidate, print reminder to LLM.
        due_items = []
        if lint_overdue:
            due_items.append(f"lint (last: {state.get('last_lint') or 'never'}, due every {lint_days}d)")
        if consolidate_overdue:
            due_items.append(f"consolidate (last: {state.get('last_consolidate') or 'never'}, due every {consolidate_days}d)")

        # Clean up sentinel
        due_path.unlink(missing_ok=True)

        if due_items:
            print("---")
            print("[maintenance] The following wiki operations are due:")
            for item in due_items:
                print(f"  > {item}")
            print("Run them during this session. After running, the LLM should update")
            print(".claude/maintenance-state.json with today's date for each completed op.")
            print("---")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # never crash the session
    sys.exit(0)
