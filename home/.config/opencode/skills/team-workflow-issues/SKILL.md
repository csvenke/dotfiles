---
name: team-workflow-issues
description: "Issue creation phase for team workflow. Creating epic, tasks, and linking dependencies."
---

# Issue Creation Phase

After the user approves the plan, create tracker issues.

## Prerequisites

1. Load the `beads` skill before running any `bd` commands
2. Use `--actor=team-lead` on all `bd` commands

## Create Epic and Tasks

```bash
# 1. Initialize if needed
bd init --stealth

# 2. Create epic (capture the ID)
bd create "<title>" --type=epic --description="<desc>" --silent --force
# --silent outputs only the issue ID → capture as <epic-id>

# 3. Create tasks under the epic
bd create "<title>" --type=task --parent=<epic-id> \
  --description="<desc>" --acceptance="<criteria>" --force

# 4. Link dependencies
bd dep add <task-id> <dependency-id>
```

## Issue Sizing

| Size        | Characteristics                                         |
| ----------- | ------------------------------------------------------- |
| Right-sized | 1-5 files, one clear concern                            |
| Too small   | One-line fixes, renames, config nits → fold into parent |
| Too large   | Unrelated concerns, 10+ files → split by boundaries     |

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

- `--acceptance` must be concrete and verifiable by QA
- If tests are expected, specify: targeted, regression, or E2E
- Dependencies should reflect real ordering constraints only

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
