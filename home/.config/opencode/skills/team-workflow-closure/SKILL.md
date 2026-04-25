---
name: team-workflow-closure
description: "Epic closure phase for team workflow. Memory writeback, pattern mining, and epic close. Staff review happens in wave execution."
---

# Epic Closure Phase

Enter this phase after staff review passes (`has_blockers=false`). Staff review is Step 8 of Wave Execution.

## Step 1: Memory Writeback (`memory_mode=active`)

Capture epic-level durable outcomes:

1. `mempalace_mempalace_check_duplicate` before drawer writes
2. `mempalace_mempalace_add_drawer` for new durable text
3. `mempalace_mempalace_kg_add` for durable relationship facts

Skip if `memory_mode=degraded`.

## Step 2: Workflow Retrospective

When the run exposed reusable workflow learning, store in `wing=opencode`, `room=team-retros`:

- `epic_id`, `epic_title`, `run_outcome`
- `clarification_effectiveness`
- `rework_pattern`
- `routing_misses`
- `specialist_lane_learnings`
- `memory_lane_issues`
- `what_helped`
- `policy_candidate`

Skip for routine successful runs with no reusable lesson.

## Step 3: Pattern Mining (`memory_mode=active`)

Extract reusable patterns from retrospective into KG triples:

### If `policy_candidate` is non-empty:

1. Identify pattern type: `test_triage`, `contract_change`, `infra_failure`, `rework_loop`, `routing_miss`
2. Sanitize policy text (remove `!`, `/`, special chars)
3. Record origin:
   ```
   kg_add(subject=<pattern_type>, predicate="learned_from", object=<epic_id>)
   ```
4. Record policy:
   ```
   kg_add(subject=<pattern_type>, predicate="policy", object=<sanitized_policy>)
   ```

### If bug pattern with fix approach:

```
kg_add(subject=<bug_pattern>, predicate="fixed_by", object=<fix_approach>)
kg_add(subject=<bug_pattern>, predicate="seen_in", object=<epic_id>)
```

### If subsystem has recurring issues:

```
kg_add(subject=<subsystem>, predicate="risk_history", object=<compact_risk_note>)
```

Pattern Mining makes learnings queryable by Planning Memory Prime in future runs.

Skip if `memory_mode=degraded`.

## Step 4: Close Epic

```bash
tk ls --status=closed -T team-task  # confirm all workflow tasks closed
tk close <epic-id>
```

Update todos: mark "Epic Closure" as completed.

## Step 5: Final Report

Report to user:

- Epic closed
- Summary of changes
- Staff review findings (from wave execution)
- Hand off for human review

## Human Review and Release

This workflow ends with human review:

1. Human performs final code review
2. Human decides if more fixes needed
3. Human commits and pushes
