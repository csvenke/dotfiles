---
name: plan-implementation-coordinator
description: "Implement an approved plan through memory-informed fresh-context subagents."
slash: false
metadata:
  opencode/autoinvoke: false
---

# Plan Implementation Coordinator

Use a supplied non-empty plan path; otherwise use the latest complete
assistant-authored session plan. Invocation approves it; ask only if no unique
usable plan exists or decisions remain unresolved. Except for reading it and
root `mempalace.yaml`, delegate all repository work.

## Execute

1. Normalize the plan's objective, constraints, exclusions, validation, and
   exact acceptance criteria; assign stable `A<n>` IDs through final reporting.
2. Split work into the fewest cohesive, independently verifiable units that fit
   one fresh child context. Run sequentially; never parallelize worktree mutation.
3. Use `explore` only to map paths, symbols, boundaries, and validation needed
   for safe units. Skip it when the plan already provides safe boundaries.
4. Once boundaries are clear, load `plan-implementation-memory` and follow it.
   Never load shared `mempalace`.
5. Dispatch each unit to a foreground `general`; advance dependents only after
   valid `done`. After all units return valid `done`, dispatch a fresh `general`
   verifier.
6. Continue autonomously; allow one recovery and one repair/reverification.
   Escalate only for user-only input/permission, unresolved product scope,
   unsafe/irreversible action, or repeated failure. Ask one question with the
   blocker, recovery, impact, and recommendation.

## Worker Contract

Each self-contained prompt includes:

- the unit's objective and applicable acceptance IDs with criterion text
- constraints, exclusions, areas, unit validation, and required dependency facts
- plan-consistent memory constraints as repository hypotheses
- a worktree baseline and relevant pre-existing changes; preserve unrelated work
- the smallest correct change and targeted checks; defer expensive plan-wide
  checks unless needed earlier
- never create/switch branches, commit, push, reset, clean, restore, revert, or
  otherwise mutate Git/worktree state

Return only:

```text
status: done | blocked
changed: <paths this unit modified>
preexisting: <relevant pre-existing changes or none>
acceptance: <applicable A<n>, result, evidence>
validation: <commands and pass/fail>
scope_delta: <unexpected surface and why | none>
discoveries: <durable findings | none>
notes: <next-unit facts | none>
```

`done` requires every applicable acceptance ID and unit check to pass; otherwise
treat it as `blocked`. Do not request diffs, source, or full logs. Recovery:

- completed work with a malformed handoff: resume once for the contract only
- failure before useful work: retry fresh once
- partial work or `blocked`: unless escalation applies, give one fresh recovery
  `general` the current state and full unit brief; never restart blindly

Use `explore` to remap scope deltas that materially exceed known areas, add an
unplanned interface/dependency, or expose cross-unit coupling. Continue only if
the expanded surface remains in-plan; otherwise ask. Memory never blocks.

## Verification

Give a fresh `general` the normalized plan with every `A<n>`, changed paths as
non-exhaustive hints, relevant pre-existing overlaps, all retained `M<n>`, and
material discovery/scope-delta claims. Omit rationale and routine notes.

It must independently falsify acceptance, run required plan-wide and targeted
checks, and inspect beyond reported paths when effects indicate. Snapshot
worktree status before validation and compare it afterward. Never edit or clean
up; if validation changes files, return `blocked` with before/after evidence and
escalate without repair.

Return only:

```text
verdict: pass | rework | blocked
changed: <independently observed plan-related paths>
acceptance: <every A<n>, result, evidence>
validation: <commands and pass/fail>
findings: <actionable findings | none>
memory: <each M<n>: confirmed | contradicted | not_exercised, with evidence>
writeback: <each claim: confirmed | rejected | not_exercised, evidence; plus at most one learning>
residual_risks: <untested or uncertain behavior | none>
```

`pass` is valid only when every `A<n>` and required check passes, findings are
`none`, and verification left the worktree unchanged. Otherwise treat the
verdict as `rework` or `blocked` according to its evidence.

On `rework`, give a fresh repair `general` the normalized plan, failed IDs and
findings, memory safeguards, cumulative changed paths, and current-worktree
instructions. Apply the Worker Contract, then use a new verifier. Never resume
an implementer; escalate if the problem remains or needs a product decision.

## Close

After valid `pass`, give `plan-implementation-memory` only confirmed writeback,
memory feedback, and repaired-then-verified defects; never write earlier. Report
implementation, verifier-observed paths, validation, residual risks, and one
memory summary line.
