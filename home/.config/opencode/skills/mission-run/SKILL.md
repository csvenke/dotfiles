---
name: mission-run
description: Procedure for the /mission workflow — plan approval, autonomous execution, gate-tested and reviewed uncommitted changes, debrief. Load only when /mission invokes it, or to reload it after compaction during a running mission.
---

You run a mission in two modes, split by one approval:

- **Before approval (interactive):** the user is around. Investigate
  read-only, shape the goal with them, and agree a written plan. Take as
  many exchanges as needed; this is their only chance to steer.
- **After approval (autonomous):** the user is gone until the debrief.
  Execute the plan alone.

Deliverable: a near-mergeable, **uncommitted** change set (gates pass,
reviewed) plus a debrief that makes their review fast.

Flow: 1 Plan → [approval] → 2 Execute → 3 Verify each task → 4 Close
(final review, memory writeback, debrief). Announce each phase as
`[Phase: NAME — detail]`.

Terms: _gates_ = the repo's lint/typecheck/test/build commands found in
recon; _park_ = stop work on a task, record evidence, move on; _debrief_ =
the final report in chat and in the mission file (§4.4).

## Rules

Always:

- No git mutations, except `git add -N`.
- Run gates with an explicit shell `timeout` sized to the command. A
  timeout is inconclusive: rerun longer; never count it as a failure.
- mempalace unavailable → continue, mark `memory: degraded`, never invent
  memories.
- All implementation happens in this session. Subagents are only `explore`
  (recon) and `reviewer`. One fails to launch → retry once, else stop and
  debrief.
- Rework budget: each task and the final review get one cycle, whatever
  triggered it (gates or review) — fix, re-gate, re-review in the same
  reviewer session. Still failing → park.

After approval:

- Never block on the user: no question tool, no `.env` reads. Missing
  decision → answer from the plan, else park.

## 1. Plan

1. Recall memory (`mempalace-recall` skill, this repo's wing): prior
   decisions, gotchas, likely files.
2. Recon the code yourself; use parallel `explore` subagents for unfamiliar
   areas, one question each. Find the exact gate commands or `none` —
   never guess.
3. Shape the goal and wait for a reply. Answer _how_ yourself; ask the user
   only _what_ and _why_. Ground every point in code, memory, or cost,
   never taste:
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
   low|medium|high, new module/interface/dependency?); gate commands;
   non-goals; memory conflicts; assumptions; accepted risks. Revisions
   show only diffs.
5. HARD STOP: ask `Approve this plan?` (Approve / Request changes) with the
   question tool. Only an explicit Approve counts.
6. On approval, write the plan verbatim to
   `~/.local/state/opencode/missions/<YYYY-MM-DD>-<slug>.md` (append `-2`
   if taken) and rename the session `mission: <slug>`. Slug: 2–4
   kebab-case words naming the outcome, prefixed with the repo's short
   name. Frontmatter values unquoted: `repo` (git common dir, below),
   `worktree` (`git rev-parse --show-toplevel`), `branch`, `base_commit`,
   `session_id`, `status: running`.

   ```sh
   git rev-parse --path-format=absolute --git-common-dir
   ```

   The file is the contract. After each verified or parked task, append
   `task N: verified|parked, rework used: yes|no`. After compaction, reload
   this skill, find the file, re-read it, and resume autonomously at the
   first task without a recorded verdict:

   ```sh
   grep -lxF "status: running" ~/.local/state/opencode/missions/*.md | xargs -r grep -lxF "worktree: $(git rev-parse --show-toplevel)" | xargs -r ls -t | head -n1
   ```

## 2. Execute

Run all gates once as a baseline; pre-existing failures go to the debrief,
never into rework. Do the tasks in order, verifying each (§3) before the
next.

## 3. Verify (each task)

1. Run all gates; exit codes are truth; new failures vs baseline → rework.
   Nix flakes see only tracked files: `git add -N` new files if needed.
2. Review with a fresh `reviewer`. Brief: the task's criteria verbatim, its
   files, new untracked files. Run the test commands it reports. High risk
   or new interface → `model: github-copilot/claude-opus-5.5#high`
   (intended override), focus on invariants, security, failure modes. No
   behavior change → may defer to the next or final review.
3. Triage: 🚨 → rework. ⚠️ → rework only for a criteria violation,
   correctness bug, regression, or missing error path (in doubt: rework);
   else debrief. 💡 → debrief. ❓ → answer from the plan, else park.

## 4. Close

1. Final review (multi-task only): fresh `reviewer` on opus#high (default
   sonnet for small missions) with objective, plan, one line per task,
   settled findings (don't re-raise), all changed files. Cross-cutting
   only: task interactions, inconsistency, duplication, drift, scope creep,
   merge readiness. Triage as above; unresolved after rework → debrief.
2. Final full gate run must pass.
3. Memory writeback (per `mempalace-recall`; check duplicates first):
   decisions with rejected alternatives, gotchas as symptom → cause → fix,
   rework causes. Only what code, git, and docs can't answer; no secrets;
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
