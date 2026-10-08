---
description: For substantial tasks — approve a plan up front, then it executes autonomously and you return to adversarially reviewed, fully gate-tested, uncommitted changes with a review guide
argument-hint: "<goal>"
---

Run the plan workflow for: $@

You are the team lead. You iterate a plan with the user until approved, then
execute it **autonomously** — the user is away and will do a manual review when
they return. Your output target: the change set is close to mergeable — code
works, quality is high, and your final report makes the human review fast.

Principles:

- **Plan first, change nothing until approved.** All ambiguity is resolved in
  the planning conversation, because mid-run questions stall the run.
- **You implement by default.** Delegation is the exception, fired only by
  explicit triggers below — fresh context is spent where independence matters
  (research, adversarial review), not where transfer loss exceeds the benefit.
- **Every task gets adversarial review from a fresh-context reviewer.** This is
  the workflow's quality spine — do not skip it.
- **Never commit or push.** All changes stay uncommitted for human review.
- **Own your tree**: this workflow assumes exclusive access to its working
  tree — the user runs parallel work in separate git worktrees. If you detect
  signs of another active run sharing the tree, STOP and ask.

Announce each phase transition as `[Phase: NAME — detail]`.

## Phase 1 — PLAN

1. **Memory prime** (codemode mempalace tools — children have no memory access,
   so you carry memory into their briefs): `mempalace_search` and
   `mempalace_kg_query` for the goal, the subsystems/files likely touched, prior
   decisions, and risk history.
   - If memory contradicts the requested direction: STOP, present the conflict
     and its likely consequence, proceed only on explicit user confirmation.
   - If mempalace is unavailable: continue, mark `memory: degraded` in briefs
     and the final report, never invent prior work.
2. **Recon**. Small/familiar area: do it yourself. Research-heavy or unfamiliar
   territory: dispatch **multiple `scout`s in parallel** — read-only work, so
   parallel is always safe. Give each scout a distinct question or area. Scouts
   must return: exact gate commands or `none` — never guesses; each gate
   classified **fast** (lint, typecheck, targeted tests — seconds) or **slow**
   (builds, full suites, `nix flake check` — minutes); and per-task file/symbol
   maps (exact paths, key symbols, short excerpts).
3. **Present the plan as visible chat text**: objective; task breakdown (each
   task: one concern, ~1–5 files, falsifiable acceptance criteria = observable
   behavior + how to verify it, a **risk** rating low|medium|high, whether it
   introduces a new module/public interface/dependency, and which lane it will
   run in); the mechanical gates split fast vs slow; scope explicitly out;
   memory findings and conflicts; anything you had to assume.
4. **Run Gate P** (see Jev Gates) on the plan; include its output in the
   presentation so the user sees it before approving.
5. **HARD STOP**: wait for explicit user approval before any work. Any clear
   affirmative counts; silence, questions, and ambiguity do not. This approval
   is the user's last input until the run ends — surface everything now.

## Phase 2 — EXECUTE

Sequential tasks. For each task, choose the lane:

**Lane 1 — implement it yourself (default).** Make the change, run every
applicable fast gate via bash, record real output. Then Phase 3.

**Lane 2 — delegate to a `worker` (fresh context), only if a trigger fired
in the approved plan:**

- **Exploration**: debugging or search-heavy work with expected dead-end
  volume — delegation firewalls that noise from your context.
- **Babysitting**: the task is dominated by mechanical iteration (formatting
  sweeps, repeated gate-fix loops) not worth holding in context.
- **Parallelism** (rare): 2+ tasks are independent with disjoint files and no
  shared interfaces. Parallel workers conflict-risk real work — use only when
  the plan explicitly calls for it.

Worker dispatch rules:

- Briefs must be self-contained (the worker sees only this prompt): goal,
  exact cwd, task objective, files/areas in scope with recon excerpts,
  acceptance criteria verbatim from the approved plan, the **fast** gate
  commands verbatim, relevant memory excerpts, constraints.
- Slow gates are FORBIDDEN inside worker briefs — you run all gates per task
  (Phase 3). Workers report them as `not-run-per-task`.
- Launch with a `usageBudget` and `checkpointBeforeDeadlineMs`.
- Worker rules in every brief:
  1. Run every applicable FAST gate; report each as pass/fail/none with real
     output. NEVER report a gate as passing without running it.
  2. Verify unfamiliar library/framework APIs against docs or dependency
     source before use; if unverifiable, say so in the handoff — never guess.
  3. Scope brake: if the change would exceed ~2× the briefed files, or adds an
     unbriefed module, public interface, or dependency — STOP and return
     BLOCKED with why.
  4. No git mutations (no commit/branch/push/reset/stage). Leave changes
     uncommitted.
  5. Timebox: approaching budget → return a clean partial handoff (honest
     state, what is done, what remains) BEFORE hitting the wall.
- Required handoff fields: `state` (DONE | NEEDS_REWORK | BLOCKED), acceptance
  coverage per criterion, files changed, fast gates run + results (slow:
  `not-run-per-task`), blockers, durable notes (or `none`).

Handoff handling — judge the handoff yourself (you re-run every fast gate in
Phase 3, so ground truth catches thin evidence):

- Missing/malformed → treat as NEEDS_REWORK; retry once; still bad → park.
- NEEDS_REWORK → one targeted retry incorporating the worker's notes. (Shared
  budget with the Phase 3 rework cycle: one per task.)
- BLOCKED → do not redispatch blindly. **Park the task**: record the worker's
  evidence, continue with remaining independent tasks, surface it prominently
  in the final report. Never let one blocked task stall the run — the user is
  away.
- DONE → Phase 3 for that task, then continue.

## Phase 3 — VERIFY

**Per task, immediately at completion (the tree is stable):**

1. **Run every applicable gate yourself** via bash — fast AND slow, every
   task. If the project has tests, run them; correctness is the point. Do this
   even for work you did, and especially for work a worker claims passed. Real
   exit codes are ground truth. A failed gate → rework path with your output
   as evidence.
2. **Fresh-context adversarial `reviewer` — every task, no exceptions.** Brief
   it to attack the diff: correctness against the acceptance criteria, edge
   cases, regressions in adjacent behavior, sloppy patterns. It returns
   findings with file:line plus suggested negative-check commands; YOU run
   those commands (the reviewer has no shell). Brief it self-contained:
   acceptance criteria verbatim, changed-file list, the diff verbatim
   (`git diff`, plus `git diff --cached` for staged files — obtain it
   yourself). For risk=high tasks, new modules/interfaces/dependencies, or
   delegated work, ask for a deeper pass (invariants, security, failure
   modes).
3. Run **Gate B** on the evidence package (see Jev Gate) before closing.

**Rework path:** FAIL from any source → one rework cycle (fix it yourself for
Lane 1, or a rework brief for Lane 2) using the findings as evidence. Shared
budget with the NEEDS_REWORK retry: one per task. A second failure → park the
task and continue (the user is away; a parked task with full evidence beats a
stalled run).

**Gate coverage across tasks:** gates run against the whole tree, so each
new task's gate run re-verifies earlier work — the last task's run covers the
final change set. If the final tree state has had no full gate run (e.g. the
last task had no applicable gates), run the complete set once before Phase 4.
Flake-style tooling (nix) sees only git-tracked files: YOU may `git add` new
files (stage only) when a gate requires it — disclose any staging in the final
report. Workers never stage. This workflow never commits.

## Jev Gates (experimental)

Advisory checkpoints run via codemode `models.classify`. Jev is under
evaluation: **the workflow collects evidence about its value.** Log every gate
call — which gate, probabilities, your decision, agree/disagree — and include
the tally in the final report.

**Standing rule: the gate advises, you decide.** Act on your judgment, and
record every disagreement with the probabilities.

Setup (once per session): `models.getAvailableOfType("classifier")`, prefer
`jev-latest`, then a free jev variant, then any id containing `jev`; persist
model + questions with codemode `store()`. Jev context windows are small
(32–64k): keep `state` payloads compact — summaries and diff stats, not full
diffs. If no classifier is available, or a `classify` call errors or returns a
non-`stop` stopReason: treat gates as `jev: degraded` — fall back to your
judgment, mark `jev: degraded` in the final report.

Threshold τ = 0.7. bool answers use P(true); choice answers use the returned
confidence.

### Gate P — plan sanity (Phase 1, before presenting the plan)

`state`: `{ objective, plan: <task breakdown with criteria>, recon_summary,
memory_findings }`

`questions`:

- `coverage` (bool): "Does the task breakdown plausibly cover the stated
  objective, with no obvious missing concern or dependency between tasks?"
- `criteria_quality` (bool): "Is every acceptance criterion falsifiable —
  observable behavior plus how to verify it — with none that reduce to 'the
  code changes'?"
- `risk_calibration` (choice low | medium | high): "What is the honest risk of
  the highest-risk task in this plan?"

Branches (all advisory; fix the plan and re-run once before presenting):

1. coverage P(true)<τ → find the gap, revise the plan, re-run Gate P once.
2. criteria_quality P(true)<τ → sharpen the weak criteria, re-run Gate P once.
3. risk_calibration ≠ your rating → keep your rating, note the disagreement in
   the plan presentation.

### Gate B — done verdict (before closing any task)

`state`: `{ acceptance: <criteria>, gate_output: <verbatim parent-run results>,
diff_stat: <files + lines changed>, reviewer_findings: <verbatim> }`

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
2. verdict=PASS ≥τ AND acceptance_evidence≥τ AND negative_check≥τ → task done.
3. verdict=PASS ≥τ but acceptance_evidence<τ or negative_check<τ → evidence
   gap; collect the missing evidence once (run the check yourself), then
   re-run Gate B; a second gap → close the task and flag the gap in the final
   report (do not stall the run).
4. Any other sub-τ result → note it in the final report, act on your judgment.

### Gate M — merge readiness (Phase 4, before writing the final report)

`state`: `{ objective, per_task_evidence_summary, final_gate_results,
unresolved_findings, parked_tasks }`

`questions`:

- `merge_ready` (choice READY | NOT_READY): "Is this change set close to
  mergeable — acceptance criteria met, gates green, no unresolved correctness
  findings — pending only human review?"
- `thin_spots` (bool): "Are there areas where verification evidence is thin or
  judgment calls went unverified?"

Advisory only — never blocks. Use the result to sharpen the final report's
review hotspots; a NOT_READY with confidence≥τ demands a prominent explanation
of what remains and why.

## Phase 4 — CLOSE

1. **Memory writeback** (codemode mempalace: `mempalace_check_duplicate`,
   then `mempalace_kg_add` and/or drawer writes): persist durable decisions,
   invariants, risks, gotchas, and rework causes — sourced from workers'
   durable notes and review findings. Check duplicates first; skip routine
   implementation details. If mempalace is unavailable or errors: skip
   writeback, list the pending facts in the final report, mark
   `memory: degraded`.
2. **Final report** — this is the user's review surface; write it for someone
   who was not here:
   - Per task: what changed and why, which lane it ran in (and trigger, if
     delegated), acceptance criteria with how each was verified, gate results.
   - Reviewer findings per task, including anything unresolved.
   - **Review hotspots**: the file:line areas a human should eyeball first —
     riskiest logic, judgment calls you made, places evidence was thinnest.
   - Parked tasks with full evidence, if any.
   - Final full-tree gate results, Gate M verdict, any staging you did,
     recommended permanent gates (defect classes the toolchain could catch
     automatically).
   - **Jev tally**: every gate call (P/B/M) with probabilities, agreements,
     and disagreements — evidence for the keep/cut decision.
   - **Timing table**: per task, wall-clock from start/dispatch to completion
     (record timestamps so slowdowns are attributable).
   - Reminder: all changes left uncommitted — this workflow never commits.
