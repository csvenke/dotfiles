---
name: ticket
description: "Command reference and workflow conventions for the tk issue tracker. Use before any tk commands."
---

# Issue Tracker (tk)

`tk` is a simple markdown ticket tracker. Use it for ticket scope, dependencies, status, tags, and durable notes.

For weaker models, prefer short commands: create the ticket first, then add details with notes.

## Core Semantics

- `tk start <id>` sets `status: in_progress`.
- Use tags for workflow filtering. Team workflow tickets must use `team-epic` or `team-task`.
- Use notes for durable handoffs and blockers.
- Use the short command forms below for team workflow tickets.

## Create

```bash
tk create "<title>" -t epic --tags team-epic -d "<desc>"
tk create "<title>" -t task --tags team-task,<lane> -d "See SPEC notes." --acceptance "See ACCEPTANCE notes."
tk create "<title>" -t task --parent <epic-id> --tags team-task,<lane> -d "See SPEC notes." --acceptance "See ACCEPTANCE notes."
```

- Lane tags are optional and should be concise: `ui`, `domain-heavy`, `validation`, `fast-lane`, `server-tests`, or a subsystem tag.
- Use only these create flags in team workflow commands: `-t`, `--parent`, `--tags`, `-d`, `--acceptance`.

## Query

```bash
tk ready -T team-task                         # List ready workflow tasks
tk show <id>                                  # Show ticket details
tk ls --status=open -T team-task              # List open workflow tasks
tk ls --status=in_progress -T team-task       # List active workflow tasks
tk ls --status=closed -T team-task            # List closed workflow tasks
tk query 'select(.type == "epic")'            # Query epics as JSON
tk query 'select(.type == "task" and (.tags // [] | index("team-task")))'  # Query workflow tasks as JSON
```

## Update

```bash
tk start <id>              # Set status to in_progress
tk status <id> open        # Reopen for more work
tk add-note <id> "<text>"  # Append timestamped durable note
tk close <id>              # Close ticket
```

- Team lead runs `tk start` before first dispatching active work.
- QA may run `tk close <id>` only after acceptance passes.

## Dependencies

```bash
tk dep <id> <dep-id>       # id depends on dep-id
tk dep tree <id>           # Show dependency tree
tk dep cycle               # Find dependency cycles
tk undep <id> <dep-id>     # Remove dependency
```

## Team Workflow Recipe

Use this recipe exactly for team workflow tickets.

Create the epic with a short description:

```bash
tk create "<epic title>" -t epic --tags team-epic -d "<epic brief>"
```

Create each task with short placeholder description and short acceptance:

```bash
tk create "<task title>" -t task --parent <epic-id> --tags team-task,<lane> -d "See SPEC notes." --acceptance "See ACCEPTANCE notes."
```

Add task details as notes. Keep each note concise; split long text into multiple notes.

```bash
tk add-note <task-id> "SPEC: <what to change, why, and where to start>"
tk add-note <task-id> "ACCEPTANCE: <verifiable acceptance criteria>"
tk add-note <task-id> "METADATA: risk=<low|medium|high>; test_expectation=<none|targeted|regression|e2e>; areas_touched=<paths>; parallel_safe=<true|false>"
```

Start active work:

```bash
tk start <task-id>
```

Record durable handoffs when useful:

```bash
tk add-note <task-id> "HANDOFF: software-engineer -> qa-engineer: <what to validate>"
tk add-note <task-id> "REWORK: qa-engineer -> software-engineer: <specific gap>"
tk add-note <task-id> "BLOCKED: <reason>"
```

Close work:

```bash
tk close <task-id>
tk close <epic-id>
```

## Command Check

Before running `tk create`, check the command against this list:

- It matches one of the create templates above.
- It uses short `-d` and `--acceptance` values.
- Long details are in `tk add-note` commands.

If a `tk` command fails, reload this skill, compare the command to the template, correct it, and retry once.
