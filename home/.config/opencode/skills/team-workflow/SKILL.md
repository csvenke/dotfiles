---
name: team-workflow
description: "Entry point for the team workflow. Phase detection and routing to the phase skills. Always load this first."
---

# Team Workflow

Four phases, run in order. `tk` is the source of truth for live state. MemPalace is
historical evidence only.

Load the phase skill when you enter that phase — not before. Each phase skill is the
authoritative procedure for that phase.

| Phase            | Skill to load             | Description                                    |
| ---------------- | ------------------------- | ---------------------------------------------- |
| `PLANNING`       | `team-workflow-planning`  | Gather requirements, clarify scope, draft plan |
| `ISSUE_CREATION` | `team-workflow-issues`    | Plan approved, create epic and task issues     |
| `WAVE_EXECUTION` | `team-workflow-execution` | Dispatch work in waves, including staff review |
| `EPIC_CLOSURE`   | `team-workflow-closure`   | Memory writeback, pattern mining, and close    |

Also load on demand:

- `team-workflow-dispatch` — before dispatching any worker, for `<global_rules>`,
  `<task_brief>`, handoff contracts, and escalation rules
- `mempalace` — before any memory operation
- `ticket` — before any `tk` command

## Phase Detection

Run these checks in order. Load `ticket` first if `tk` commands are needed.

1. **User approved plan?** No → `PLANNING`
2. **Epic exists with tasks?** `tk query 'select(.type == "epic")'` and
   `tk query 'select(.type == "task" and (.tags // [] | index("team-task")))'` —
   No → `ISSUE_CREATION`
3. **All tasks closed AND staff review passed?** `tk ls --status=open -T team-task`
   and `tk ls --status=in_progress -T team-task` both empty AND last staff review
   `has_blockers=false` → `EPIC_CLOSURE`
4. Otherwise → `WAVE_EXECUTION`

!!CRITICAL!! Post-closure change request: if a previous run reached COMPLETE and the
user asks for changes, fixes, or follow-up, clear approval state and restart at
`PLANNING`.

Transitions are automatic once their condition holds. Stop only when state is unsafe
or a user decision is required. `PLANNING → ISSUE_CREATION` requires explicit user
approval and never happens automatically.

Announce each phase entry and load its skill in the same turn:
`[Phase: WAVE_EXECUTION, Wave: 2]`

## Memory Mode

Load the `mempalace` skill for memory-mode initialization, degraded-mode behavior,
and all read/write protocols. Initialize before phase-specific work, refresh at repo
bootstrap, and include the current mode in downstream prompts.

## Todo Tracking

Create one todo per phase on the first turn, plus one per active wave stage. Mark
them as you go. `tk` is authoritative — todos are a display aid, not state.
