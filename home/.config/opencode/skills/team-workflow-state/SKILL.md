---
name: team-workflow-state
description: "Phase definitions, transition validations, and checkpoints for the team workflow. Always load this skill first."
---

# Workflow State Machine

This skill defines the team workflow phases and validates transitions.

## Phases

| Phase            | Description                                                      |
| ---------------- | ---------------------------------------------------------------- |
| `PLANNING`       | Gathering requirements, clarifying scope, drafting plan          |
| `ISSUE_CREATION` | Plan approved, creating epic and task issues                     |
| `WAVE_EXECUTION` | Dispatching work in waves (steps 0-8), including staff review    |
| `EPIC_CLOSURE`   | Staff review passed, memory writeback, pattern mining, and close |

## Phase Detection

Run these checks in order to determine current phase:

1. **Has user approved a plan?**
   - No → `PLANNING`
2. **Does epic exist with tasks?**
   - Run: `bd list --type=epic --json` and `bd list --parent=<epic-id> --json`
   - No epic or no tasks → `ISSUE_CREATION`
3. **Are all tasks closed AND staff review passed?**
   - Run: `bd ready --parent=<epic-id>` and `bd list --status=in_progress --parent=<epic-id>`
   - Both empty AND last staff review had `has_blockers=false` → `EPIC_CLOSURE`
   - Otherwise → `WAVE_EXECUTION`

## Transition Validations

Before entering a new phase, validate the transition:

| Transition                      | Validation                                           | Expected          |
| ------------------------------- | ---------------------------------------------------- | ----------------- |
| PLANNING → ISSUE_CREATION       | User said "approve", "yes", "lgtm", or similar       | Explicit approval |
| ISSUE_CREATION → WAVE_EXECUTION | `bd ready --parent=<epic-id>`                        | At least 1 task   |
| WAVE_EXECUTION → EPIC_CLOSURE   | All tasks closed + staff review `has_blockers=false` | Review passed     |
| EPIC_CLOSURE → COMPLETE         | `bd show <epic-id>`                                  | status=closed     |

**These validations are internal.** If validation succeeds, continue automatically in the same turn. Do not ask the user to continue.

If validation fails: stop only when the state is unsafe or requires a user decision. Otherwise recover and continue.

## Wave Step Tracking

Within `WAVE_EXECUTION`, track current step (0-8):

| Step | Name            | Entry Condition                              |
| ---- | --------------- | -------------------------------------------- |
| 0    | Repo bootstrap  | First wave only                              |
| 1    | Find ready work | Start of each wave                           |
| 2    | Domain brief    | Ready tasks need invariant analysis          |
| 3    | UX design       | Ready tasks are UI tasks                     |
| 4    | Implementation  | Tasks ready for implementation               |
| 5    | Validation      | Tasks need heavy validation                  |
| 6    | QA              | Tasks reached READY_FOR_QA                   |
| 7    | Wave summary    | Wave actions complete                        |
| 8    | Staff review    | All tasks closed, review before epic closure |

Output current step before each action: `"[Step 4: Implementation]"`

## Memory Mode

Track `memory_mode` for the entire run:

- `active`: MemPalace operations expected
- `degraded`: MemPalace unavailable, continue without blocking

Set once after Step 0 (bootstrap). Include in all downstream prompts.

## Todo Progress Tracking

Use TodoWrite to show visual progress in the UI.

### Phase Todos (create on first turn)

Create these todos at the start of a new workflow run:

```
TodoWrite([
  { content: "Planning - gather requirements and draft plan", status: "in_progress", priority: "high" },
  { content: "Issue Creation - create epic and tasks", status: "pending", priority: "high" },
  { content: "Wave Execution - implement, validate, and review", status: "pending", priority: "high" },
  { content: "Epic Closure - memory writeback and close", status: "pending", priority: "high" }
])
```

### Phase Transition Updates

| Transition       | Todo Update                                                  |
| ---------------- | ------------------------------------------------------------ |
| → PLANNING       | "Planning" = in_progress                                     |
| → ISSUE_CREATION | "Planning" = completed, "Issue Creation" = in_progress       |
| → WAVE_EXECUTION | "Issue Creation" = completed, "Wave Execution" = in_progress |
| → EPIC_CLOSURE   | "Wave Execution" = completed, "Epic Closure" = in_progress   |
| → COMPLETE       | "Epic Closure" = completed                                   |

### Wave Step Todos

At the start of each wave, create todos only for steps that will execute:

- "Find ready work (wave N)" — always
- "Domain brief (wave N)" — if invariant-analyst needed
- "UX design (wave N)" — if UI tasks present
- "Implementation (wave N)" — if tasks ready
- "Validation (wave N)" — if heavy validation needed
- "QA (wave N)" — if tasks ready for QA
- "Wave N summary" — always
- "Staff review" — only when all tasks closed (final step before closure)

Mark each step `in_progress` when entering, `completed` when done.

Before starting a new wave, mark previous wave's step todos as `completed` (or `cancelled` if skipped).

### Example Todo States

**During wave 1:**

```
[✓] Planning - gather requirements and draft plan
[✓] Issue Creation - create epic and tasks
[●] Wave Execution - implement, validate, and review
    [✓] Find ready work (wave 1)
    [●] Implementation (wave 1)
    [ ] QA (wave 1)
    [ ] Wave 1 summary
[ ] Epic Closure - memory writeback and close
```

**Staff review with follow-ups:**

```
[✓] Planning - gather requirements and draft plan
[✓] Issue Creation - create epic and tasks
[●] Wave Execution - implement, validate, and review
    [✓] Wave 1 summary
    [✓] Staff review - blockers found, created follow-ups
    [●] Find ready work (wave 2)
    [ ] Implementation (wave 2)
    [ ] QA (wave 2)
[ ] Epic Closure - memory writeback and close
```

## Status Output Format

After each wave, output a status summary. **This is informative only — continue automatically after outputting it.** Do not ask the user to continue.

```
## Wave <N> Complete

| Task | Status | Last Agent | Outcome |
|------|--------|------------|---------|
| <id> | <state> | <agent> | <1-line summary> |

- Phase: WAVE_EXECUTION
- Memory: <active|degraded>
- Tasks closed this wave: <count>
- Tasks in progress: <count>
- Tasks ready: <count>
- Next: <action>
```
