# Beads Workflow

## Core Rules

- Track strategic work in beads.
- Use `bd create` for all new issues (tasks, features, bugs).
- Check `bd ready` for available work.

## Essential Commands

### Finding Work

- `bd ready` - Show issues ready to work (no blockers).
- `bd list --status=open` - All open issues.
- `bd list --status=in_progress` - Your active work.
- `bd show <id>` - Detailed issue view with dependencies.

### Creating & Updating

- `bd create --title="..." --type=task|bug|feature --priority=2` - New issue.
- `bd update <id> --status=in_progress` - Claim work.
- `bd close <id>` - Mark complete.
- `bd dep add <issue> <depends-on>` - Add dependency (issue depends on depends-on).

### Syncing

- `bd sync --squash` - Update the local beads data file. This does NOT commit or push.

## Common Workflows

**Starting work:**

```bash
bd ready
bd show <id>
bd update <id> --status=in_progress
```

**Completing work:**

```bash
bd close <id1> <id2>
bd sync --squash
```
