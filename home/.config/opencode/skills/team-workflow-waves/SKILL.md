---
name: team-workflow-waves
description: "Wave execution phase for team workflow. Steps 0-8: bootstrap, dispatch, implementation, validation, QA, and staff review."
---

# Wave Execution Phase

Repeat until staff review passes. Load `team-workflow-contracts` for handoff formats.

## Global Rules

- **Tracker Writes are Sequential**: Run `tk` writes one at a time.
- **Ticket Status**: Run `tk start <id>` once before first dispatching active work.
- **Sequential Default**: Process one ready task at a time unless tasks are obviously independent and `parallel_safe=true`.
- **Self-Contained Dispatch**: Every worker prompt must include a complete `<task_brief>` (see `team-workflow-contracts` for template).
- **Structured Context**: Wrap briefs in XML tags (`<repo_bootstrap>`, `<invariants>`, `<memory_context>`).
- **High-Signal Audit Trail**: Log only architectural decisions, invariants, UX decisions, pivots, and blockers via `tk add-note`.

## Memory Loop

**Memory Prime** (before dispatch, `memory_mode=active`):

1. `mempalace_mempalace_search` with ticket id/title and scope terms
2. `mempalace_mempalace_kg_query` for ticket id and epic id
3. Build compact `<memory_context>` block, include in downstream prompts

**Memory Writeback** (on task closure, `memory_mode=active`):

1. Capture durable outcomes only
2. `mempalace_mempalace_check_duplicate` before writing
3. `mempalace_mempalace_add_drawer` for new durable text
4. `mempalace_mempalace_kg_add` for relationship facts

**Worker Diaries** (on handoff):

All workers must write a 1-sentence diary entry before handoff:
`mempalace_diary_write(agent_name=<role>, entry=<1-sentence summary of work done and any blockers>)`

The team lead reads these diaries only when a worker returns `NEEDS_REWORK` or `BLOCKED`.

Skip memory operations in `degraded` mode. Note `memory_status=degraded` in handoffs.

## Step 0: Repo Bootstrap (once per run)

Launch `codebase-analyst` to determine: `base_branch`, `lint_command`, `typecheck_command`, `unit_test_command`, `integration_test_command`, `e2e_command`, `build_command`, `playwright_available`. Record `none` instead of guessing. Set `memory_mode` after checking lane availability.

Update todos: mark "Find ready work (wave 1)" as in_progress.

## Step 1: Find Ready Work

`tk ready -T team-task` → split into UI tasks, fast-lane, domain-heavy, standard. Default to first ready task by priority. Group multiple tasks only when `parallel_safe=true`, `areas_touched` don't overlap, and coordination is obviously simple.

Create wave step todos for steps that will execute. Before dispatching, include `<global_rules>` and a complete `<task_brief>` (templates in `team-workflow-contracts`) in the worker prompt.

## Step 2: Domain Brief (selective)

Skip unless task is domain-heavy or underspecified.

1. `invariant-analyst "Review invariants for ticket <id>: <title>"`
2. Include brief excerpts in downstream prompts
3. Log durable core invariants: `tk add-note <id> "INVARIANTS: <summary>"`

## Step 3: UX Design (UI tasks only)

Skip if no UI tasks or fast-lane.

1. `ux-designer "Design ticket <id>: <title>"` with complete `<global_rules>` and `<task_brief>`
2. Verify the response contains all required fields for the role per `team-workflow-contracts`. If missing required fields or unstructured, treat as `NEEDS_REWORK` and escalate.
3. Check `state`: `READY_FOR_IMPLEMENTATION` → dispatch software-engineer; `NEEDS_REWORK`/`BLOCKED` → escalate

## Step 4: Implementation

1. `software-engineer "Implement ticket <id>: <title>"` with complete `<global_rules>` and `<task_brief>` including repo bootstrap, invariant brief, memory context, UX notes when present
2. Verify the response contains all required fields for the role per `team-workflow-contracts`. If missing required fields or unstructured, treat as `NEEDS_REWORK` and escalate.
3. Check `state`: `READY_FOR_QA` → dispatch validation-runner or qa-engineer; `NEEDS_REWORK`/`BLOCKED` → escalate

## Step 5: Validation (selective)

Skip unless validation is expensive, noisy, or server-starting.

1. `validation-runner "Validate ticket <id>: <title>"` with complete `<global_rules>` and `<task_brief>`. Sequential for `requires_server_tests=true`.
2. Verify the response contains all required fields for the role per `team-workflow-contracts`. If missing required fields or unstructured, treat as `NEEDS_REWORK` and escalate.
3. Check `state`: `READY_FOR_QA` → dispatch qa-engineer; `NEEDS_REWORK` → dispatch software-engineer with evidence; `BLOCKED` → escalate

## Step 6: QA

1. `qa-engineer "QA ticket <id>: <title>"` with complete `<global_rules>` and `<task_brief>`. Lightweight for fast-lane.
2. Verify the response contains all required fields for the role per `team-workflow-contracts`. If missing required fields or unstructured, treat as `NEEDS_REWORK` and escalate.
3. Check `state`: `CLOSED` → Memory Writeback, task done; `NEEDS_REWORK` → route to software-engineer or ux-designer; `BLOCKED` → escalate

## Step 7: Wave Summary

Output wave status summary (see `team-workflow-state`), then immediately continue.

1. `tk ls --status=in_progress -T team-task` — check for stuck tasks
2. Discoverability verification for closed tasks
3. Mark wave step todos as completed
4. If unblocked tasks remain → Step 1 (new wave)
5. If `tk ls --status=open -T team-task` and `tk ls --status=in_progress -T team-task` both empty → Step 8

## Step 8: Staff Review

Run when all tasks are closed.

**Review Surface**: If worktree has unrelated changes → use user-approved staged/unstaged surface. Otherwise → `git diff <base_branch>` or epic-scoped diff.

**Run**: `staff-engineer "Review changes for epic <id>. Run: <review-surface-command>"`

**Check Results**:

- `has_blockers=false` → proceed to Epic Closure
- `has_blockers=true`:
  1. Create follow-up issues under same epic
  2. Mine blockers into KG: `mempalace_mempalace_kg_add(subject=<blocker-type>, predicate="seen_in", object=<epic-id>)` and `mempalace_mempalace_kg_add(subject=<blocker-type>, predicate="policy", object=<fix-approach-or-escalation>)`
  3. Update todo "Staff review - blockers found, created follow-ups", return to Step 1

**Todo Updates**: Start = "Staff review" in_progress. Passed = completed, continue automatically. Blockers = completed with follow-ups note, continue to Step 1 automatically.

## Dispatch Matrix

- `codebase-analyst` — Step 0 only, never elsewhere
- `explore` — Quick codebase research during execution
- `invariant-analyst` — Hidden invariants, legacy constraints
- `ux-designer` — User-facing UI changes
- `validation-runner` — Heavy, noisy, server-starting validation
- `staff-engineer` — Step 8 review, high-risk task review

!!CRITICAL!! If you cannot explain in one sentence why a specialist is needed, skip it.

## Exit Condition

Staff review passed (`has_blockers=false`) → Load `team-workflow-closure` skill
