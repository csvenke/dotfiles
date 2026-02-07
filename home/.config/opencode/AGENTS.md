# Global Agent Guidelines

## Documentation

When you need to search docs, always use `context7` tools.

## Issue Tracking

Use **bd (beads)** for issue tracking.
Run `bd prime` for workflow context.

**Quick reference:**

- `bd ready` - Find unblocked work
- `bd create "Title" --type task --priority 2` - Create task
- `bd create "Title" --type epic --priority 2` - Create epic
- `bd close <id>` - Complete work
- `bd dep add <issue> <depends-on>` - Add dependency
- `bd sync` - Sync with git (run at session end)

For full workflow details: `bd prime`

## Plan Mode

When in **plan mode**, the agent analyzes requirements and creates a implementation plan.
Once the user approves the plan:

1. **Convert plan to beads issues**: Create epics, tasks, and sub-tasks in beads to track the work
2. **Structure**: Use epics for major deliverables, tasks for actionable work, sub-tasks for granular steps
3. **Dependencies**: Link related issues using `bd dep add` to establish blocking relationships
