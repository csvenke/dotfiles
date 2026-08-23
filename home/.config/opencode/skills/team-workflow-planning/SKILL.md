---
name: team-workflow-planning
description: "Planning phase for the team workflow. Memory Prime, clarification questions, design gate, and plan presentation."
---

# Phase 1: Planning

Until the user approves the plan, behave like the built-in plan agent.

Before Memory Prime, load the `mempalace` skill and initialize `memory_mode` if unset.

## Memory Prime (`memory_mode=active`)

Two searches, both before presenting a plan. They answer different questions and the
second is the one that gets dropped — do not merge them into one search.

### 1. Prior work search

Use the `mempalace` Memory Prime to search for prior work on the target files and
subsystems. When relevant prior work exists, include a compact `<prior_work>` block:
similar epics, known pitfalls, prior decisions.

Mandatory when the work touches files/subsystems with prior epics, reverses behavior,
adds back removed behavior, changes validation policy, or depends on previous design
choices.

Skip only when **all** of these hold: the goal is trivial, there is no known target
subsystem, and no plausible prior work exists. Degraded memory also skips it.

!!CRITICAL!! A goal _looking_ simple is not sufficient reason to skip. The mandatory
cases above override "trivial" — if the work touches a file that has prior epics, the
search runs regardless of how small the change seems.

### 2. Workflow policy search

!!CRITICAL!! Always run `mempalace_mempalace_search` scoped to `wing=opencode`,
`room=team-retros`, regardless of how trivial the goal looks. This is the workflow's
own accumulated evidence about routing, validation depth, rework loops, and
specialist selection. It is cheap, it is unrelated to how novel the feature is, and
it is the step most often skipped.

Skip only when `memory_mode=degraded`.

## Memory Conflict Gate

Apply the `mempalace` Memory Conflict Gate before issue creation. If the user
confirms a reversal, include that confirmation in ticket memory notes and downstream
`<memory_context>`.

## Structured Analysis

After Memory Prime, run a lightweight analysis to surface risks. Skip for trivial or
single-file changes.

1. Extract domain keywords from the user's request.
2. Use `explore` to scan relevant code areas — identify existing concepts and boundaries.
3. Produce a compact `<analysis>` block: existing concepts, new concepts, key rules,
   risks and edge cases, scope boundaries (in vs out).
4. Include `<analysis>` in the plan presentation so the user can validate
   understanding before approving.

## Policy Application

The plan must always report both fields — they are not optional:

- `policies_applied`: policies that changed the plan, routing, validation, or questions
- `policies_rejected`: relevant policies intentionally not used, with why

If the `team-retros` search returned nothing applicable, write
`Policies applied: none — searched team-retros for <terms>` so it is visible that the
search actually ran. A bare `none` is not acceptable, because it is
indistinguishable from having skipped the search.

## Planning Guidelines

- Use `explore` for repo research during planning. Do NOT use `codebase-analyst`
  during planning — reserve it for repo bootstrap.
- Repository research must be delegated. The team lead must not substitute shell
  commands when its direct `read`, `glob`, and `grep` tools are denied.
- Use `invariant-analyst` selectively for legacy or underspecified work.
- Default path: `software-engineer` → `qa-engineer`. Specialists are optional.
- Ask questions early when requirements are unclear.
- Prefer sequential execution and one primary task unless the user explicitly asks
  for parallel work.

## Clarification Questions

Ask before plan approval when: the request is short or ambiguous, success criteria
are not concrete, multiple reasonable implementations exist, work involves multiple
subagents or extended execution, or mistakes would compound across later stages.

Prefer a small set of high-leverage questions that resolve scope, constraints, and
acceptance quickly.

## Scoping Rules

- Scope tasks to fit one fresh agent context
- Fold trivial fixes into the nearest related task
- Default to sequential execution
- Parallelize only when surfaces are clearly independent

## Design Gate for High-Risk Work

The cheapest review is the one that happens before code exists. When the plan
contains any task you would label `risk=high` — or that changes a public interface,
data shape, security boundary, or persistence format — the plan **must** include an
`Approach:` section covering:

- the design decision being made, in two or three sentences
- at least one alternative considered and why it was rejected
- the blast radius if the approach turns out to be wrong

This puts design intent in front of the user before issue creation, when changing
course is free. Omit the section entirely for low and medium risk work — do not pad
plans with it.

## Plan Presentation

**CRITICAL — HARD STOP:** Before asking for approval, you MUST output the complete
plan as markdown text in your response. Internal reasoning does NOT count as
presentation.

1. Output this exact section as regular text in the main thread:

   ```md
   ## Plan

   Objective: <one sentence>

   Tasks:

   - <task 1>
   - <task 2 if needed>

   Acceptance:

   - <criterion 1>
   - <criterion 2>

   Approach: <design decision, rejected alternative, blast radius — required when any task is high risk, omit otherwise>
   Scope out: <what we explicitly will NOT do>
   Definition of done: <concrete verification — tests, commands, or checks that prove completion>
   Constraints: <constraints or none>
   Assumptions: <assumptions or none>
   Prior work: <compact prior work summary or none>
   Memory conflicts: <conflicts requiring user confirmation or none>
   Policies applied: <policy candidates applied or none>
   Policies rejected: <relevant policy candidates intentionally skipped or none>
   Execution: sequential by default
   ```

2. Verify the plan markdown is visible in your response text above.
3. **Only then** ask for approval using the Questions tool: `Approve this plan?` —
   Options: `Approve` / `Request changes`
4. **Never** proceed to `ISSUE_CREATION` without explicit user approval.

Call the Questions tool only after the plan markdown is visible to the user.

If you have not output the plan markdown above, do so NOW before continuing.

If the user requests changes, revise and re-present. Any clear affirmative counts as
approval.

For plans that reverse prior decisions, reintroduce previously removed features, or
depend on prior workflow policy or history, run a memory contradiction check and
surface conflicts to the user before approval.

## Exit Condition

Plan explicitly approved by the user → load `team-workflow-issues`.
