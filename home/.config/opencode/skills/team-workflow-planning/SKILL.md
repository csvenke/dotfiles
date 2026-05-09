---
name: team-workflow-planning
description: "Planning phase for team workflow. Memory Prime, clarification guidelines, and plan presentation."
---

# Planning Phase

Until user approves the plan, behave like the built-in plan agent.

Before Memory Prime, load the `mempalace` skill and initialize `memory_mode` if unset.

## Memory Prime (`memory_mode=active`)

Before presenting a plan, use the `mempalace` Memory Prime to search for relevant prior work. When relevant prior work exists, include a compact `<prior_work>` block: similar epics, known pitfalls, applicable policy candidates.

Memory Prime is mandatory before plan approval when the work touches files/subsystems with prior epics, reverses behavior, adds back removed behavior, changes validation policy, or depends on previous design choices.

Skip Memory Prime only when: goal is trivial, memory is degraded, or there is no plausible prior work and no known target subsystem.

## Memory Conflict Gate

Apply the `mempalace` Memory Conflict Gate before issue creation. If the user confirms a reversal, include that confirmation in ticket memory notes and downstream `<memory_context>`.

## Structured Analysis

After Memory Prime, run a lightweight analysis to surface risks. Skip for trivial or single-file changes.

1. Extract domain keywords from the user's request.
2. Use `explore` agent to scan relevant code areas — identify existing concepts and boundaries.
3. Produce a compact `<analysis>` block: existing concepts, new concepts, key rules, risks and edge cases, scope boundaries (in vs out).
4. Include `<analysis>` in the plan presentation so the user can validate understanding before approving.

## Policy Application

When Memory Prime finds workflow retrospectives or policy candidates, include a compact policy section in the plan:

- `policies_applied`: policies that changed the plan, routing, validation, or questions
- `policies_rejected`: relevant policies intentionally not used, with why

Omit this section only when Memory Prime finds no applicable policy candidates.

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
   Prior work: <compact prior work summary or none>
   Memory conflicts: <conflicts requiring user confirmation or none>
   Policies applied: <policy candidates applied or none>
   Policies rejected: <relevant policy candidates intentionally skipped or none>
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
