---
name: team-workflow-contracts
description: "Handoff contracts and escalation rules for team workflow. Load when dispatching or receiving worker handoffs."
---

# Handoff Contracts

## Dispatch Contract

Every worker prompt from the team lead must include `<global_rules>` followed by a self-contained `<task_brief>`. Workers may read the ticket, but the prompt must be sufficient to start safely.

Load the `mempalace` skill before adding or interpreting `<memory_context>`.

```xml
<global_rules>
- Treat issue metadata as a starting point, not a ceiling. If observed surface exceeds plan, raise risk or test_expectation and explain why.
- Treat repo bootstrap commands as source of truth. Report missing commands as not run.
- Run every mechanical gate discovered in repo bootstrap (lint, typecheck, build) that applies to your role. Report each as pass, fail, or none. Never report a gate as passing without running it.
- Verify unfamiliar library or framework APIs before using them. Use context7 for documented libraries, or read the dependency source. Never infer a signature, option name, or return shape. If an API cannot be verified, say so in your handoff instead of guessing.
- Stop and return NEEDS_REWORK if the change would exceed roughly twice the briefed files_or_areas, or introduce a new module, public interface, or dependency that is not in the brief. Do not silently expand scope.
- Load the tdd skill when fixing a bug, or when it otherwise materially helps. Do not load by default for other work.
- Reserve at least 15 steps for handoff formatting.
- Never create or switch branches, commit, push, or otherwise mutate git state. Work on the current branch and leave changes uncommitted in the worktree.
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

When memory is active, include a `<memory_context>` block after `<task_brief>` if any relevant memory exists. Use the schema from the `mempalace` skill. If memory is degraded, include `memory_status: degraded` and do not invent prior work.

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

### Mechanical Gates

Repo bootstrap discovers `lint_command`, `typecheck_command`, and `build_command`. These are the cheapest, highest-signal quality checks available and they are not optional.

- Run every discovered gate that applies to your role before handing off.
- Report each as `pass`, `fail`, or `none`. `none` means `codebase-analyst` returned `none` for that command — not that you chose to skip it.
- Never report a gate as `pass` without having run it and seen it succeed.
- A `fail` on any gate means the work is not ready. Fix it or return `NEEDS_REWORK`.

### API Verification

Inventing library APIs is a common and expensive failure. Before using any library or framework API you are not certain of:

- Use `context7` (`context7_resolve-library-id`, then `context7_query-docs`) for published libraries.
- Or read the dependency source directly in the worktree (`node_modules`, vendored sources, flake inputs).
- Never infer a function signature, option name, config key, or return shape.
- If an API cannot be verified, report it explicitly in `untested_or_not_run` rather than shipping a guess. The typecheck gate is a backstop, not a substitute.

### Scope Circuit Breaker

Silent scope expansion degrades review quality and hides risk. Stop and return `NEEDS_REWORK` with rationale if the change would:

- exceed roughly twice the briefed `files_or_areas`, or
- introduce a new module, public interface, or third-party dependency not named in the brief.

Re-scoping is the team lead's decision, not yours.

### Other

- Load the `tdd` skill when fixing a bug (see the bug-fix rule in `software-engineer`), or when it will otherwise materially help write or restructure tests. Do not load it by default for routine feature work.
- Reserve at least 15 steps for handoff formatting.
- Treat `<memory_context>` as advisory evidence, except explicit user-confirmed reversals and hard invariants, which are safeguards. If repo evidence contradicts memory, report the conflict instead of silently choosing one.
- Never create or switch branches, commit, push, or otherwise mutate git state. Work on the current branch and leave changes uncommitted in the worktree.

## Role-Specific Extensions

### ux-designer

No extra fields beyond base contract.

### software-engineer

Must also include:

- `mechanical_gates`: `lint=<pass|fail|none>; typecheck=<pass|fail|none>; build=<pass|fail|none>`
- `apis_verified`: libraries/APIs checked against docs or source, or `none`
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
- `mechanical_gates`: `lint=<pass|fail|none>; typecheck=<pass|fail|none>; build=<pass|fail|none>`
- `validation_summary`
- `failure_scope`: implementation | infra | none

### qa-engineer

Must also include:

- `mechanical_gates`: `lint=<pass|fail|none>; typecheck=<pass|fail|none>; build=<pass|fail|none>`
- `tests_added`
- `tests_run_by_implementation`
- `tests_run_by_qa`
- `risk`
- `test_expectation`
- `risk_areas`
- `defect_owner`: software-engineer | ux-designer | none
- `memory_risks_validated`

!!CRITICAL!! `qa-engineer` must not return `CLOSED` unless every discovered mechanical gate is `pass` or genuinely `none`. A gate that is `fail`, unrun, or unreported is `NEEDS_REWORK`.

## Specialist Formats

### codebase-analyst

Compact repo cartography brief (not base contract).

### invariant-analyst

Compact invariant brief (not base contract).

### staff-engineer

Review summary format:

- `review_scope`: `epic` | `task:<id>`
- `has_blockers`: true | false
- `blocker_count`
- `concern_count`
- `suggestion_count`
- `mechanical_invariant_gaps`
- `memory_writeback_candidates`
- `superseded_memory`

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

---

# Memory Write Rules

Use the `mempalace` skill for durable drawer writeback, project wing/room selection, canonical KG relationships, and KG slug rules.
