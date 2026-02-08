# Global Agent Guidelines

## Documentation

When you need to search docs, always use `context7` tools.

## Issue Tracking

Use **bd (beads)** for issue tracking. For workflow, use the 'beads' skill.

## Plan Mode

When in **plan mode**, the agent analyzes requirements and creates a implementation plan.
Once the user approves the plan:

1. **Convert plan to beads issues**: Create epics, tasks, and sub-tasks in beads to track the work
2. **Structure**: Use epics for major deliverables, tasks for actionable work, sub-tasks for granular steps
3. **Dependencies**: Link related issues using `bd dep add` to establish blocking relationships
