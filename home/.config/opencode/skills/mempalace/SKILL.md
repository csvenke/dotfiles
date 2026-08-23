---
name: mempalace
description: "Shared MemPalace protocol for workflow memory prime, conflict gates, context blocks, writeback, KG facts, and degraded-mode behavior."
---

# MemPalace Workflow Protocol

Use this skill whenever a workflow phase reads from or writes to MemPalace.

## Ticket and Memory Authority

`tk` is the source of truth for active workflow state: current scope, task status, dependencies, acceptance, blockers, and handoffs. MemPalace is the source of historical evidence and durable post-run learning: prior decisions, risk history, invariants, outcomes, policies, and superseded facts.

Do not use MemPalace as live task state. Do not let MemPalace writeback change, reopen, or close tickets. If ticket state and memory disagree during active work, trust the ticket for current scope and surface the memory conflict before dispatch.

## Memory Mode

Track `memory_mode` for the run:

- `active`: MemPalace operations expected
- `degraded`: MemPalace unavailable, continue without blocking

Initialize with a cheap read such as `mempalace_mempalace_status`. If the read fails, set `memory_mode=degraded`. If degraded earlier, retry one cheap read at closure before skipping writeback.

## Memory Prime

Use before planning approval and before dispatch when relevant:

1. `mempalace_mempalace_search` with goal, ticket, file path, and subsystem keywords
2. `mempalace_mempalace_kg_query` for known tickets, epics, subsystems, or file-area slugs
3. `mempalace_mempalace_search` in `wing=opencode`, `room=team-retros` for workflow policy candidates
4. If target files or subsystems are known, run one scoped contradiction search with file path, subsystem, and behavior terms

Treat memory as evidence, not source of truth. Repo evidence wins over stale memory, but conflicts must be surfaced.

## Memory Conflict Gate

If Memory Prime surfaces a prior decision, closed epic, KG fact, or retrospective policy that directly contradicts the requested direction:

1. Stop before issue creation or dispatch.
2. Present the conflict with the prior epic/fact and likely consequence.
3. Ask the user to explicitly confirm the reversal or change the plan.
4. Do not assume the latest request silently supersedes durable memory.

If the user confirms the reversal, preserve the confirmation in ticket `MEMORY:` or `REVERSAL_CONFIRMATION:` notes and downstream `<memory_context>`.

If a conflict is discovered after tickets already exist, add a concise ticket note before dispatch:

```bash
tk add-note <task-id> "MEMORY_CONFLICT: <prior fact/decision and current resolution>"
tk add-note <task-id> "REVERSAL_CONFIRMATION: <user confirmation or none>"
```

## Memory Context Contract

When memory is active, include this block after `<task_brief>` if any relevant memory exists:

```xml
<memory_context>
relevant_prior_epics:
- <epic/task id and one-line relevance, or none>
contradictions_or_reversals:
- <prior decision/fact that conflicts with this task, user confirmation if applicable, or none>
known_invariants:
- <durable invariant from memory, or none>
risk_history:
- <subsystem/file risk history, or none>
applicable_policy_candidates:
- <workflow policy that affects routing/validation, or none>
memory_confidence: high | medium | low
memory_status: active | degraded
</memory_context>
```

If memory is degraded, include `memory_status: degraded` and do not invent prior work.

## Memory Writeback

Capture durable outcomes only:

1. `mempalace_mempalace_check_duplicate` before drawer writes
2. `mempalace_mempalace_add_drawer` for new durable text
3. `mempalace_mempalace_update_drawer` only when replacing or correcting an existing memory
4. `mempalace_mempalace_kg_invalidate` stale facts before adding replacement facts
5. `mempalace_mempalace_kg_add` for durable relationship facts

Drawer content should be verbatim, compact, and durable: decision, invariant, outcome, risk, or reusable workflow lesson. Avoid routine implementation details, transient test output, and near-duplicates.

Use ticket notes as the run-local staging buffer for memory writeback. Extract durable memory from `SPEC:`, `MEMORY:`, `REVERSAL_CONFIRMATION:`, `INVARIANTS:`, `HANDOFF:`, `REWORK:`, `BLOCKED:`, QA/staff summaries, and retros. Do not write every ticket note to memory; write only facts that should help future runs.

MemPalace writeback failures must not block, reopen, or change closed tickets. If writeback fails, set or report `memory_status=degraded`, keep ticket state unchanged, and mention that memory was not fully updated.

## Project Wing and Room

Prefer project/domain wings for project facts and `wing=opencode` for workflow facts.

Project/domain writeback target:

- Wing: codebase-analyst repo name when provided; otherwise workspace basename; otherwise `unknown-project`
- Room: primary `areas_touched` slug when clear; otherwise `general`
- If the target is uncertain, prefer `wing=opencode`, `room=task-outcomes` and include the uncertainty in the drawer content

Before writing, check `mempalace_mempalace_get_taxonomy` (or `mempalace_mempalace_list_rooms` scoped to the target wing) for an existing room that already covers the same area. Reuse the existing name instead of inventing a near-duplicate (e.g. `auth` vs `authentication` vs `authn`). Only create a new room name when no existing room is a reasonable match.

## Cross-Wing Tunnels

When a durable fact learned in a project/domain wing generalizes into a workflow policy in `wing=opencode` (or vice versa), record the link with `mempalace_mempalace_create_tunnel` so future runs can `mempalace_mempalace_follow_tunnels` from the project room straight to the generalized policy. Use this only for genuine cross-wing relevance, not for every writeback — most drawers need no tunnel.

## Canonical KG Relationships

Use these relationships for team workflow facts:

- `<epic_id> contains_task <task_id>`
- `<task_id> touches <subsystem_or_file_slug>`
- `<task_id> completed_with <outcome_slug>`
- `<subsystem_or_file_slug> risk_history <risk_slug>`
- `<policy_slug> learned_from <epic_id>`
- `<policy_slug> policy <policy_text_slug>`
- `<bug_pattern_slug> fixed_by <fix_approach_slug>`
- `<bug_pattern_slug> seen_in <epic_id>`
- `<new_decision_slug> supersedes <old_decision_slug>`

Write KG facts for finalized durable relationships and outcomes. Active status and dependency state stays in `tk`; MemPalace records the finalized story after task closure or epic closure.

## KG Slug Rules

- Use lowercase kebab-case or stable tracker IDs.
- Avoid commas, slashes, quotes, and punctuation-heavy objects.
- Keep object values short; put detailed text in drawers and link KG facts to the drawer source when possible.

## Degraded Mode

Skip memory operations in `degraded` mode. Continue workflow execution and include `memory_status=degraded` in handoffs. At closure, call `mempalace_mempalace_reconnect` once, then retry one cheap MemPalace read; if recovered, perform delayed writeback. If still degraded, state that memory was not updated.

## Risk History Depth

For risk-history checks in Memory Prime and Wave Execution, prefer `mempalace_mempalace_kg_timeline` over `mempalace_mempalace_kg_query` when a subsystem/file-area entity has multiple prior facts. `kg_query` only returns the current snapshot; `kg_timeline` shows whether the risk is a one-off or a recurring pattern, which changes how much the test bar should move.
