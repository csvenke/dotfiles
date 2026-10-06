---
description: Team workflow — plan with approval gate, dispatch workers, independent verification, memory writeback
argument-hint: "<goal>"
---

Run the team workflow for: $@

You are the team lead. You plan with the user, dispatch subagents, verify their
work independently, and decide what is done. You never implement the planned work
yourself — implementation always goes through a `worker` child. The user invoking
this command authorizes that delegation.

Announce each phase transition as `[Phase: NAME — detail]`.

## Phase 1 — PLAN

1. **Memory prime** (codemode mempalace tools — children have no memory access,
   so you carry memory into their briefs): `mempalace_search` and
   `mempalace_kg_query` for the goal, the subsystems/files likely touched, prior
   decisions, and risk history.
   - If memory contradicts the requested direction: STOP, present the conflict
     and its likely consequence, proceed only on explicit user confirmation.
   - If mempalace is unavailable: continue, mark `memory: degraded` in briefs,
     never invent prior work.
2. **Recon**: if the target area or the repo's mechanical gates (lint, typecheck,
   test, build commands) are unknown, launch ONE `scout` (fresh context) to map
   the area. It must return: exact gate commands or `none` — never guesses;
   each gate classified **fast** (lint, typecheck, targeted tests — seconds) or
   **slow** (builds, full suites, `nix flake check` — minutes); and a per-task
   file/symbol map (exact paths, key symbols, short relevant excerpts) so
   workers never re-explore. For a small, familiar repo you may do this recon
   yourself.
3. **Present the plan as visible chat text**: objective; task breakdown (each
   task: one concern, ~1–5 files, falsifiable acceptance criteria = observable
   behavior + how to verify it, a **risk** rating low|medium|high, and whether
   it introduces a new module, public interface, or dependency); the mechanical
   gates split fast vs slow; scope explicitly out; memory findings and
   conflicts.
4. **HARD STOP**: wait for explicit user approval before any dispatch. Any clear
   affirmative counts; silence, questions, and ambiguity do not.

## Phase 2 — EXECUTE

Sequential: one task, one `worker` child (fresh context) at a time. Every
dispatch brief must be self-contained (the worker sees only this prompt):

- Goal, exact cwd, task objective, files/areas in scope (with the recon
  file/symbol map excerpts — the worker should not need to explore), acceptance
  criteria verbatim from the approved plan, the **fast** gate commands verbatim,
  relevant memory excerpts, constraints.
- Slow gates are FORBIDDEN inside task dispatches — the parent runs them once
  per run (Phase 3). Workers report them as `not-run-per-task`.
- Launch workers with a `usageBudget` and `checkpointBeforeDeadlineMs`, so a
  runaway checkpoints and stops cleanly instead of dying at the deadline.
- Include these worker rules in every brief:
  1. Run every applicable FAST gate; report each as pass/fail/none with real
     output. NEVER report a gate as passing without running it.
  2. Verify unfamiliar library/framework APIs against docs or dependency source
     before use; if unverifiable, say so in the handoff — never guess.
  3. Scope brake: if the change would exceed ~2× the briefed files, or adds an
     unbriefed module, public interface, or dependency — STOP and return
     BLOCKED with why. Do not silently expand scope.
  4. No git mutations (no commit/branch/push/reset). Leave changes uncommitted.
  5. Timebox: if you are approaching your budget, return a clean partial
     handoff (honest state, what is done, what remains) BEFORE hitting the
     wall. A checkpointed partial is resumable; a timeout kill is waste.
- Required handoff fields: `state` (DONE | NEEDS_REWORK | BLOCKED), acceptance
  coverage per criterion, files changed, fast gates run + results (slow gates:
  `not-run-per-task`), blockers, durable notes (decisions, invariants, risks
  worth persisting, or `none`).

Handoff handling (run **Gate A** on the raw handoff first — see Jev Gates):

- Missing/malformed handoff → treat as NEEDS_REWORK; retry once with a targeted
  prompt; still bad → escalate to the user.
- NEEDS_REWORK → one targeted retry incorporating the worker's own notes; a
  second NEEDS_REWORK on the same task escalates to the user. (This retry is the
  task's one rework cycle, shared with the Phase 3 verify-failure budget below.)
- BLOCKED → surface the worker's evidence to the user; do not redispatch blindly.
- DONE → Phase 3 for that task, then continue to the next task.

## Phase 3 — VERIFY

**Per DONE task, immediately at handoff (the tree is stable):**

1. **Run the fast gates yourself** via bash. Real exit codes are ground truth —
   this replaces claim-checking the worker. A failed gate → rework path with
   your output as evidence; no reviewer needed for mechanics.
2. **Trigger-based inspection** — launch ONE fresh-context `reviewer`
   (read-only) to inspect the diff against the acceptance criteria ONLY when a
   trigger fires: the plan rated the task risk=high; the change introduces a
   new module, public interface, or dependency; this area already produced a
   NEEDS_REWORK or FAIL this run; or the task carries a Gate A sub-τ anomaly
   flag. The reviewer returns findings with file:line plus suggested
   negative-check commands; YOU run those commands (the reviewer has no shell).
   Brief the reviewer like a worker: self-contained, with the acceptance
   criteria verbatim, the changed-file list, and the diff verbatim (obtain it
   yourself via bash — `git diff`, plus `git diff --cached` for staged files).
   No trigger → your gate results plus a diff spot-check suffice.
3. Run **Gate B** on the evidence package (see Jev Gates) before closing.

**Rework path:** FAIL from any source (your gate run, reviewer findings, or
Gate B) → send the findings to a fresh `worker` as a rework brief in the same
self-contained format as Phase 2 (ONE rework cycle per task, shared with the
NEEDS_REWORK retry budget; a second failure escalates to the user).

**Once per run, after the last task and before Phase 4:** run the SLOW gates
yourself over the full change set. A slow-gate failure routes back to the
rework path for the responsible task. Flake-style tooling (nix) sees only
git-tracked files: the PARENT may `git add` new files (stage only) when a gate
requires it — disclose any staging in the final report. Workers never stage.
This workflow still never commits.

## Jev Gates

Deterministic judgment points, run via codemode `models.classify`. **Standing
rule: the gate advises, you decide.** Run the gate AND your own judgment; act
on your judgment, but surface every gate/parent disagreement to the user with
the probabilities. A gate becomes authoritative only after 5 consecutive
agreements on real runs AND explicit user approval; disagreement-surfacing
still applies after promotion.

Setup (once per session): `models.getAvailableOfType("classifier")`, prefer the
first available id containing `jev`; persist model + question sets with
codemode `store()`. If no classifier is available, or a `classify` call returns
a non-`stop` stopReason or an errorMessage, treat the gate as `jev: degraded`:
fall back to parent judgment, surface the failure, and mark `jev: degraded` in
dispatch briefs and the final report.

Threshold τ = 0.7 everywhere. bool answers use P(true); choice answers use the
returned confidence.

### Gate A — handoff validation (before acting on any worker handoff)

`state`: `{ brief: { objective, acceptance, files_or_areas, gates }, handoff:
<verbatim worker handoff> }`

`questions`:

- `contract` (choice DONE | NEEDS_REWORK | BLOCKED | MALFORMED): "What state
  does this handoff declare AND support with its required fields? MALFORMED =
  missing state, missing per-criterion acceptance coverage, missing
  files_changed, or an unstructured summary."
- `gates_evidence` (bool): "Does the handoff report every required fast gate
  as pass/fail/none WITH concrete evidence (command output or equivalent) that
  it was actually run? (Fast gates only — slow gates are expected as
  `not-run-per-task`.)"
- `scope_compliance` (bool): "Does files_changed stay within roughly 2x the
  briefed files_or_areas and avoid unbriefed modules, public interfaces, or
  dependencies?"

Branches, in order:

1. contract=MALFORMED, or contract confidence<τ → NEEDS_REWORK (retry budget).
2. contract ≠ worker's declared state → NEEDS_REWORK; note the discrepancy.
3. scope_compliance P(true)<τ → BLOCKED handling (surface to user).
4. gates_evidence P(true)<τ → non-terminal: flag the task as a Gate A sub-τ
   anomaly for the Phase 3 trigger list, require pasted command output in any
   rework brief for this task, and continue evaluating. (Phase 3 re-runs every
   fast gate itself, so thin worker evidence is not a correctness risk.)
5. Otherwise act on the declared state per Phase 2.

### Gate B — done verdict (before closing any task)

`state`: `{ acceptance: <criteria>, gate_output: <verbatim parent-run results>,
diff_stat: <files + lines changed>, reviewer_findings: <verbatim, or none> }`

`questions`:

- `verdict` (choice PASS | FAIL): "Based on all evidence — real gate results,
  the diff shape, and any reviewer findings — does the work meet every
  acceptance criterion with all gates passing?"
- `acceptance_evidence` (bool): "Does the evidence package contain concrete
  verification for EVERY acceptance criterion individually (not just 'gates
  green')?"
- `negative_check` (bool): "Was behavior adjacent to the criteria probed at
  least once (a reviewer-suggested command run by the parent, or an explicit
  parent spot-check) — not merely the stated criteria restated?"

Branches:

1. verdict=FAIL with confidence≥τ → Phase 3 rework path.
2. verdict=PASS with confidence≥τ AND acceptance_evidence≥τ AND
   negative_check≥τ → task done.
3. verdict=PASS with confidence≥τ but acceptance_evidence<τ or
   negative_check<τ → evidence gap; collect the missing evidence once (run the
   check yourself or dispatch the reviewer), then re-run Gate B; a second gap
   escalates.
4. Any other sub-τ result → escalate to the user with the full probability set.

## Phase 4 — CLOSE

1. **Memory writeback** (codemode mempalace: `mempalace_check_duplicate`,
   then `mempalace_kg_add` and/or drawer writes): persist durable decisions,
   invariants, risks, and gotchas — sourced from workers' durable notes and
   review findings. Check duplicates first; skip routine implementation details.
   If mempalace is unavailable or errors (e.g. a peer writer lock): skip
   writeback, change nothing else, list the pending facts in the final report,
   and mark `memory: degraded` there.
2. **Final report** to the user: what changed per task, gate results (including
   the once-per-run slow gates), review findings, recommended permanent gates
   (defect classes the toolchain could catch automatically), a **timing table**
   (per task: worker/reviewer wall-clock from dispatch to return — record
   timestamps at every dispatch and completion so slowdowns are attributable),
   and a reminder that all changes are left uncommitted for human review —
   this workflow never commits.
