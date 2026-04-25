---
name: team-workflow-waves
description: "Wave execution phase for team workflow. Steps 0-8: bootstrap, dispatch, implementation, validation, QA, and staff review."
---

# Wave Execution Phase

Repeat until staff review passes. Load `team-workflow-contracts` for handoff formats.

## Global Rules

- **Tracker Writes are Sequential**: Run `tk` writes (`start`, `status`, `close`, `add-note`) one at a time.
- **Ticket Status**: The team lead runs `tk start <id>` once before first dispatching active work.
- **Role Routing**: The team lead prompt determines the current worker role.
- **Sequential Default**: Process one ready task at a time unless the user explicitly requests parallel work or the tasks are obviously independent.
- **Self-Contained Dispatch**: Every worker prompt must include the ticket id, objective, files/areas, acceptance criteria, constraints, and expected validation.
- **Structured Context**: Wrap briefs in XML tags (`<repo_bootstrap>`, `<invariants>`, `<memory_context>`)
- **High-Signal Audit Trail**: Log only architectural decisions, not routine changes
  - `tk add-note <id> "<summary>"` for invariants, UX decisions, architectural pivots, handoffs with durable validation guidance, and blockers

## Memory Loop

### Memory Prime (before dispatch, `memory_mode=active`)

1. `mempalace_mempalace_search` with ticket id/title and scope terms
2. `mempalace_mempalace_kg_query` for ticket id and epic id
3. Build compact `<memory_context>` block
4. Include in downstream worker prompts

### Memory Writeback (on task closure, `memory_mode=active`)

1. Capture durable outcomes only
2. `mempalace_mempalace_check_duplicate` before writing
3. `mempalace_mempalace_add_drawer` for new durable text
4. `mempalace_mempalace_kg_add` for relationship facts

Skip memory operations in `degraded` mode. Note `memory_status=degraded` in handoffs.

## Step 0: Repo Bootstrap (once per run)

Use `codebase-analyst` here for bootstrap. Use `explore` for ad-hoc codebase research elsewhere.

Launch `codebase-analyst` to determine:

- `base_branch`, `lint_command`, `typecheck_command`
- `unit_test_command`, `integration_test_command`, `e2e_command`
- `build_command`, `playwright_available`

Record `none` instead of guessing. Set `memory_mode` after checking lane availability.

Update todos: mark "Find ready work (wave 1)" as in_progress.

## Step 1: Find Ready Work

`tk ready -T team-task` → split into:

- UI tasks (need UX)
- Fast-lane tasks
- Domain-heavy tasks (need invariant-analyst)
- Standard tasks

Default to the first ready task by priority. Group multiple tasks into the same wave only when `parallel_safe=true`, `areas_touched` do not overlap, and the coordination is obviously simple.

Create wave step todos for steps that will execute this wave.

Before dispatching a worker, build this brief and paste it into the worker prompt:

```xml
<task_brief>
ticket_id: <id>
title: <title>
role: <software-engineer|qa-engineer|validation-runner|ux-designer>
objective: <one sentence>
files_or_areas: <paths or subsystems>
acceptance:
- <criterion 1>
- <criterion 2>
constraints:
- <smallest safe change, preserve existing behavior, etc.>
validation: <known commands or none>
notes: <repo bootstrap, invariants, UX notes, memory context, or none>
</task_brief>
```

## Step 2: Domain Brief (selective)

Skip unless task is domain-heavy or underspecified.

1. `invariant-analyst "Review invariants for ticket <id>: <title>"`
2. Include brief excerpts in downstream prompts
3. Log only durable core invariants: `tk add-note <id> "INVARIANTS: <summary>"`

## Step 3: UX Design (UI tasks only)

Skip if no UI tasks or fast-lane.

1. `ux-designer "Design ticket <id>: <title>"` with a complete `<task_brief>`
2. Check `state` field:
   - `READY_FOR_IMPLEMENTATION` → dispatch software-engineer, log durable design guidance when useful
   - `NEEDS_REWORK` / `BLOCKED` → escalate

## Step 4: Implementation

1. `software-engineer "Implement ticket <id>: <title>"` with a complete `<task_brief>`
   - Include repo bootstrap, invariant brief, memory context, UX notes when present
2. Check `state` field:
   - `READY_FOR_QA` → dispatch validation-runner or qa-engineer as appropriate; add a handoff note only for durable validation guidance
   - `NEEDS_REWORK` / `BLOCKED` → escalate

## Step 5: Validation (selective)

Skip unless validation is expensive, noisy, or server-starting.

1. `validation-runner "Validate ticket <id>: <title>"` with a complete `<task_brief>`
   - Sequential for `requires_server_tests=true`
2. Check `state` field:
   - `READY_FOR_QA` → dispatch qa-engineer
   - `NEEDS_REWORK` → dispatch software-engineer with validation evidence
   - `BLOCKED` → escalate

## Step 6: QA

1. `qa-engineer "QA ticket <id>: <title>"` with a complete `<task_brief>`
   - Lightweight for fast-lane tasks
2. Check `state` field:
   - `CLOSED` → Memory Writeback, task done
   - `NEEDS_REWORK` → route to software-engineer or ux-designer
   - `BLOCKED` → escalate

## Step 7: Wave Summary

Output the wave status summary (see `team-workflow-state`), then immediately continue to the next step in the same turn.

1. `tk ls --status=in_progress -T team-task` — check for stuck tasks
2. Discoverability verification for closed tasks
3. Mark wave step todos as completed
4. If unblocked tasks remain → Step 1 (new wave)
5. If `tk ls --status=open -T team-task` and `tk ls --status=in_progress -T team-task` both empty → Step 8 (Staff Review)

## Step 8: Staff Review

Run when all tasks are closed, before proceeding to Epic Closure.

### Determine Review Surface

- If worktree has unrelated changes → use user-approved staged/unstaged surface
- Otherwise → `git diff <base_branch>` or narrower epic-scoped diff

### Run Staff Review

```
staff-engineer "Review changes for epic <id>. Run: <review-surface-command>"
```

### Check Results

- `has_blockers=false` → Staff review passed, proceed to Epic Closure
- `has_blockers=true`:
  1. Create follow-up issues under same epic
  2. Update todo: "Staff review - blockers found, created follow-ups"
  3. Return to Step 1 with new wave

### Todo Updates for Staff Review

- When starting: create "Staff review" todo as in_progress
- If passed: mark "Staff review" as completed, continue to Epic Closure automatically
- If blockers: mark "Staff review" as completed, add note about follow-ups, continue to Step 1 automatically

## Dispatch Matrix

| Agent               | When to Use                                      |
| ------------------- | ------------------------------------------------ |
| `codebase-analyst`  | Step 0 repo bootstrap ONLY — never use elsewhere |
| `explore`           | Quick codebase research during execution         |
| `invariant-analyst` | Hidden invariants, legacy constraints            |
| `ux-designer`       | User-facing UI changes                           |
| `validation-runner` | Heavy, noisy, server-starting validation         |
| `staff-engineer`    | Step 8 review, high-risk task review             |

If you cannot explain in one sentence why a specialist is needed, skip it.

## Exit Condition

Staff review passed (`has_blockers=false`) → Load `team-workflow-closure` skill
