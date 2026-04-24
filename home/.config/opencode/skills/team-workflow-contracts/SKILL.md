---
name: team-workflow-contracts
description: "Handoff contracts and escalation rules for team workflow. Load when dispatching or receiving worker handoffs."
---

# Handoff Contracts

## Base Contract (all workflow roles)

Every handoff must include:

1. `state`: `READY_FOR_IMPLEMENTATION` | `READY_FOR_QA` | `CLOSED` | `NEEDS_REWORK` | `BLOCKED`
2. `acceptance_coverage`: which criteria met/not met
3. `files_changed`: comma-separated paths or `none`
4. `qa_or_handoff_notes`: what next role should validate
5. `blockers`: explicit `none` or blocker description

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

If a subagent response:

- Missing required fields for its role
- Hits step limit and returns unstructured summary

Then: treat as `NEEDS_REWORK`, release pre-claim, escalate.

---

# Escalation Rules

## When to Escalate

- Subagent hits step limit without valid handoff
- Subagent returns without required fields
- Task permanently blocked or requires user intervention
- Issue remains `NEEDS_REWORK` after one full rework cycle
- Requirements unclear or conflicting
- Worker reports pre-claim missing or held by wrong assignee

## How to Escalate

1. Release any pre-claim
2. Log blocker to issue: `bd comments add <id> "BLOCKED: <reason>"`
3. Pause and ask the user
4. Do not auto-close ambiguous issues

## Special Cases

| Situation                       | Action                                                |
| ------------------------------- | ----------------------------------------------------- |
| `EADDRINUSE` / port collision   | Requeue once in sequential server-test lane           |
| Rework scope unclear            | Use `explore` agent to understand fix surface, then ask user |
| Pre-claim orchestration failure | Release, re-pre-claim once, retry once, then escalate |
| Previous rework comment exists  | Escalate instead of redispatching                     |

## Logging Rules

Only log to beads when it represents:

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
