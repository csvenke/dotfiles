---
name: plan-implementation-memory
description: "Private MemPalace protocol for the plan implementation coordinator."
slash: false
metadata:
  opencode/autoinvoke: false
---

# Plan Implementation Memory

Private to `plan-implementation-coordinator`. Never load the shared `mempalace`
skill.

## Rules

- `/implement` approves the plan. Memory is historical: repository evidence
  wins; memory cannot block, ask, or change scope/acceptance. Contradictions are
  checks, never implementation constraints.
- Track `memory_mode=active|degraded`; degraded memory never blocks work.
- Resolve `project_wing` only from the repository-root `mempalace.yaml` top-level
  `wing:`; never infer it from a directory name. If absent, remain active with
  `project_wing: none`, search unscoped, and report skipped project writes.
- Use only `room=implementation-lessons`. Never read other rooms, `team-retros`,
  KG, tunnels, diaries, or mined source; never write tickets, retrospectives,
  KG, tunnels, or diaries.
- In Code Mode, call exact catalog paths. If the partial catalog omits one, use
  global `search(...)` before treating it as unavailable; never shadow `search`.

## Read

1. Call `tools.mempalace.mempalace_status`; on failure set `degraded` and stop
   reading.
2. When active, call `tools.mempalace.mempalace_search` once with: `query` = an
   objective/path/subsystem keyword string of at most 250 characters; `context`
   = normalized plan; `room=implementation-lessons`; `limit=3`; and
   `wing=project_wing` only when set. On failure set `degraded`; do not retry
   during implementation.
3. Keep at most three actionable, plan-consistent results as `M1`, `M2`, ...;
   retain drawer IDs only in coordinator state.

| Confidence       | Use                                                         |
| ---------------- | ----------------------------------------------------------- |
| `observed`       | Verification check only                                     |
| `repeated`       | Verification check; implementation constraint when relevant |
| `repo-invariant` | Implementation safeguard and verification check             |

Use at most three memories, two implementation constraints, and three checks.
Never forward raw drawer content or prior solutions unless the plan requires them.

```xml
<memory_capsule>
status: active | degraded
project_wing: <configured wing | none>
implementation_constraints:
- M<n>: <plan-consistent repeated decision or invariant, or none>
verification_checks:
- M<n>: <prior failure condition to try to falsify, or none>
</memory_capsule>
```

Always return the capsule with explicit `none` entries when degraded or nothing
is actionable.

## Verify And Write

The verifier grades every `M<n>` as `confirmed`, `contradicted`, or
`not_exercised`, and every worker claim as `confirmed`, `rejected`, or
`not_exercised`, with evidence. Contradiction marks stale memory, not failure
unless the plan also fails.

After a fresh verifier passes, write only when `project_wing` is set and the fact
would change a future brief/check. Candidates: confirmed claims, the verifier's
learning, and repaired-then-verified defects. Prefer repaired failures; exclude
rejected/unexercised claims, routine success, paths/logs, advice, speculation,
and obvious facts.

Store at most two new lessons, promotions, or corrections per run:

```text
schema: coordinator-memory-v1
kind: invariant | decision | failure-pattern | validation-gap
task_shape: <short reusable task description>
surface: <paths or subsystems>
observation: <fact established by current evidence>
future_action: <specific future constraint or verification check>
applies_when: <conditions that make the lesson relevant>
evidence: verified-first-pass | repaired-then-verified
confidence: observed | repeated | repo-invariant
```

| Evidence                                             | Action                                           |
| ---------------------------------------------------- | ------------------------------------------------ |
| New verified lesson                                  | `observed`                                       |
| New structural, test, or documented contract         | `repo-invariant`                                 |
| Retrieved `observed` confirmed in a later run        | Update to `repeated`                             |
| Retrieved `repeated` confirmed as a current contract | Update to `repo-invariant`                       |
| Retrieved memory contradicted                        | Correct only after verifier confirms replacement |
| `not_exercised`                                      | No write                                         |

New lessons never start `repeated`. The two-write cap includes additions,
promotions, and corrections. Promote/correct with
`tools.mempalace.mempalace_update_drawer` and `drawer_id=<retained ID>`. Add
lessons in one `tools.mempalace.mempalace_checkpoint`; each `items[]` entry sets
`wing=project_wing`, `room=implementation-lessons`, and schema content. Set
`added_by=plan-implementation-coordinator`, omit `diary`, and use its deduplication.

Write failures never change implementation success. If degraded at closure,
call `tools.mempalace.mempalace_reconnect`, retry status once, and write only if
recovered and `project_wing` is set. Do not blindly retry a failed write. Return
mode, project wing, retrieved/applied/written counts (`applied` means used as a
constraint or check), and any incomplete writeback.
