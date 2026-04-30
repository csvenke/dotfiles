---
description: Close a team workflow run, clean up open tickets, and capture learnings
agent: general
---

Close the current team workflow run. Clean up all open tickets and capture a retrospective so the learning is not lost.

Close reason (optional): $ARGUMENTS

## Instructions

Execute these steps in order:

### Step 1: Load ticket skill and find the target epic

Load the `ticket` skill, then find all open team epics:

```bash
tk query 'select(.type == "epic" and (.tags // [] | index("team-epic")) and .status != "closed")'
```

- If **no open epics** exist, report "No open workflow epics found" and stop.
- If **exactly one** open epic exists, select it automatically.
- If **multiple** open epics exist, present them to the user with the `question` tool and ask which epic to close.

Record the selected `epic_id`.

### Step 2: Find tasks belonging to this epic

Find all tasks that are children of the selected epic:

```bash
tk query 'select(.type == "task" and .parent == "<epic_id>")'
```

This scopes the close to only the tasks belonging to the selected epic. Unrelated tickets are left untouched.

### Step 3: Annotate and close tickets

For each task from Step 2 that is not already closed:

```bash
tk add-note <id> "CLOSED: Workflow run closed by user. Reason: <close reason or 'no reason given'>"
tk close <id>
```

Then close the epic itself:

```bash
tk add-note <epic_id> "CLOSED: Workflow run closed by user. Reason: <close reason or 'no reason given'>"
tk close <epic_id>
```

### Step 4: Retrospective and pattern mining

Load `skill team-workflow-closure` and execute its **Step 2 (Workflow Retrospective)** and **Step 3 (Pattern Mining)**.

Use these values:

- `run_outcome: closed`
- `close_reason`: the user-provided reason, or "not specified"
- `tasks_completed`: tasks from Step 2 that were already closed before this close
- `tasks_abandoned`: tasks from Step 2 that were open/in-progress at close time

### Step 5: Report

Report to the user:

- Which tickets were closed
- Summary of the retrospective stored
- Any patterns recorded
