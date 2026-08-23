---
name: team-workflow-closure
description: "Epic closure phase for the team workflow. Memory writeback, retrospective, pattern mining, and closing the epic."
---

# Phase 4: Epic Closure

Enter after staff review passes (`has_blockers=false`). Staff review happens in
`team-workflow-execution`.

## Memory Writeback

Capture epic-level durable outcomes. Load the `mempalace` skill, then:

1. Use Memory Writeback rules for workflow-level durable text in `wing=opencode`
2. Use project/domain target rules for project durable text, checking existing
   taxonomy/rooms first per the `mempalace` skill
3. Use canonical KG relationships and slug rules for durable relationship facts
4. Invalidate stale facts before adding replacements when the epic supersedes prior memory
5. Write any `mechanical_invariant_gaps` reported by `staff-engineer` as durable
   project memory. These identify where a lint rule, type constraint, or structural
   test would prevent a whole defect class — among the most reusable findings a run
   produces.
6. If a durable fact generalizes from a project/domain wing into an `opencode`
   workflow policy (or the reverse), link them with
   `mempalace_mempalace_create_tunnel` per the `mempalace` Cross-Wing Tunnels guidance.
7. Run a dry-run `mempalace_mempalace_sync` for the project wing (no `apply`). If it
   reports meaningful drift, mention it in the Final Report as a suggestion; never
   pass `apply=true` without explicit user confirmation.

If `memory_mode=degraded`, use the `mempalace` degraded-mode retry behavior
(including `mempalace_mempalace_reconnect`).

## Workflow Retrospective

When the run exposed reusable workflow learning, store it in `wing=opencode`,
`room=team-retros`: `epic_id`, `epic_title`, `run_outcome`,
`clarification_effectiveness`, `rework_pattern`, `routing_misses`,
`specialist_lane_learnings`, `memory_lane_issues`, `what_helped`, `policy_candidate`.

Skip for routine successful runs with no reusable lesson.

## Pattern Mining (`memory_mode=active`)

Extract reusable patterns from the retrospective into KG triples. Apply the canonical
relationships and KG slug rules from the `mempalace` skill to every fact.

**If `policy_candidate` is non-empty:**

1. Identify pattern type: `test_triage`, `contract_change`, `infra_failure`,
   `rework_loop`, `routing_miss`
2. Sanitize policy text (remove `!`, `/`, special chars)
3. Record origin: `kg_add(subject=<pattern_type_slug>, predicate="learned_from", object=<epic_id>)`
4. Record policy: `kg_add(subject=<pattern_type_slug>, predicate="policy", object=<sanitized_policy_slug>)`

**If a bug pattern with fix approach:**
`kg_add(subject=<bug_pattern_slug>, predicate="fixed_by", object=<fix_approach_slug>)`
`kg_add(subject=<bug_pattern_slug>, predicate="seen_in", object=<epic_id>)`

**If a subsystem has recurring issues:**
`kg_add(subject=<subsystem_slug>, predicate="risk_history", object=<compact_risk_slug>)`

Pattern Mining makes learnings queryable by Planning Memory Prime in future runs.
Skip if `memory_mode=degraded`.

## Team Lead Diary (`memory_mode=active`, optional)

When the run produced a reusable lesson, write a compact
`mempalace_mempalace_diary_write` entry as `agent_name="team-lead"` in AAAK format
summarizing the epic outcome and lesson. This is a cheaper continuity layer than
`team-retros` drawers — Planning may `mempalace_mempalace_diary_read` it for fast
self-context before running a full Memory Prime search. Skip for routine runs.

## Close Epic

```bash
tk ls --status=closed -T team-task  # confirm all workflow tasks closed
tk close <epic-id>
```

## Final Report

Report to the user: epic closed, summary of changes, staff review findings, hand off
for human review.

Include any `mechanical_invariant_gaps` as an explicit "recommended permanent gates"
list. These are the highest-leverage follow-ups available — each one converts a class
of defects into something the toolchain catches automatically instead of relying on
review.

## Human Review and Release

This workflow ends with human review:

1. Human performs final code review
2. Human decides if more fixes are needed
3. Human commits and pushes
