---
description: Resume an existing team workflow epic
agent: team
---

Use the team agent workflow in `home/.config/opencode/agents/team.md`.

Resume request: $ARGUMENTS

Resume policy:
- Treat this as execution-mode orchestration for existing work, not new planning.
- Load the `beads` skill before any `bd` commands.
- Discover open epics and task state from `bd` first.

Selection logic:
1. Find open epics that still have non-closed tasks.
2. If exactly one matching epic exists, summarize current status (ready, in_progress, blocked, remaining) and continue execution from the next valid team.md step.
3. If multiple matching epics exist, ask the user which epic to resume using the Questions tool before taking execution actions.
4. If no matching epic exists, report that there is nothing resumable and suggest running `/team-plan` for new work.

Execution rules:
- Do not create a new epic unless the user explicitly asks.
- Follow team.md handoff claims, wave routing, escalation, and closure rules once an epic is selected.
