---
name: trashman
description: Clean up workspace trash safely - archives old files, logs, empty folders. Maintains reversible cleanup via .trashbin/. Follows strict safeguards to prevent data loss.
---

# Trashman — Safe Workspace Cleanup

## Overview

Trashman is a safety-conscious cleanup agent that scans the workspace for unused files and archives them reversibly to `.trashbin/`. Every action is logged and can be restored.

## Core Principles

1. **Reversibility first** — All deletions go to `.trashbin/`, nothing is permanently removed
2. **Paranoia is healthy** — When in doubt, don't delete
3. **Audit trail** — Every action logged to `.trashlist`
4. **Protection zones** — Critical files and directories are never touched

## Protected Resources (NEVER TOUCH)

**Files:**
- `CLAUDE.md`, `SOUL.md`, `SELF.md`
- `flake.nix`, `configuration.nix`
- `kanban.md`, `scheduled.md`
- `memoria.md` (any task)

**Directories:**
- `modules/`, `stow/`, `projetos/`, `scripts/`
- Anything linked in active kanban cards (Backlog, Em Andamento)

## Cleanup Targets

| Target | Age Threshold | Notes |
|--------|---------------|-------|
| `.ephemeral/scratch/` | > 7 days | Temp files |
| `.ephemeral/logs/` | > 14 days | Archived logs |
| `.ephemeral/notes/` | orphaned | Tasks that don't exist anymore |
| `vault/artefacts/` | > 30 days | Completed tasks (check kanban) |
| `vault/_agent/reports/` | > 30 days | Old reports |
| `vault/sugestoes/` | > 14 days | Reviewed (`reviewed: true` in frontmatter) |
| `vault/` (images) | > 3 days | Unreferenced images (*.png, *.jpg, etc.) |
| Empty directories | after cleanup | Recursively, except protected paths |

## Workflow

```
Scan cleanup targets
  -> Build candidate list (with reasons)
  -> Check against protected resources
  -> Move to .trashbin/ with path preserved
  -> Log each action to .trashlist
Scan for empty directories
  -> Move empty dirs to .trashbin/
  -> Log each removal
Generate report
```

## Step 1: Scan and Build Candidates

For each target category:

```bash
# Example: find old logs
find .ephemeral/logs/ -type f -mtime +14 -not -name ".gitkeep"

# Example: find orphaned notes
find .ephemeral/notes/ -type f | while read f; do
  basename=$(basename "$f" .md)
  # Check if task dir exists in recurring/pending/running/
done

# Example: find unreferenced images
find vault/ -type f \( -name "*.png" -o -name "*.jpg" \) -mtime +3
  # Check if referenced in any .md file
```

**For each candidate:**
- Store path, age, and removal reason
- Cross-check against active kanban (grep for file path in kanban.md)

## Step 2: Archive to .trashbin/

For each approved candidate:

```bash
mkdir -p .ephemeral/.trashbin
# Preserve directory structure
rsync -R <candidate> .ephemeral/.trashbin/

# Register the removal
echo "$(date '+%Y-%m-%d %H:%M') | <path> | <reason>" >> .ephemeral/.trashlist
```

**Example:**
```bash
# Original: vault/sugestoes/2025-10-01-old-idea.md
# Destination: .ephemeral/.trashbin/vault/sugestoes/2025-10-01-old-idea.md
# Log: 2026-03-14 10:30 | vault/sugestoes/2025-10-01-old-idea.md | reviewed >14d ago
```

## Step 3: Empty Directory Cleanup

After file cleanup, recursively find and archive empty directories:

```bash
# Find empty directories (excluding protected paths)
find /workspace \
  -type d \
  -empty \
  -not -path "./modules/*" \
  -not -path "./stow/*" \
  -not -path "./projetos/*" \
  -not -path "./scripts/*" \
  -not -path "./.ephemeral/*" \
  | while read dir; do
    # Move to trashbin and log
  done
```

## Step 4: Generate Report

Create report in context directory:

```markdown
# Trashman Report
**Date:** YYYY-MM-DD HH:MM:SS
**Status:** 🧹 Cleaned N files + M empty directories | ✨ Nothing to clean

## Summary
- Files archived: N
- Empty directories archived: M
- Space freed: ~X MB

## Scan Results
- .ephemeral/scratch/: P items (Q archived)
- .ephemeral/logs/: P items (Q archived)
- .ephemeral/notes/: P items (Q archived)
- vault/artefacts/: P dirs (Q archived)
- vault/_agent/reports/: P items (Q archived)
- vault/sugestoes/: P items (Q archived)
- vault/ images: P items (Q archived)
- Empty directories: P found (M archived)

## Archived Items
[List of moved files/dirs]

## Decisions
[Items that looked suspicious but were preserved]
```

## Safety Checks

Before archiving **always**:

1. ✅ Verify path is not in protected list
2. ✅ Verify file is not referenced in active kanban card
3. ✅ Verify file/dir age meets threshold
4. ✅ If frontmatter file, check frontmatter (e.g., `reviewed: true`)
5. ✅ If age ambiguous, keep it

## Recovery

If a file was archived incorrectly:

```bash
# List what's in trashbin
ls -R .ephemeral/.trashbin/

# Restore a file
cp .ephemeral/.trashbin/<relative-path> <original-location>

# Remove entry from log (optional, for records)
```

## Auto-Evolution

After each run, reflect:

- Are age thresholds too aggressive / too conservative?
- Any new types of trash to monitor?
- False positives that should be protected?

If needed, update this SKILL.md or the recurring task's CLAUDE.md with learnings.

## Quick Checklist

- [ ] Scan all target directories
- [ ] Check protected resources
- [ ] Verify kanban links
- [ ] Archive candidates to .trashbin/
- [ ] Log all archival actions
- [ ] Find and archive empty directories
- [ ] Generate report
- [ ] Reflect on thresholds
