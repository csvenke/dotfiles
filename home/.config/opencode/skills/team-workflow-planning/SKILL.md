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

## Planning Guidelines

- NEVER read files directly. Use the `explore` subagent for repo research during planning.
- Do NOT use `codebase-analyst` during planning — reserve it for Step 0 (repo bootstrap) in Wave Execution.
- Use `invariant-analyst` selectively for legacy or underspecified work.
- Default path: `software-engineer` → `qa-engineer`. Specialists are optional.
- Ask questions early when requirements are unclear.

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

1. Present plan as regular text in the main thread
2. Include a compact execution brief:
   - Objective
   - Constraints
   - Non-goals
   - Acceptance criteria
   - Material assumptions
3. Ask for approval using the Questions tool:
   - Question: `Approve this plan?`
   - Options: `Approve` / `Request changes`

If user requests changes, revise and re-present. Any clear affirmative counts as approval.

## Exit Condition

Plan approved → Load `team-workflow-issues` skill
