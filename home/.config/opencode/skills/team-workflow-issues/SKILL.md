---
name: team-workflow-issues
description: "Issue creation phase for the team workflow. Creating the epic, tasks, acceptance criteria, and dependencies."
---

# Phase 2: Issue Creation

After the user approves the plan, create tracker issues. Load the `ticket` skill
first and follow its Team Workflow Recipe exactly. Keep tracker operations mechanical:
create first, then separate `add_note` operations for SPEC,
ACCEPTANCE, METADATA, and memory notes when applicable.

## Create Epic and Tasks

1. Capture the pre-create baseline: run `query_epics` and record the returned IDs
   and the current time as `launch_time`, then run `ticket_tracker` operation
   `create_epic`; capture the returned `<epic-id>`. This baseline is what
   `ticket` skill Recovery uses to correlate an ambiguous create failure — never
   skip it, even when the create looks likely to succeed.
2. For each task: capture the pre-create baseline by running `query_children` with
   `parent=<epic-id>` and recording the returned IDs and `launch_time`, then run
   `create_task` with `parent=<epic-id>` and the lane; capture `<task-id>`.
3. Run separate `add_note` operations for `SPEC:`, `ACCEPTANCE:`, and `METADATA:`.
4. Add `MEMORY:` and `REVERSAL_CONFIRMATION:` notes when planning found relevant
   history, conflicts, or a user-confirmed reversal.
5. Run `add_dependency` only for real ordering constraints.

## Issue Sizing

| Size        | Characteristics                                         |
| ----------- | ------------------------------------------------------- |
| Right-sized | 1-5 files, one clear concern                            |
| Too small   | One-line fixes, renames, config nits → fold into parent |
| Too large   | Unrelated concerns, 10+ files → split by boundaries     |

Prefer one right-sized task over many small subtasks. Create multiple tasks only
when there is a real dependency boundary or independent work surface.

## Default Metadata

```
risk=medium
test_expectation=targeted
requires_server_tests=false
shared_resources=none
parallel_safe=false
fast_lane=false
```

Always include `areas_touched=<subsystems/files>`.

## Acceptance Criteria

Weak acceptance criteria are the root cause of weak QA. A criterion that cannot be
falsified cannot gate anything.

Every criterion must name **an observable behavior** and **how it is verified**:

- Good: `Invalid tokens return 401 and log an auth_failed event — verify with the auth unit suite`
- Good: `Config file missing does not crash; falls back to defaults — verify by running the CLI with no config present`
- Bad: `Works correctly` / `Handles errors properly` / `Code is clean`

Rules:

- `--acceptance` must be concrete and verifiable by QA without asking the
  implementer what was meant.
- Reject and rewrite any criterion that has no observable behavior or no
  verification path.
- If tests are expected, specify which kind: targeted, regression, or E2E.
- Dependencies should reflect real ordering constraints only.
- Put task metadata in `METADATA:` notes; `tk` has no dedicated metadata fields
  beyond frontmatter.

## Issue Descriptions

Issue descriptions are the agent's starting brief: what to change, why, where to
start reading, design decisions.

When planning found relevant prior work, memory conflicts, or user-confirmed
reversals, preserve them in separate task notes. Keep `SPEC:` focused on the
requested work and use memory notes for downstream `<memory_context>`
reconstruction. If no memory findings apply, skip memory notes.

## Routing Rules

- Single worktree: default to sequential
- Parallelize only when `parallel_safe=true` AND `areas_touched` don't overlap
- Mark `requires_server_tests=true` for work that starts app services
- Use `fast_lane=true` only for docs, comments, safe config tweaks

## Command Recovery

If any tracker operation fails: reload the `ticket` skill and follow its Recovery
section — classify the failure as pre-exec (non-mutating, fix and retry) or
post-launch (ambiguous; reconcile against live tracker state via `query`/`show`
before ever retrying create/add/status/dependency operations). For `create_epic`/
`create_task`, reconciliation requires the baseline captured in step 1/2 above —
never adopt a same-title ticket without a baseline-diff match. Ask the user rather
than guessing when the reconciliation read cannot correlate a single ticket with
confidence.

## Exit Condition

All planned issues created → load `team-workflow-execution`.
