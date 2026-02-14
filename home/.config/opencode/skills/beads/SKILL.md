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

Title is a **positional argument**, not a flag.

```bash
# Epic
bd create "<title>" --type=epic --description="<desc>"

# Task (standalone)
bd create "<title>" --type=task --description="<desc>" --acceptance="<criteria>"

# Task (child of epic)
bd create "<title>" --type=task --parent=<epic-id> \
  --description="<desc>" --acceptance="<criteria>"
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
bd update <id> --claim --json
```

Sets assignee + status=in_progress atomically. If already claimed, the command fails.

### Close

```bash
bd close <id>
```

### Epic Closure

```bash
# Close epics where all children are complete
bd epic close-eligible
```
