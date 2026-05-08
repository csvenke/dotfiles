---
name: team-workflow-contracts
description: "Handoff contracts and escalation rules for team workflow. Load when dispatching or receiving worker handoffs."
---

# Handoff Contracts

## Dispatch Contract

Every worker prompt from the team lead must include `<global_rules>` followed by a self-contained `<task_brief>`. Workers may read the ticket, but the prompt must be sufficient to start safely.

```xml
<global_rules>
- Treat issue metadata as a starting point, not a ceiling. If observed surface exceeds plan, raise risk or test_expectation and explain why.
- Treat repo bootstrap commands as source of truth. Report missing commands as not run.
- Load the tdd skill only when it materially helps. Do not load by default.
- Reserve at least 15 steps for handoff formatting.
</global_rules>

<task_brief>
ticket_id: <id>
title: <title>
role: <software-engineer|qa-engineer|validation-runner|ux-designer>
objective: <one sentence>
files_or_areas: <paths or subsystems>
acceptance:
- <criterion 1>
- <criterion 2>
constraints:
- <smallest safe change, preserve existing behavior, etc.>
norms:
- <coding standards, patterns to follow, naming conventions — from codebase-analyst or prior work>
safeguards:
- <invariants that must not break, non-negotiable boundaries — from invariant-analyst or domain knowledge>
validation: <known commands or none>
notes: <repo bootstrap, UX notes, memory context, or none>
</task_brief>
```

- `norms` = "how to write the code" — engineering standards the worker should follow (patterns, conventions, style). Omit or use `none` when the codebase has no strong conventions.
- `safeguards` = "what must never break" — hard constraints, invariants, security rules. Omit or use `none` when no known invariants apply.

!!CRITICAL!! If the brief is missing ticket id, objective, or acceptance criteria, the worker must report `BLOCKED` instead of guessing.

## Base Contract (all workflow roles)

Every handoff must include:

1. `state`: `READY_FOR_IMPLEMENTATION` | `READY_FOR_QA` | `CLOSED` | `NEEDS_REWORK` | `BLOCKED`
2. `acceptance_coverage`: which criteria met/not met
3. `files_changed`: comma-separated paths or `none`
4. `qa_or_handoff_notes`: what next role should validate
5. `blockers`: explicit `none` or blocker description

## Global Worker Rules

All workers must follow these rules regardless of role:

- Treat issue metadata (`risk`, `test_expectation`, `areas_touched`, `fast_lane`, repo bootstrap commands) as a starting point, not a ceiling. If the observed change surface is riskier than planned, raise `risk` or `test_expectation` in your handoff and explain why.
- Treat repo bootstrap commands as the source of truth. If a needed command is missing, report it as not run instead of guessing.
- Load the `tdd` skill only when it will materially help write or restructure tests. Do not load it by default.
- Reserve at least 15 steps for handoff formatting.
- Before handoff, write a 1-sentence diary entry: `mempalace_diary_write(agent_name=<your-role>, entry=<1-sentence summary of work done and any blockers>)`

## Role-Specific Extensions

### ux-designer

No extra fields beyond base contract.

### software-engineer

Must also include:

- `tests_added`
- `tests_run_by_implementation`
- `recommended_qa_commands`
- `risk`: low | medium | high
- `test_expectation`: none | targeted | regression | e2e
- `areas_touched`
- `risk_areas`
- `untested_or_not_run`

### validation-runner

Must also include:

- `commands_run`
- `validation_summary`
- `failure_scope`: implementation | infra | none

### qa-engineer

Must also include:

- `tests_added`
- `tests_run_by_implementation`
- `tests_run_by_qa`
- `risk`
- `test_expectation`
- `risk_areas`
- `defect_owner`: software-engineer | ux-designer | none

## Specialist Formats

### codebase-analyst

Compact repo cartography brief (not base contract).

### invariant-analyst

Compact invariant brief (not base contract).

### staff-engineer

Review summary format:

- `has_blockers`: true | false
- `blocker_count`
- `concern_count`
- `suggestion_count`

## Incomplete Responses

!!CRITICAL!! If a subagent response is missing required fields for its role or hits step limit and returns unstructured summary, treat as `NEEDS_REWORK` and escalate.

---

# Escalation Rules

## When to Escalate

- Subagent hits step limit without valid handoff
- Subagent returns without required fields
- Task permanently blocked or requires user intervention
- Issue remains `NEEDS_REWORK` after one full rework cycle
- Requirements unclear or conflicting
- Ticket is missing, already closed unexpectedly, or does not match the worker prompt

## How to Escalate

1. Log blocker to issue: `tk add-note <id> "BLOCKED: <reason>"`
2. !!CRITICAL!! Ask the user only when autonomous continuation is blocked by a real decision, missing requirement, or unsafe state
3. Leave ambiguous issues open

## Special Cases

| Situation                      | Action                                                       |
| ------------------------------ | ------------------------------------------------------------ |
| `EADDRINUSE` / port collision  | Requeue once in sequential server-test lane                  |
| Rework scope unclear           | Use `explore` agent to understand fix surface, then ask user |
| Ticket/prompt mismatch         | Re-check the ticket ID once, then escalate                   |
| Previous rework comment exists | Escalate instead of redispatching                            |

## Logging Rules

Only log to the tracker when it represents:

- Core invariants discovered
- Core UX/interaction decisions
- Architectural pivots
- Fundamental design changes
- Permanent blockers

Do NOT log:

- Routine state changes
- Implementation details
- Test runs
- Minor defects
