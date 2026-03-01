---
name: beads
description: "Command reference for the bd issue tracker (beads). Use when creating, querying, claiming, or closing issues with bd commands."
---

# Task Tracker (Beads)

Command reference for the `bd` issue tracker. All commands support `--json` for programmatic parsing.

## Setup

```bash
bd init --stealth
```

## Commands

### Create

Title is a **positional argument**, not a flag. Always use `--force` to avoid prefix mismatch errors.

```bash
# Epic
bd create "<title>" --type=epic --description="<desc>" --force

# Task (standalone)
bd create "<title>" --type=task --description="<desc>" --acceptance="<criteria>" --force

# Task (child of epic)
bd create "<title>" --type=task --parent=<epic-id> \
  --description="<desc>" --acceptance="<criteria>" --force
```

Use `--silent` to output only the issue ID (for scripting).

### Dependencies

Both arguments are positional.

```bash
bd dep add <task-id> <depends-on-id>
```

### Query

```bash
# Unblocked work
bd ready --json

# Unblocked work under an epic
bd ready --parent=<epic-id> --json

# Full issue details
bd show <id> --json

bd list --status=<open|in_progress|closed> --json
```

### Claim (atomic)

```bash
bd update <id> --claim --actor=<role> --json
```

Sets assignee + status=in_progress atomically. If already claimed, the command fails. Use `--actor` to identify the claiming role (e.g., `--actor=software-engineer`).

### Release (unclaim)

```bash
bd update <id> --status=open --assignee="" --json
```

Resets assignee and status so the next agent in the pipeline can claim.

### Design Notes

```bash
bd update <id> --design="<notes>"
```

Attach implementation-ready design notes to a bead (used by UX handoff).

### Comments

```bash
bd comments <id> --json
bd comments add <id> "<message>"
```

### Close

```bash
bd close <id>
```

### Epic Closure

```bash
# Close epics where all children are complete
bd epic close-eligible --json
```

### Global Flags

These flags work on any `bd` command:

- `--actor=<name>` — set the actor name for audit trail (default: `$BD_ACTOR` or `$USER`)
- `--json` — output in JSON format
