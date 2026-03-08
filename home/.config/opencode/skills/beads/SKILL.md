---
name: beads
description: "Command reference for the bd issue tracker (beads). Use when creating, querying, claiming, or closing issues with bd commands."
---

# Task Tracker (Beads)

Short command reference for `bd`.

- Prefer plain output.
- Use `--json` only for multi-item routing, filtering, or validation.
- Use `--silent` when you only need the created issue ID.
- Title is positional for `bd create`.
- Use `--force` on `bd create`.
- Use `--actor=<name>` on any command when audit trail matters.

## Setup

```bash
bd init --stealth
```

## Create

```bash
bd create "<title>" --type=epic --description="<desc>" --force

bd create "<title>" --type=task --description="<desc>" --acceptance="<criteria>" --force

bd create "<title>" --type=task --parent=<epic-id> \
  --description="<desc>" --acceptance="<criteria>" --force
```

## Query

```bash
bd ready
bd ready --parent=<epic-id>
bd ready --parent=<epic-id> --json

bd show <id>
bd list --status=<open|in_progress|closed>
```

## Update

```bash
bd update <id> --claim --actor=<role>
bd update <id> --status=open --assignee=""
bd update <id> --design="<notes>"
```

- `--claim` is atomic and sets assignee plus `in_progress`.
- If claim fails, another agent already has the bead.

## Other

```bash
bd dep add <task-id> <depends-on-id>

bd comments <id>
bd comments add <id> "<message>"

bd close <id>
bd epic close-eligible
```
