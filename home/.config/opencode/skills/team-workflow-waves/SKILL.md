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
- **No Git Mutations**: No agent creates or switches branches, commits, or pushes. All work stays uncommitted on the current branch. Review surfaces use read-only `git diff` only.

## Memory Loop

Load the `mempalace` skill before memory operations. Track lightweight memory counters per the `mempalace` skill.

**Memory Prime** (before dispatch, `memory_mode=active`):

Use the `mempalace` Memory Prime with ticket id/title, scope terms, epic id, and known subsystem or file-area slugs. Build compact `<memory_context>` using the `mempalace` schema and include it in downstream prompts. If memory shows a contradiction not approved during planning, apply the `mempalace` Memory Conflict Gate before dispatch.

**Risk History Escalation** (`memory_mode=active`):

Memory that only informs is wasted. When Memory Prime returns a `risk_history` fact for a subsystem in the task's `areas_touched`:

1. Raise `test_expectation` one level (`none`→`targeted`→`regression`→`e2e`) and say why in the brief.
2. Set the Step 6.5 incremental review trigger for that task.
3. Note the escalation in `<memory_context>` so the worker knows the bar moved and why.

Do not escalate on generic or unrelated risk history. Escalate only when the recorded risk maps to a subsystem this task actually touches.

**Memory Writeback** (on task closure, `memory_mode=active`):

Use the `mempalace` Memory Writeback rules. Write workflow-level task outcomes to `wing=opencode`, `room=task-outcomes`; write durable project facts, invariants, risks, or decisions to the project/domain target selected by the `mempalace` skill.

Skip memory operations in `degraded` mode per the `mempalace` skill. Note `memory_status=degraded` in handoffs.

## Step 0: Repo Bootstrap (once per run)

Refresh MemPalace availability using the `mempalace` skill.

When `memory_mode=active`, use the `mempalace` Memory Prime for prior repo bootstrap and risk memory. Pass prior memory to `codebase-analyst` as hypotheses to verify, not as source of truth.

Launch `codebase-analyst` to determine: `base_branch`, `lint_command`, `typecheck_command`, `unit_test_command`, `integration_test_command`, `e2e_command`, `build_command`, `playwright_available`. Record `none` instead of guessing. Repo evidence wins over stale memory; report conflicts in the bootstrap brief.

!!CRITICAL!! `lint_command`, `typecheck_command`, and `build_command` become mandatory mechanical gates for every task in this run. Pass them verbatim in every `<task_brief>`. A `none` here permanently excuses that gate for the run — so a wrong `none` silently removes a quality gate. If `codebase-analyst` reports `none` for typecheck or lint in a repo that plausibly has one, verify before accepting it.

Update todos: mark "Find ready work (wave 1)" as the only `in_progress` todo. Keep the parent "Wave Execution" todo pending until the phase completes.

## Step 1: Find Ready Work

`tk ready -T team-task` → split into UI tasks, fast-lane, domain-heavy, standard. Default to first ready task by priority. Group multiple tasks only when `parallel_safe=true`, `areas_touched` don't overlap, and coordination is obviously simple.

Create wave step todos only for steps that will execute. Do not create "Staff review" until all tasks are closed and Step 8 is about to run. Before dispatching, include `<global_rules>` and a complete `<task_brief>` (templates in `team-workflow-contracts`) in the worker prompt. Always pass the repo bootstrap mechanical gate commands in `validation` or `notes`.

## Step 2: Domain Brief (selective)

Skip unless task is domain-heavy or underspecified.

1. `invariant-analyst "Review invariants for ticket <id>: <title>"` with complete `<global_rules>` and `<task_brief>` including repo bootstrap and `<memory_context>` when present
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
3. Verify `mechanical_gates` are all `pass` or `none`. A `CLOSED` state with a failing, missing, or unrun gate is invalid — treat as `NEEDS_REWORK` regardless of what the handoff claims.
4. Check `state`: `CLOSED` → Memory Writeback, task done; `NEEDS_REWORK` → route to software-engineer or ux-designer; `BLOCKED` → escalate

## Step 6.5: Incremental Staff Review (selective)

Catching an architecture problem while one task is still open is far cheaper than catching it at Step 8 after every task has closed. Run this step **before** the task's QA closure is accepted.

**Trigger** — run when any of these is true:

- `risk=high`
- Memory Prime returned a `risk_history` match for a subsystem in `areas_touched` (see Risk History Escalation)
- the task introduces a new module, public interface, or third-party dependency
- `staff-engineer` flagged this area in a previous wave of this epic

Skip otherwise. Most tasks should skip this step.

**Run**: `staff-engineer "Review changes for ticket <id>. review_scope=task:<id>. Run: git diff -- <areas_touched>"` with `<global_rules>` and the complete `<task_brief>`.

**Check Results**:

- `has_blockers=false` → accept QA closure, continue to Step 7
- `has_blockers=true` → reopen the task (`tk status <id> open`), log `tk add-note <id> "STAFF_REVIEW: <blockers>"`, and route back to Step 4 with the findings as the rework brief

Record `mechanical_invariant_gaps` for the epic-closure report even when there are no blockers.

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

**Run**: `staff-engineer "Review changes for epic <id>. review_scope=epic. Run: <review-surface-command>"`

Instruct the reviewer to triage by size first and review large diffs in logical chunks, highest-risk areas first, per the `code-review` skill triage table. Tasks already cleared at Step 6.5 can be reviewed for integration effects rather than re-reviewed line by line.

**Check Results**:

- `has_blockers=false` → proceed to Epic Closure
- `has_blockers=true`: create follow-up issues under same epic, update todo "Staff review - blockers found, created follow-ups", return to Step 1

Carry `mechanical_invariant_gaps` from this review and from any Step 6.5 reviews into Epic Closure for memory writeback.

**Todo Updates**: Start = "Staff review" in_progress. Passed = completed, continue automatically. Blockers = completed with follow-ups note, continue to Step 1 automatically.

## Dispatch Matrix

- `codebase-analyst` — Step 0 only, never elsewhere
- `explore` — Quick codebase research during execution; also dependency and library source verification when an API cannot be confirmed via context7
- `invariant-analyst` — Hidden invariants, legacy constraints
- `ux-designer` — User-facing UI changes
- `validation-runner` — Heavy, noisy, server-starting validation
- `staff-engineer` — Step 6.5 incremental task review, Step 8 epic review

!!CRITICAL!! If you cannot explain in one sentence why a specialist is needed, skip it.

## Exit Condition

Staff review passed (`has_blockers=false`) → Load `team-workflow-closure` skill
