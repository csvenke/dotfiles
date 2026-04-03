---
description: Report concise team workflow status via team agent
agent: team
subtask: true
---

Report concise team workflow status for: $ARGUMENTS

Status policy:

- Route status reporting through the team agent regardless of active primary agent.
- Keep output non-destructive and status-only.
- Keep updates concise and outcome-focused.

Report one current state using exactly one of:

- awaiting approval
- executing wave
- blocked/escalated: <reason>
- complete (all tasks closed)
