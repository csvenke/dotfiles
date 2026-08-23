---
name: team-workflow-issues
description: "Issue creation phase for the team workflow. Creating the epic, tasks, acceptance criteria, and dependencies."
---

# Phase 2: Issue Creation

After the user approves the plan, create tracker issues. Load the `ticket` skill
first and follow its Team Workflow Recipe exactly. Keep tracker commands mechanical:
short create command first, then separate `tk add-note` commands for SPEC,
ACCEPTANCE, METADATA, and memory notes when applicable.

## Create Epic and Tasks

```bash
# 1. Initialize on first create (auto-creates .tickets/)
# 2. Create epic (capture the ID)
tk create "<title>" -t epic --tags team-epic -d "<desc>"
# tk create prints the ticket ID → capture as <epic-id>

# 3. Create tasks under the epic
tk create "<title>" -t task --parent <epic-id> --tags team-task,<lane> -d "See SPEC notes." --acceptance "See ACCEPTANCE notes."

# 4. Add task details
tk add-note <task-id> "SPEC: <what to change, why, and where to start>"
tk add-note <task-id> "ACCEPTANCE: <verifiable acceptance criteria>"
tk add-note <task-id> "METADATA: risk=<low|medium|high>; test_expectation=<none|targeted|regression|e2e>; areas_touched=<paths>; parallel_safe=<true|false>"
# Optional when planning found prior work, memory conflicts, or user-confirmed reversals:
tk add-note <task-id> "MEMORY: prior_work=<epic/fact or none>; conflicts=<conflict or none>; risk_history=<risk or none>"
tk add-note <task-id> "REVERSAL_CONFIRMATION: <user confirmation or none>"

# 5. Link dependencies
tk dep <task-id> <dependency-id>
```

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

If any `tk` command fails: stop issuing new tracker commands, reload the `ticket`
skill, compare the failed command to the Team Workflow Recipe, retry once with only
the allowed flags, and ask the user rather than guessing another flag.

## Exit Condition

All planned issues created → load `team-workflow-execution`.
