---
name: team-workflow-waves
description: "Wave execution phase for team workflow. Steps 0-8: bootstrap, dispatch, implementation, validation, QA, and staff review."
---

# Wave Execution Phase

Repeat until staff review passes. Load `team-workflow-contracts` for handoff formats.

## Global Rules

- **Tracker Writes are Sequential**: All `bd` commands (update, comments, close) must run one at a time. Never run multiple `bd` writes in parallel — the tracker does not handle concurrent writes.
- **Handoff Claims**: Release previous claim, pre-claim for next target before dispatch
  - Release: `bd update <id> --status=open --assignee=""`
  - Pre-claim: `bd update <id> --claim --actor=<target-role>`
  - Run claim BEFORE comment: `bd update ... && bd comments add ...`
- **Structured Context**: Wrap briefs in XML tags (`<repo_bootstrap>`, `<invariants>`, `<memory_context>`)
- **High-Signal Audit Trail**: Log only architectural decisions, not routine changes
  - `bd comments add <id> "<summary>"` for invariants, UX decisions, architectural pivots

## Memory Loop

### Memory Prime (before dispatch, `memory_mode=active`)

1. `mempalace_mempalace_search` with bead id/title and scope terms
2. `mempalace_mempalace_kg_query` for bead id and epic id
3. Build compact `<memory_context>` block
4. Include in downstream worker prompts

### Memory Writeback (on task closure, `memory_mode=active`)

1. Capture durable outcomes only
2. `mempalace_mempalace_check_duplicate` before writing
3. `mempalace_mempalace_add_drawer` for new durable text
4. `mempalace_mempalace_kg_add` for relationship facts

Skip memory operations in `degraded` mode. Note `memory_status=degraded` in handoffs.

## Step 0: Repo Bootstrap (once per run)

**This is the ONLY step where `codebase-analyst` should be used.** Do not use it anywhere else in the workflow — use `explore` for ad-hoc codebase research.

Launch `codebase-analyst` to determine:

- `base_branch`, `lint_command`, `typecheck_command`
- `unit_test_command`, `integration_test_command`, `e2e_command`
- `build_command`, `playwright_available`

Record `none` instead of guessing. Set `memory_mode` after checking lane availability.

Update todos: mark "Find ready work (wave 1)" as in_progress.

## Step 1: Find Ready Work

`bd ready --parent=<epic-id> --json` → split into:

- UI tasks (need UX)
- Fast-lane tasks
- Domain-heavy tasks (need invariant-analyst)
- Standard tasks

Group by `parallel_safe`, `areas_touched`, `shared_resources`. Only mutually safe tasks share a wave.

Create wave step todos for steps that will execute this wave.

## Step 2: Domain Brief (selective)

Skip unless task is domain-heavy or underspecified.

1. `invariant-analyst "Review invariants for bead <id>: <title>"`
2. Include brief excerpts in downstream prompts
3. Log core invariants: `bd comments add <id> "<summary>"`

## Step 3: UX Design (UI tasks only)

Skip if no UI tasks or fast-lane.

1. `ux-designer "Design bead <id>: <title>"`
2. Check `state` field:
   - `READY_FOR_IMPLEMENTATION` → pre-claim for software-engineer, log design
   - `NEEDS_REWORK` / `BLOCKED` → escalate

## Step 4: Implementation

1. `software-engineer "Implement bead <id>: <title>"`
   - Include repo bootstrap, invariant brief, memory context, UX notes
2. Check `state` field:
   - `READY_FOR_QA` → pre-claim for next step
   - `NEEDS_REWORK` / `BLOCKED` → escalate

## Step 5: Validation (selective)

Skip unless validation is expensive, noisy, or server-starting.

1. `validation-runner "Validate bead <id>: <title>"`
   - Sequential for `requires_server_tests=true`
2. Check `state` field:
   - `READY_FOR_QA` → pre-claim for qa-engineer
   - `NEEDS_REWORK` → pre-claim for software-engineer
   - `BLOCKED` → escalate

## Step 6: QA

1. `qa-engineer "QA bead <id>: <title>"`
   - Lightweight for fast-lane tasks
2. Check `state` field:
   - `CLOSED` → Memory Writeback, task done
   - `NEEDS_REWORK` → route to software-engineer or ux-designer
   - `BLOCKED` → escalate

## Step 7: Wave Checkpoint

Output wave checkpoint (see `team-workflow-state`), then:

1. `bd list --status=in_progress` — check for stuck tasks
2. Discoverability verification for closed tasks
3. Mark wave step todos as completed
4. If unblocked tasks remain → Step 1 (new wave)
5. If `bd ready` and `bd list --status=in_progress` both empty → Step 8 (Staff Review)

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
- If passed: mark "Staff review" as completed
- If blockers: mark "Staff review" as completed, add note about follow-ups

## Dispatch Matrix

| Agent               | When to Use                                   |
| ------------------- | --------------------------------------------- |
| `codebase-analyst`  | Step 0 repo bootstrap ONLY — never use elsewhere |
| `explore`           | Quick codebase research during execution      |
| `invariant-analyst` | Hidden invariants, legacy constraints         |
| `ux-designer`       | User-facing UI changes                        |
| `validation-runner` | Heavy, noisy, server-starting validation      |
| `staff-engineer`    | Step 8 review, high-risk task review          |

If you cannot explain in one sentence why a specialist is needed, skip it.

## Exit Condition

Staff review passed (`has_blockers=false`) → Load `team-workflow-closure` skill
