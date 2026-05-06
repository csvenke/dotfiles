---
name: team-workflow-planning
description: "Planning phase for team workflow. Memory Prime, clarification guidelines, and plan presentation."
---

# Planning Phase

Until user approves the plan, behave like the built-in plan agent.

## Memory Prime (`memory_mode=active`)

Before presenting a plan, search for relevant prior work:

1. `mempalace_mempalace_search` with goal keywords and likely subsystems
2. `mempalace_mempalace_kg_query` for subsystems to pull risk history
3. `mempalace_mempalace_search` in `wing=opencode`, `room=team-retros` for applicable policies
4. When relevant prior work exists, include a compact `<prior_work>` block: similar epics, known pitfalls, applicable policy candidates

Skip Memory Prime when: goal is trivial, memory is degraded, or no plausible prior work exists.

## Structured Analysis

After Memory Prime, run a lightweight analysis to surface risks. Skip for trivial or single-file changes.

1. Extract domain keywords from the user's request.
2. Use `explore` agent to scan relevant code areas — identify existing concepts and boundaries.
3. Produce a compact `<analysis>` block: existing concepts, new concepts, key rules, risks and edge cases, scope boundaries (in vs out).
4. Include `<analysis>` in the plan presentation so the user can validate understanding before approving.

## Planning Guidelines

- Use `explore` for repo research during planning. Do NOT use `codebase-analyst` during planning — reserve for Step 0 (repo bootstrap).
- Use `invariant-analyst` selectively for legacy or underspecified work.
- Default path: `software-engineer` → `qa-engineer`. Specialists are optional.
- Ask questions early when requirements are unclear.
- Prefer sequential execution and one primary task unless the user explicitly asks for parallel work.

## Clarification Questions

Ask before plan approval when: request is short/ambiguous, success criteria are not concrete, multiple reasonable implementations exist, work involves multiple subagents or extended execution, mistakes would compound across later stages.

Prefer a small set of high-leverage questions that resolve scope, constraints, and acceptance quickly.

## Scoping Rules

- Scope tasks to fit one fresh agent context
- Fold trivial fixes into the nearest related task
- Default to sequential execution
- Parallelize only when surfaces are clearly independent

## Plan Presentation

**CRITICAL — HARD STOP:** Before asking for approval, you MUST output the complete plan as markdown text in your response. Internal reasoning does NOT count as presentation.

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
     Scope out: <what we explicitly will NOT do>
     Definition of done: <concrete verification — tests, commands, or checks that prove completion>
     Constraints: <constraints or none>
     Assumptions: <assumptions or none>
     Execution: sequential by default
   ```

2. Verify the plan markdown is visible in your response text above.
3. **Only then** ask for approval using the Questions tool: `Approve this plan?` — Options: `Approve` / `Request changes`
4. **Never** proceed to `ISSUE_CREATION` without explicit user approval.

Call the Questions tool only after the plan markdown is visible to the user.

If you have not output the plan markdown above, do so NOW before continuing.

If user requests changes, revise and re-present. Any clear affirmative counts as approval.

## Exit Condition

Plan approved → Load `team-workflow-issues` skill
