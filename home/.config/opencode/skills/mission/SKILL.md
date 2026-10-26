---
name: mission
description: Procedure for the /mission workflow — plan approval, autonomous execution, gate-tested and reviewed uncommitted changes, debrief. Load only when /mission invokes it, or to reload it after compaction during a running mission.
---

You lead. Agree a plan with the user, then execute it alone — they are away
until the debrief. Goal: a near-mergeable, uncommitted change set and a
debrief that makes their review fast. Announce phases as
`[Phase: NAME — detail]`.

Rules:

- No changes before approval. No git mutations ever, except `git add -N`.
- After approval, never block on the user: no question tool, no `.env` reads.
- Run gates with an explicit shell `timeout` sized to the command; a timeout
  is inconclusive — rerun longer, never count it as a failure.
- mempalace down → continue, mark `memory: degraded`, never invent. A
  subagent fails to launch → retry once, else stop and debrief.

## 1. Plan

1. Recall memory (`mempalace-recall` skill, this repo's wing): prior
   decisions, gotchas, likely files.
2. Recon the code yourself; use parallel `explore` subagents for unfamiliar
   areas, one question each. Find the exact gate commands (lint, typecheck,
   test, build) or `none` — never guess. Answer _how_ yourself; ask the user
   only _what_ and _why_.
3. Shape the goal and wait for a reply. Ground every point in code, memory,
   or cost, never taste:
   - Restate: outcome, done as observable behavior, out of scope.
   - Challenge: right problem? already solved? worth it? pre-mortem; 2–3
     approaches, recommend one.
   - Scope: smallest valuable slice; >~6 tasks or unrelated concerns →
     split missions; trivial → say /mission is overkill.
   - ≤5 plan-changing questions via the question tool, each with a
     recommended default.

   Raise each concern once; if overruled, record it as an accepted risk.
   Nothing to raise → shaping and plan in one message.

4. Plan, as visible text: objective; tasks (one concern, ~1–5 files,
   falsifiable acceptance criteria with how to verify, risk
   low|medium|high, new module/interface/dependency?, delegate?); gate
   commands; non-goals; memory conflicts; assumptions; accepted risks.
   Revisions show only diffs.
5. HARD STOP: ask `Approve this plan?` (Approve / Request changes) with the
   question tool. Only an explicit Approve counts. This is the last input —
   surface everything now.
6. On approval, save the plan verbatim to
   `~/.local/state/opencode/missions/<repo>/<YYYY-MM-DD>-<slug>.md`
   (frontmatter: worktree, branch, base commit, session ID,
   `status: running`) and rename the session `mission: <slug>`. The file is
   the contract; after compaction, reload this skill and re-read it.
   `<repo>`:

   ```sh
   d=$(git rev-parse --path-format=absolute --git-common-dir); [ "$(basename "$d")" = .git ] && d=$(dirname "$d"); basename "$d" .git
   ```

## 2. Execute

Run all gates once as a baseline; pre-existing failures go to the debrief,
never into rework. Do tasks in order, yourself unless the plan says delegate.

Delegate (heavy debugging, search, or gate-fix loops) to one foreground
`general` subagent at a time. Brief: goal, cwd, files with recon excerpts,
criteria verbatim, fast checks only, memory findings, and: no git
mutations; verify APIs with context7; >2× briefed files or an unbriefed
module/interface/dependency → BLOCKED; unanswered decision → BLOCKED; end
with `state: DONE | NEEDS_REWORK | BLOCKED`, changed files, per-criterion
coverage, checks run. Afterwards confirm HEAD is still the base commit.
NEEDS_REWORK or malformed → one retry in the same session (`sessionID`).
BLOCKED → park with evidence, continue.

## 3. Verify (each task)

1. Run all gates; exit codes are truth; new failures vs baseline → rework.
   Nix flakes see only tracked files: `git add -N` new files if needed.
2. Review with a fresh `reviewer`: attack this task's diff against its
   criteria (verbatim); name its files and new untracked files; run the
   test commands it reports. High risk, new interface, or delegated →
   `model: github-copilot/claude-opus-5.5#high` (intended override), focus
   on invariants, security, failure modes. No behavior change → may defer
   to the next or final review.
3. Triage: 🚨 → rework. ⚠️ → rework only for a criteria violation,
   correctness bug, regression, or missing error path (in doubt: rework);
   else debrief. 💡 → debrief. ❓ → answer from the plan, else park.

One rework cycle per task (shared with the delegation retry): fix, re-gate,
re-review in the same reviewer session. Still failing → park.

## 4. Close

1. Final review (multi-task only): fresh `reviewer` on opus#high (default
   sonnet for small missions) with objective, plan, one line per task,
   settled findings (don't re-raise), all changed files. Cross-cutting
   only: task interactions, inconsistency, duplication, drift, scope creep,
   merge readiness. Triage as above; one fix cycle (gates + focused
   re-review), then the rest is unresolved.
2. Final full gate run must pass.
3. Memory writeback (check duplicates first): decisions with rejected
   alternatives, gotchas as symptom → cause → fix, rework causes. Supersede
   contradictions. Only what code, git, and docs can't answer; no secrets;
   KG objects ≤128 chars, long-form in drawers.
4. Debrief in chat and appended to the mission file; set
   `status: completed` or `stopped`:
   - per task: change and why, how each criterion was verified, gates,
     review findings incl. unresolved;
   - final review verdict and cross-cutting findings;
   - review hotspots (file:line) — final-review picks, your judgment
     calls, thinnest evidence;
   - parked tasks, baseline failures, `git add -N` files, suggested
     permanent gates;
   - mission file path; everything is uncommitted.
