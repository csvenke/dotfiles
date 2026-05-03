---
name: team-workflow-state
description: "Phase definitions, transition validations, and checkpoints for the team workflow. Always load this skill first."
---

# Workflow State Machine

## Phases

| Phase            | Description                                                      |
| ---------------- | ---------------------------------------------------------------- |
| `PLANNING`       | Gathering requirements, clarifying scope, drafting plan          |
| `ISSUE_CREATION` | Plan approved, creating epic and task issues                     |
| `WAVE_EXECUTION` | Dispatching work in waves (steps 0-8), including staff review    |
| `EPIC_CLOSURE`   | Staff review passed, memory writeback, pattern mining, and close |

## Phase Detection

Run checks in order:

1. **User approved plan?** No → `PLANNING`
2. **Epic exists with tasks?** `tk query 'select(.type == "epic")'` and `tk query 'select(.type == "task" and (.tags // [] | index("team-task")))'` — No → `ISSUE_CREATION`
3. **All tasks closed AND staff review passed?** `tk ls --status=open -T team-task` and `tk ls --status=in_progress -T team-task` — Both empty AND last staff review `has_blockers=false` → `EPIC_CLOSURE`
4. Otherwise → `WAVE_EXECUTION`

!!CRITICAL!! Post-closure change request: if previous run reached COMPLETE and user asks for changes/fixes/follow-up, clear approval state and restart at PLANNING.

## Transition Validations

Before entering a new phase, validate the transition. If validation succeeds, continue automatically. If validation fails, stop only when state is unsafe or requires user decision; otherwise recover and continue.

| Transition                      | Validation                                           | Expected               |
| ------------------------------- | ---------------------------------------------------- | ---------------------- | --------------- |
| PLANNING → ISSUE_CREATION       | User said "approve", "yes", "lgtm", or similar       | Explicit approval      |
| ISSUE_CREATION → WAVE_EXECUTION | `tk query 'select(.type == "task" and (.tags // []   | index("team-task")))'` | At least 1 task |
| WAVE_EXECUTION → EPIC_CLOSURE   | All tasks closed + staff review `has_blockers=false` | Review passed          |
| EPIC_CLOSURE → COMPLETE         | `tk show <epic-id>`                                  | status=closed          |

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

Create phase todos on first turn:

```
TodoWrite([
  { content: "Planning - gather requirements and draft plan", status: "in_progress", priority: "high" },
  { content: "Issue Creation - create epic and tasks", status: "pending", priority: "high" },
  { content: "Wave Execution - implement, validate, and review", status: "pending", priority: "high" },
  { content: "Epic Closure - memory writeback and close", status: "pending", priority: "high" }
])
```

Update on phase transitions:

| Transition       | Todo Update                                                  |
| ---------------- | ------------------------------------------------------------ |
| → PLANNING       | "Planning" = in_progress                                     |
| → ISSUE_CREATION | "Planning" = completed, "Issue Creation" = in_progress       |
| → WAVE_EXECUTION | "Issue Creation" = completed, "Wave Execution" = in_progress |
| → EPIC_CLOSURE   | "Wave Execution" = completed, "Epic Closure" = in_progress   |
| → COMPLETE       | "Epic Closure" = completed                                   |

Wave step todos (create at start of each wave for steps that will execute):

- "Find ready work (wave N)" — always
- "Domain brief (wave N)" — if invariant-analyst needed
- "UX design (wave N)" — if UI tasks present
- "Implementation (wave N)" — if tasks ready
- "Validation (wave N)" — if heavy validation needed
- "QA (wave N)" — if tasks ready for QA
- "Wave N summary" — always
- "Staff review" — only when all tasks closed

Mark each step `in_progress` when entering, `completed` when done. Before starting a new wave, mark previous wave's step todos as `completed` (or `cancelled` if skipped).

## Status Output Format

After each wave, output a status summary. **This is informative only — continue automatically after outputting it.**

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
