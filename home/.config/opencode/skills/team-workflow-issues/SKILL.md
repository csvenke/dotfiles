---
name: team-workflow-issues
description: "Issue creation phase for team workflow. Creating epic, tasks, and linking dependencies."
---

# Issue Creation Phase

After the user approves the plan, create tracker issues.

## Prerequisites

Load the `ticket` skill before running any `tk` commands. Follow its Team Workflow Recipe exactly.

Keep tracker commands mechanical: short create command first, then separate `tk add-note` commands for SPEC, ACCEPTANCE, and METADATA.

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

# 5. Link dependencies
tk dep <task-id> <dependency-id>
```

## Issue Sizing

| Size        | Characteristics                                         |
| ----------- | ------------------------------------------------------- |
| Right-sized | 1-5 files, one clear concern                            |
| Too small   | One-line fixes, renames, config nits → fold into parent |
| Too large   | Unrelated concerns, 10+ files → split by boundaries     |

Prefer one right-sized task over many small subtasks. Create multiple tasks only when there is a real dependency boundary or independent work surface.

## Default Metadata

Use these defaults unless the task needs different values:

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

- `--acceptance` must be concrete and verifiable by QA.
- If tests are expected, specify: targeted, regression, or E2E
- Dependencies should reflect real ordering constraints only
- Put task metadata in `METADATA:` notes; `tk` does not have dedicated metadata fields beyond frontmatter.

## Command Recovery

If any `tk` command fails:

1. Stop issuing new tracker commands.
2. Reload the `ticket` skill.
3. Compare the failed command to the exact Team Workflow Recipe.
4. Retry once with only the allowed flags.
5. If retry fails, ask the user instead of guessing another flag.

## Issue Descriptions

Issue descriptions are the agent's starting brief:

- What to change
- Why
- Where to start reading
- Design decisions

## Routing Rules

- Single worktree: default to sequential
- Parallelize only when `parallel_safe=true` AND `areas_touched` don't overlap
- Mark `requires_server_tests=true` for work that starts app services
- Use `fast_lane=true` only for docs, comments, safe config tweaks

## Exit Condition

All planned issues created → Load `team-workflow-waves` skill
