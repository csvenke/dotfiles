---
name: team-workflow-planning
description: "Planning phase for team workflow. Memory Prime, clarification guidelines, and plan presentation."
---

# Planning Phase

Until the user approves the plan, behave like the built-in plan agent.

## Planning Memory Prime

Before presenting a plan, search for relevant prior work when `memory_mode=active`:

1. `mempalace_mempalace_search` with goal keywords and likely subsystems
2. `mempalace_mempalace_kg_query` for subsystems to pull risk history
3. `mempalace_mempalace_search` in `wing=opencode`, `room=team-retros` for applicable policies
4. When relevant prior work exists, include a compact `<prior_work>` block:
   - Similar epics and outcomes
   - Known pitfalls for affected subsystems
   - Applicable policy candidates

Skip Memory Prime when: goal is trivial, memory is degraded, or no plausible prior work exists.

## Structured Analysis

After Memory Prime and before drafting the plan, run a structured analysis to surface risks and sharpen scope. Skip for trivial or single-file changes.

1. Extract domain keywords from the user's request (entities, operations, subsystems).
2. Use `explore` agent to scan relevant code areas for those keywords — identify existing concepts and boundaries.
3. Produce a compact `<analysis>` block covering:
   - **Existing concepts**: what the codebase already has that relates to this work
   - **New concepts**: what needs to be introduced
   - **Key rules**: business rules, invariants, or constraints the change must respect
   - **Risks and edge cases**: technical risks, ambiguities, boundary conditions
   - **Scope boundaries**: what is explicitly in vs. out
4. Include the `<analysis>` block in the plan presentation so the user can validate the understanding before approving.

The analysis is lightweight — a few bullet points per section, not a document. Its purpose is to catch misunderstandings and missing edge cases before they become tasks.

## Planning Guidelines

- Use the `explore` subagent for repo research during planning.
- Do NOT use `codebase-analyst` during planning — reserve it for Step 0 (repo bootstrap) in Wave Execution.
- Use `invariant-analyst` selectively for legacy or underspecified work.
- Default path: `software-engineer` → `qa-engineer`. Specialists are optional.
- Ask questions early when requirements are unclear.
- Prefer sequential execution and one primary task unless the user explicitly asks for parallel work.

## Clarification Questions

Ask before plan approval when:

- Request is short or ambiguous
- Success criteria are not concrete
- Multiple reasonable implementations exist
- Work involves multiple subagents or extended execution
- Mistakes would compound across later stages

Prefer a small set of high-leverage questions that resolve scope, constraints, and acceptance quickly.

## Scoping Rules

- Scope tasks to fit one fresh agent context
- Fold trivial fixes into the nearest related task
- Default to sequential execution
- Parallelize only when surfaces are clearly independent

## Plan Presentation

When the plan is ready:

1. Present this exact section as regular text in the main thread:

   ```md
   ## Plan

   Objective: <one sentence>
   Tasks:

   - <task 1>
   - <task 2 if needed>
     Acceptance:
   - <criterion 1>
   - <criterion 2>
     Scope out: <what we explicitly will NOT do>
     Definition of done: <concrete verification — tests, commands, or checks that prove completion>
     Constraints: <constraints or none>
     Assumptions: <assumptions or none>
     Execution: sequential by default
   ```

2. Keep the plan visible and concise.
3. Ask for approval using the Questions tool:
   - Question: `Approve this plan?`
   - Options: `Approve` / `Request changes`

Call the Questions tool only after the plan and execution brief are visible to the user in the main thread.

If user requests changes, revise and re-present. Any clear affirmative counts as approval.

## Exit Condition

Plan approved → Load `team-workflow-issues` skill
