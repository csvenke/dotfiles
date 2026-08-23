---
name: team-workflow-dispatch
description: "Worker dispatch contract, handoff contracts, and escalation rules for the team workflow. Load before dispatching any worker."
---

# Dispatch and Escalation

Load before dispatching workers or interpreting their handoffs.

## Dispatch Contract

Every worker prompt must include `<global_rules>` followed by a self-contained
`<task_brief>` and, when the worker's role needs live ticket state, a `<ticket_context>`
block. Workers never call `ticket_tracker` or `tk` — the tool is hidden from and
rejected for every non-`team` agent. The dispatch prompt must be sufficient to start
safely without any tracker read of its own.

Load the `mempalace` skill before adding or interpreting `<memory_context>`.

```xml
<ticket_context>
id: <ticket id>
title: <ticket title>
status: <open|in_progress|closed>
parent: <epic id or none>
description: <SPEC note text>
acceptance: <ACCEPTANCE note text>
metadata: <METADATA note text, or none>
</ticket_context>
```

`team` builds `<ticket_context>` from its own `ticket_tracker show` result immediately
before dispatch. !!CRITICAL!! If `<ticket_context>` is missing, or its `id`/`title`
does not match the `<task_brief>`, or `status` is already `closed`, the worker must
return `BLOCKED` instead of guessing or re-deriving ticket state itself.

```xml
<global_rules>
- Treat issue metadata as a starting point, not a ceiling. If observed surface exceeds plan, raise risk or test_expectation and explain why.
- Treat repo bootstrap commands as source of truth. Report missing commands as not run.
- Run every mechanical gate discovered in repo bootstrap (lint, typecheck, build) that applies to your role. Report each as pass, fail, or none. Never report a gate as passing without running it.
- Verify unfamiliar library or framework APIs before using them. Use context7 for documented libraries, or read the dependency source. Never infer a signature, option name, or return shape. If an API cannot be verified, say so in your handoff instead of guessing.
- Stop and return NEEDS_REWORK if the change would exceed roughly twice the briefed files_or_areas, or introduce a new module, public interface, or dependency that is not in the brief. Do not silently expand scope.
- Run long test suites as a single blocking foreground call with an explicit timeout. Never background them and return before they finish.
- Load the tdd skill when fixing a bug, or when it otherwise materially helps. Do not load by default for other work.
- Treat <memory_context> as advisory evidence, except explicit user-confirmed reversals and hard invariants, which are safeguards. If repo evidence contradicts memory, report the conflict instead of silently choosing one.
- Reserve at least 15 steps for handoff formatting.
- Never create or switch branches, commit, push, or otherwise mutate git state. Work on the current branch and leave changes uncommitted in the worktree. `git checkout`, `switch`, `reset`, `clean`, `restore`, and `git -C` are denied — run git from the current working directory and use `cd` if you need a different one.
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

- `norms` = "how to write the code" — engineering standards the worker should follow
  (patterns, conventions, style). Omit or use `none` when the codebase has no strong
  conventions.
- `safeguards` = "what must never break" — hard constraints, invariants, security
  rules. Omit or use `none` when no known invariants apply.

When memory is active, include a `<memory_context>` block after `<task_brief>` if any
relevant memory exists, using the schema from the `mempalace` skill. If memory is
degraded, include `memory_status: degraded` and do not invent prior work.

!!CRITICAL!! If the brief is missing ticket id, objective, or acceptance criteria,
the worker must report `BLOCKED` instead of guessing.

## Base Handoff Contract

Every workflow role returns at least:

1. `state`: `READY_FOR_IMPLEMENTATION` | `READY_FOR_QA` | `READY_TO_CLOSE` | `NEEDS_REWORK` | `BLOCKED`
2. `acceptance_coverage`: which criteria met/not met
3. `files_changed`: comma-separated paths or `none`
4. `qa_or_handoff_notes`: what the next role should validate
5. `blockers`: explicit `none` or blocker description
6. `ticket_notes`: durable high-signal notes for `team` to persist with
   `ticket_tracker add_note` (architectural decisions, invariants, UX decisions,
   pivots, blockers), or `none`

Role-specific extension fields are defined in each agent's own `## Output` section.

!!CRITICAL!! No worker calls `ticket_tracker` or `tk`. Every note a worker wants
recorded travels in `ticket_notes`; `team` persists it sequentially before advancing
the wave. `team` never invents or edits worker-authored note content, only records it.

!!CRITICAL!! If a response is missing `state`, is missing the fields its own agent
prompt requires, or hits the step limit and returns an unstructured summary, treat it
as `NEEDS_REWORK` and escalate.

!!CRITICAL!! `qa-engineer` never closes and must not return `CLOSED`. It returns
`READY_TO_CLOSE` only when every discovered mechanical gate is `pass` or genuinely
`none`; `team` performs the actual `ticket_tracker close` after independently
confirming the gates. A gate that is `fail`, unrun, or unreported makes the correct
verdict `NEEDS_REWORK`, not `READY_TO_CLOSE`.

## Specialist Formats

`codebase-analyst`, `invariant-analyst`, and `staff-engineer` return compact briefs,
not the base contract, but all three share one uniform context-validation field
instead of ad hoc wording: `context_status: ok | blocked`.

- `context_status: blocked` — used whenever the dispatch is task/epic-scoped (i.e.
  not `codebase-analyst` repo bootstrap) and `<ticket_context>` is missing, or its
  `id`/`title` does not match the `<task_brief>` (or, for `staff-engineer`
  `review_scope=epic`, the epic being reviewed). When `context_status=blocked`, the
  specialist does not proceed with ticket-derived analysis — it reports only the
  gap plus any file-derived findings that do not depend on ticket content, and
  `team` must treat this the same as a worker's `BLOCKED` state: do not advance the
  wave on that specialist's output until the context is fixed.
- `context_status: ok` — the specialist validated `<ticket_context>` (or the
  dispatch is repo bootstrap and no ticket context was required) and proceeded
  normally.

Repo bootstrap (`codebase-analyst`) is the sole ticket-independent dispatch — it
never requires `<ticket_context>` and always reports `context_status: ok`. Every
other task-scoped or epic-scoped specialist dispatch, including `codebase-analyst`
used for task mapping or rework triage, requires a complete, matching
`<ticket_context>` and must report `context_status: blocked` instead of guessing
when it is missing or inconsistent.

All three specialists also include a `ticket_notes` field (durable findings for
`team` to persist, or `none`).

`staff-engineer` returns a review summary:

- `review_scope`: `epic` | `task:<id>`
- `context_status`: `ok` | `blocked`
- `has_blockers`: true | false
- `blocker_count`
- `concern_count`
- `suggestion_count`
- `mechanical_invariant_gaps`
- `memory_writeback_candidates`
- `superseded_memory`
- `ticket_notes`

---

# Escalation Rules

## When to Escalate

- Subagent hits the step limit without a valid handoff
- Subagent returns without required fields
- Task permanently blocked or requires user intervention
- Issue remains `NEEDS_REWORK` after one full rework cycle
- Requirements unclear or conflicting
- Worker returns `BLOCKED` because `<ticket_context>` was missing or did not match
  the `<task_brief>`
- A specialist (`codebase-analyst`, `invariant-analyst`, `staff-engineer`) returns
  `context_status: blocked`

## How to Escalate

1. `team` logs the blocker with `ticket_tracker` operation `add_note`:
   `BLOCKED: <reason>`, using the worker's own `ticket_notes` verbatim when present
2. !!CRITICAL!! Ask the user only when autonomous continuation is blocked by a real
   decision, missing requirement, or unsafe state
3. Leave ambiguous issues open

## Special Cases

| Situation                      | Action                                                     |
| ------------------------------ | ---------------------------------------------------------- |
| `EADDRINUSE` / port collision  | Requeue once in the sequential server-test lane            |
| Rework scope unclear           | Use `explore` to understand the fix surface, then ask user |
| Ticket/prompt mismatch         | Re-check the ticket ID once, then escalate                 |
| Previous rework comment exists | Escalate instead of redispatching                          |
| Subagent returns empty/crashes | Retry once with a targeted prompt, then escalate           |

## Logging Rules

`team` logs to the tracker only for: core invariants discovered, core UX/interaction
decisions, architectural pivots, fundamental design changes, and permanent blockers —
sourced from each worker's `ticket_notes`.

Do NOT log routine state changes, implementation details, test runs, or minor defects.
