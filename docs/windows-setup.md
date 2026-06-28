# Windows Setup

## Prerequisites

```powershell
# Install Python (includes pip)
winget install Python.Python.3.12

# Install SQLite
winget install SQLite.SQLite

# Install Git
winget install Git.Git

# Optional: GPG
winget install GnuPG.GnuPG
```

Or use [Scoop](https://scoop.sh):
```powershell
scoop install python sqlite git gpg
```

## Run setup

In PowerShell:
```powershell
cd my-wiki
bash scripts/setup.sh
```

If `bash` isn't available, use Git Bash (installed with Git for Windows).

## Shell aliases

Add to PowerShell profile (`notepad $PROFILE`):

```powershell
$env:WIKI_ROOT = "C:\Users\YourName\path\to\my-wiki"

function wikiexit {
    python "$env:WIKI_ROOT\.claude\scripts\export-session.py" --trigger manual --wiki-dir "$env:WIKI_ROOT"
    python "$env:WIKI_ROOT\.claude\scripts\sweep-sessions.py" --days 7 --wiki-dir "$env:WIKI_ROOT"
}

function wikisweep {
    python "$env:WIKI_ROOT\.claude\scripts\sweep-sessions.py" --wiki-dir "$env:WIKI_ROOT"
}
```

Reload: `. $PROFILE`

## SessionEnd hook caveat

On Windows, the SessionEnd hook may not fire reliably when closing Claude Code.
Use `wikiexit` from PowerShell after each session as the reliable alternative.

## Path separators

Scripts use forward slashes internally for cross-platform compatibility.
If you see path errors, verify your wiki root has no spaces (or quote paths).

## SQLite

On Windows, `sqlite3` may not be on PATH after install. Verify:
```powershell
sqlite3 --version
```

If not found, add SQLite to PATH:
`Settings → System → Advanced system settings → Environment Variables → Path → Add SQLite directory`
