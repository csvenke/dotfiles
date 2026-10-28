---
description: Abort the running /mission — stop work immediately, leave the tree untouched, and mark the mission file canceled, with an optional reason
---

Abort the active mission now. Reason: $ARGUMENTS (empty means none given)

1. Do not finish the current task or start new work. Leave the working tree
   exactly as it is — no reverts, no cleanup, no git mutations, no gate runs.
2. If a reviewer or explore subagent is still running in the background, note
   it in the mission file; do not wait for it or act on its result.
3. Update the mission file (the path saved at plan approval; if lost, find it
   with the command below — keep in sync with `mission-run` §1.6):

   ```sh
   grep -lxF "status: running" ~/.local/state/opencode/missions/*.md | xargs -r grep -lxF "worktree: $(git rev-parse --show-toplevel)" | xargs -r ls -t | head -n1
   ```

   Set frontmatter `status: canceled`, `canceled_at`
   (ISO time), and `cancel_reason`. Append a `## Canceled` section: each task
   as done (verified or not), in progress (partial changes, by file), or not
   started; current `git status --short`; last known gate results.

4. If the reason reveals a durable lesson (wrong approach, bad assumption),
   write it back to memory (`mempalace_check_duplicate` first).
5. Reply with the mission file path and a short summary of the tree's state.

The mission is over: ignore later subagent results and do not resume unless
the user starts a new mission. If no mission is active, say so and change
nothing.
