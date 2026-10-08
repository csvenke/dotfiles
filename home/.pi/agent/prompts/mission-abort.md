---
description: Abort the running /mission — stops its subagents and marks the mission file canceled, with an optional reason
argument-hint: "[reason]"
---

Abort the active mission now. Reason: ${@:-none given}

1. Do not finish the current task or start new work. Leave the working tree
   exactly as it is — no reverts, no cleanup, no git mutations, no gate runs.
2. Stop every subagent this mission launched: list runs with
   `subagent({ action: "status" })`, then `subagent({ action: "stop", id })`
   each one still active.
3. Update the mission file (the path saved in Phase 1; if lost, the newest
   file under `~/.local/state/pi/missions/` with `status: running` and this
   worktree's path). Set frontmatter `status: canceled`, `canceled_at` (ISO
   time), and `cancel_reason`. Append a `## Canceled` section: each task as
   done (verified or not), in progress (partial changes, by file), or not
   started; current `git status --short`; last known gate results.
4. If the reason reveals a durable lesson (wrong approach, bad assumption),
   write it back to memory (`mempalace_check_duplicate` first).
5. Reply with the mission file path and a short summary of the tree's state.

The mission is over: ignore later subagent completion notices and do not
resume unless the user starts a new mission. If no mission is active, say so
and change nothing.
