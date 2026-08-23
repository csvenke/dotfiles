---
name: team-workflow-execution
description: "Wave execution phase for the team workflow. Repo bootstrap, the wave pipeline, memory loop, and staff review."
---

# Phase 3: Wave Execution

Repeat waves until staff review passes. Load `team-workflow-dispatch` for
`<global_rules>`, `<task_brief>`, handoff contracts, and escalation rules before the
first dispatch.

## Global Rules

- **Tracker writes are sequential**: run `tk` writes one at a time.
- **Ticket status**: run `tk start <id>` once before first dispatching active work.
- **Sequential default**: process one ready task at a time unless tasks are
  obviously independent and `parallel_safe=true`.
- **Self-contained dispatch**: every worker prompt must include `<global_rules>` and
  a complete `<task_brief>`.
- **Structured context**: wrap briefs in XML tags (`<repo_bootstrap>`,
  `<invariants>`, `<memory_context>`).
- **High-signal audit trail**: log only architectural decisions, invariants, UX
  decisions, pivots, and blockers via `tk add-note`.
- **No git mutations**: no agent creates or switches branches, commits, or pushes.
  All work stays uncommitted on the current branch. Review surfaces use read-only
  `git diff` only.

## Memory Loop

Load the `mempalace` skill before memory operations.

**Memory Prime** (before dispatch, `memory_mode=active`): use the `mempalace` Memory
Prime with ticket id/title, scope terms, epic id, and known subsystem or file-area
slugs. Build a compact `<memory_context>` using the `mempalace` schema and include it
in downstream prompts. If memory shows a contradiction not approved during planning,
apply the `mempalace` Memory Conflict Gate before dispatch.

**Risk History Escalation** (`memory_mode=active`): memory that only informs is
wasted. When Memory Prime returns a `risk_history` fact for a subsystem in the task's
`areas_touched`, check `mempalace_mempalace_kg_timeline` for that subsystem before
deciding the escalation level — a single historical hit and a recurring pattern
warrant different responses.

1. Raise `test_expectation` one level (`none`→`targeted`→`regression`→`e2e`) for a
   single historical hit, or two levels for a recurring pattern shown in the
   timeline, and say why in the brief.
2. Set the incremental review trigger for that task.
3. Note the escalation in `<memory_context>` so the worker knows the bar moved and why.

Do not escalate on generic or unrelated risk history. Escalate only when the recorded
risk maps to a subsystem this task actually touches.

**Memory Writeback** (on task closure, `memory_mode=active`): use the `mempalace`
Memory Writeback rules. Write workflow-level task outcomes to `wing=opencode`,
`room=task-outcomes`; write durable project facts, invariants, risks, or decisions to
the project/domain target selected by the `mempalace` skill.

Skip memory operations in `degraded` mode per the `mempalace` skill. Note
`memory_status=degraded` in handoffs.

## Repo Bootstrap (once per run)

Refresh MemPalace availability using the `mempalace` skill. When
`memory_mode=active`, use Memory Prime for prior repo bootstrap and risk memory. Pass
prior memory to `codebase-analyst` as hypotheses to verify, not as source of truth.

Launch `codebase-analyst` to determine: `base_branch`, `lint_command`,
`typecheck_command`, `unit_test_command`, `integration_test_command`, `e2e_command`,
`build_command`, `playwright_available`. Record `none` instead of guessing. Repo
evidence wins over stale memory; report conflicts in the bootstrap brief.

!!CRITICAL!! `lint_command`, `typecheck_command`, and `build_command` become
mandatory mechanical gates for every task in this run. Pass them verbatim in every
`<task_brief>`. A `none` here permanently excuses that gate for the run — so a wrong
`none` silently removes a quality gate. If `codebase-analyst` reports `none` for
typecheck or lint in a repo that plausibly has one, verify before accepting it.

## Wave Pipeline

Each wave runs these stages. Selective stages are skipped unless their condition
holds — if you cannot explain in one sentence why a specialist is needed, skip it.

`explore` is available at any point for quick codebase research, and for dependency
or library source verification when an API cannot be confirmed via `context7`.
`codebase-analyst` is for repo bootstrap only — never dispatch it elsewhere.

**Find ready work.** `tk ready -T team-task` → split into UI, fast-lane,
domain-heavy, and standard tasks. Default to the first ready task by priority. Group
multiple tasks only when `parallel_safe=true`, `areas_touched` don't overlap, and
coordination is obviously simple. Before dispatching, include `<global_rules>` and a
complete `<task_brief>` in the worker prompt, and always pass the repo bootstrap
mechanical gate commands in `validation` or `notes`.

**Domain brief** (selective — domain-heavy or underspecified tasks only).
`invariant-analyst "Review invariants for ticket <id>: <title>"` with complete
`<global_rules>` and `<task_brief>` including repo bootstrap and `<memory_context>`
when present. Include brief excerpts in downstream prompts. Log durable core
invariants: `tk add-note <id> "INVARIANTS: <summary>"`.

**UX design** (selective — UI tasks only, skip for fast-lane).
`ux-designer "Design ticket <id>: <title>"` with complete `<global_rules>` and
`<task_brief>`. `READY_FOR_IMPLEMENTATION` → dispatch software-engineer;
`NEEDS_REWORK`/`BLOCKED` → escalate.

**Implementation.** `software-engineer "Implement ticket <id>: <title>"` with
complete `<global_rules>` and `<task_brief>` including repo bootstrap, invariant
brief, memory context, and UX notes when present. `READY_FOR_QA` → dispatch
validation-runner or qa-engineer; `NEEDS_REWORK`/`BLOCKED` → escalate.

**Validation** (selective — expensive, noisy, or server-starting validation only).
`validation-runner "Validate ticket <id>: <title>"` with complete `<global_rules>`
and `<task_brief>`. Sequential for `requires_server_tests=true`. `READY_FOR_QA` →
dispatch qa-engineer; `NEEDS_REWORK` → dispatch software-engineer with evidence;
`BLOCKED` → escalate.

**QA.** `qa-engineer "QA ticket <id>: <title>"` with complete `<global_rules>` and
`<task_brief>`. Lightweight for fast-lane. Verify `mechanical_gates` are all `pass`
or `none` — a `CLOSED` state with a failing, missing, or unrun gate is invalid, so
treat it as `NEEDS_REWORK` regardless of what the handoff claims. `CLOSED` → Memory
Writeback, task done; `NEEDS_REWORK` → route to software-engineer or ux-designer;
`BLOCKED` → escalate.

**Incremental review** (selective). Catching an architecture problem while one task
is still open is far cheaper than catching it after every task has closed. Run this
**before** the task's QA closure is accepted, when any of these is true:

- `risk=high`
- Memory Prime returned a `risk_history` match for a subsystem in `areas_touched`
- the task introduces a new module, public interface, or third-party dependency
- `staff-engineer` flagged this area in a previous wave of this epic

Most tasks should skip it. Run:
`staff-engineer "Review changes for ticket <id>. review_scope=task:<id>. Run: git diff -- <areas_touched>"`
with `<global_rules>` and the complete `<task_brief>`.
`has_blockers=false` → accept QA closure. `has_blockers=true` → reopen
(`tk status <id> open`), log `tk add-note <id> "STAFF_REVIEW: <blockers>"`, and route
back to implementation with the findings as the rework brief. Record
`mechanical_invariant_gaps` for the epic-closure report even when there are no blockers.

**Wave summary.** Output the status summary below, then immediately continue.
Check for stuck tasks with `tk ls --status=in_progress -T team-task`, verify
discoverability for closed tasks, and mark wave todos complete. If unblocked tasks
remain → start a new wave. If `tk ls --status=open -T team-task` and
`tk ls --status=in_progress -T team-task` are both empty → staff review.

## Staff Review

Run when all tasks are closed.

**Review surface**: if the worktree has unrelated changes → use a user-approved
staged/unstaged surface. Otherwise → `git diff <base_branch>` or an epic-scoped diff.

**Run**: `staff-engineer "Review changes for epic <id>. review_scope=epic. Run: <review-surface-command>"`

Instruct the reviewer to triage by size first and review large diffs in logical
chunks, highest-risk areas first, per the `code-review` skill triage table. Tasks
already cleared by incremental review can be reviewed for integration effects rather
than re-reviewed line by line.

- `has_blockers=false` → proceed to Epic Closure. Do **not** run `tk close <epic-id>`
  here — closing the epic belongs to Phase 4 and must happen after memory writeback.
- `has_blockers=true` → create follow-up issues under the same epic and start a new wave

Carry `mechanical_invariant_gaps` from this review and from any incremental reviews
into Epic Closure for memory writeback.

## Status Output Format

After each wave, output this summary. **Informative only — continue automatically
after outputting it.**

```
## Wave <N> Complete

| Task | Status | Last Agent | Outcome |
|------|--------|------------|---------|
| <id> | <state> | <agent> | <1-line summary> |

- Memory: <active|degraded>
- Mechanical gates: <all pass | list of none | failures routed to rework>
- Incremental reviews run: <count or none>
- Tasks closed this wave: <count>
- Tasks in progress: <count>
- Tasks ready: <count>
- Next: <action>
```

## Exit Condition

Staff review passed (`has_blockers=false`) → load `team-workflow-closure`.
