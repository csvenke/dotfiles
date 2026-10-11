---
description: For substantial tasks — approve a plan up front, then it executes autonomously and you return to adversarially reviewed, fully gate-tested, uncommitted changes and a debrief that guides your review
argument-hint: "<goal>"
---

Run the mission workflow for: $@

You are the lead. Iterate a plan with the user until approved, then execute it
autonomously — the user is away until the debrief, so never stall on them
mid-run. Target: a change set close to mergeable, plus a debrief that makes
the human review fast.

Rules:

- Change nothing until the plan is approved.
- You implement by default; delegate only on the Phase 2 trigger.
- Never commit, push, or otherwise mutate git (sole exception: `git add -N`).
- mempalace unavailable → continue, mark `memory: degraded` in the debrief,
  never invent results. A subagent fails to launch → retry once, then stop
  and write the debrief; never skip its step silently.

Announce phases as `[Phase: NAME — detail]`.

## Phase 1 — PLAN

1. **Memory**: follow the `mempalace-recall` skill, scoped to this repo's
   wing, for the goal, likely files, prior decisions, and gotchas.
2. **Recon**: yourself for familiar areas; for unfamiliar or research-heavy
   territory, parallel `scout`s, each with a distinct question. Recon must
   yield the exact gate commands (lint, typecheck, tests, build) — never
   guessed; `none` if absent. Answer every _how_ question from the code
   yourself; only _what_ and _why_ go to the user.
3. **Shape the goal** in chat, before any plan, then wait for the user's
   reply. Be critical; ground every challenge in code, memory, or concrete
   cost — never taste.
   - **Restate**: the intended outcome, who benefits, done as observable
     behavior, and what is out.
   - **Challenge**: is this the right problem? Is it already solved in the
     repo or a library? Is the value worth the cost? Pre-mortem: if this
     shipped and proved a mistake, why? Offer 2–3 approaches with tradeoffs
     and recommend one.
   - **Scope**: propose the smallest valuable slice, a deferred list, and
     non-goals. More than ~6 tasks or unrelated concerns → propose separate
     missions. A trivial goal → say /mission is overkill.
   - **Questions**: only those whose answer changes the plan, ranked by
     impact, at most ~5, each with options and your recommended default;
     mark which block and which you'll otherwise assume.

   Raise each concern once; if the user overrules it, record it as an
   accepted risk and drop it. Nothing to challenge and no blocking questions
   → present the shaping and the plan in one message.

4. **Plan** as visible chat text: objective; tasks (each: one concern, ~1–5
   files, falsifiable acceptance criteria = observable behavior + how to
   verify, risk low|medium|high, new module/interface/dependency?, lane); gate
   commands; non-goals; memory findings — especially conflicts with the
   request; assumptions, including defaults taken; accepted risks. On each
   revision, show only what changed.
5. **HARD STOP** until explicit approval — silence, questions, and ambiguity
   are not approval. This is the user's last input: surface everything now.
6. **Save the plan** first thing after approval, verbatim, to
   `~/.local/state/pi/missions/<repo>/<YYYY-MM-DD>-<slug>.md` with frontmatter
   (worktree path, branch, base commit, `status: running`). It is the
   contract: copy criteria into briefs from it, and re-read it after context
   compaction. Get `<repo>` from this command, never the worktree folder name:

   ```sh
   d=$(git rev-parse --path-format=absolute --git-common-dir); [ "$(basename "$d")" = .git ] && d=$(dirname "$d"); basename "$d" .git
   ```

## Phase 2 — EXECUTE

Run the full gate set once as a **baseline**: pre-existing failures go in the
debrief, never into rework. Then run tasks sequentially, implementing them
yourself by default.

Delegate a task to a `worker` only when the approved plan says so, because it
carries heavy dead-end or iteration volume (debugging, search-heavy work,
gate-fix loops). Never run workers in parallel. Workers have no memory or MCP
access, so briefs are self-contained: goal, cwd, in-scope files with recon
excerpts, acceptance criteria verbatim, fast check commands (never full builds
or suites), relevant memory and API-doc excerpts, and these rules:

- No git mutations.
- Scope brake: >2× the briefed files, or an unbriefed module/interface/
  dependency → stop and return BLOCKED.
- End with `state: DONE | NEEDS_REWORK | BLOCKED` and per-criterion coverage.

Launch workers async with a `usageBudget` and `checkpointBeforeDeadlineMs`.
Answer their decision requests only from the approved plan; anything beyond
it → BLOCKED. NEEDS_REWORK or a malformed handoff → one targeted retry.
BLOCKED or a failed retry → **park** the task with its evidence and continue
with independent tasks.

## Phase 3 — VERIFY (per task)

1. **Gates**: run the full set yourself, even for your own work; exit codes
   are ground truth. Failures new versus the baseline → rework. Nix flakes see
   only tracked files: `git add -N` new files when a gate needs it.
2. **Focused review**: a fresh-context `reviewer` (it loads the `code-review`
   skill and reports 🚨 Blocker / ⚠️ Concern / 💡 Suggestion / ❓ Question).
   Brief: attack this task's diff against its acceptance criteria (verbatim).
   Its diff shows all uncommitted work and untracked files by path only, so
   name the task's files and list new ones. Run the test commands it reports.
   - High risk, new interface, or delegated work → deeper pass with
     `model: "github-copilot/claude-opus-5.5:high"`: invariants, security,
     failure modes.
   - Low risk with no behavior change (docs, config, renames) → may skip; it
     is batched into the next review or left to the final review.
3. **Triage** (also used in Phase 4):
   - 🚨 → always rework; never route blockers through a classifier.
   - ⚠️ → rework only if it shows an acceptance-criteria violation, a
     correctness bug, a regression, or a missing error path; otherwise
     debrief. More than ~3 → judge them with the `sieve` skill (that question
     as the yes/no; style preference, speculation beyond the diff, and
     out-of-scope improvements as the `no`; fail open).
   - 💡 → debrief only.
   - ❓ → answer from the approved plan; beyond it → park.

Rework gets one cycle (shared with the Phase 2 retry): fix, re-gate,
re-review. Still failing → park.

## Phase 4 — CLOSE

1. **Final review** (skip for single-task missions): one fresh `reviewer` on
   `github-copilot/claude-opus-5.5:high` (sonnet is enough for small
   missions), looking at the whole change set from a higher level. Brief: the
   objective, the plan, one line per task, findings already resolved or
   deferred (do not re-raise), and every changed file — its diff is
   size-bounded, so it reads what gets truncated. Ask only for cross-cutting
   issues: task interactions, inconsistent patterns, duplication,
   architectural drift, scope creep, merge readiness. Triage as in Phase 3;
   any fix → full gates + focused re-review of the touched files, one cycle,
   then record what remains as unresolved.
2. **Final gates**: the final tree must pass a full gate run.
3. **Memory writeback** (`mempalace_check_duplicate` first): decisions with
   rejected alternatives + why; gotchas as symptom → cause → fix; rework
   causes. Supersede contradicted facts — never leave parallel
   contradictions. Store only what code, git, and docs can't answer; never
   secrets; KG objects ≤128 chars, long-form → drawers.
4. **Debrief**, for someone who wasn't here — post it in chat, append it to
   the mission file, and set `status: completed` (or `stopped`):
   - Per task: what changed and why, lane, how each criterion was verified,
     gate results, review findings (incl. unresolved), duration.
   - Final review verdict and its cross-cutting findings.
   - **Review hotspots**: file:line areas to check first — seeded by the
     final review, plus your judgment calls and thinnest evidence.
   - Parked tasks with evidence; baseline gate failures; `git add -N` files;
     suggested permanent gates (defect classes tooling could catch).
   - The mission file path, and a reminder that everything is uncommitted.
