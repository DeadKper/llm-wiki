# Team Wiki: Personal Companion Repos

In a team wiki, individual preferences and private context don't belong in the shared
repo. Each person who wants personal context loaded at session start runs their own
private wiki — a companion repo that connects to the team wiki without polluting it.

---

## The split

| Belongs in team wiki | Belongs in personal companion |
|---|---|
| Canonical system docs | LLM interaction preferences |
| Runbooks | Personal notes and takes |
| Architecture decisions | Onboarding notes |
| Incidents | Career context and goals |
| Shared entity pages | Personal projects |

---

## Setting up a personal companion

Each team member clones the template into their own private repo:

```bash
git clone https://github.com/DeadKper/llm-wiki.git my-personal-wiki
cd my-personal-wiki
bash scripts/setup.sh
```

Example domains:

```markdown
| Domain ID | Name     | Root folder      |
|-----------|----------|------------------|
| `me`      | Personal | `wiki/me/`       |
| `work`    | Work     | `wiki/work/`     |
```

`me` — preferences, personal projects, career context.
`work` — personal notes on team systems, distinct from canonical team wiki content.

---

## Connecting to the team wiki

Each person sets this once in the team wiki repo (file is gitignored):

```bash
echo "/path/to/my-personal-wiki" > .claude/personal-wiki-path
```

At session start, `load-personal-prefs.py` loads `wiki/*/preferences/*.md` from the
personal repo into context. Only `preferences/` directories are read. Silent on failure.

---

## What personal `work` notes look like

Personal work notes are your perspective — they can contradict or extend team wiki
pages. Link to authoritative team wiki pages where relevant:

```markdown
## Notes on auth service
My understanding differs slightly from [[/absolute/path/to/team-wiki/wiki/backend/entities/auth-service.md]].
The retry logic in staging behaves differently under load.
```

Use absolute paths — personal and team wikis are separate repos and can be anywhere on disk.

---

## Session search across repos

```bash
# in personal wiki — adds team wiki sessions to recall.sh results
python3 scripts/wire-project.py ~/team-wiki
```
