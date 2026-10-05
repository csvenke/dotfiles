# User instructions

## Recall first (mempalace, via codemode)

Before non-trivial work or odd debugging: `mcp__mempalace__mempalace_search`

- `mcp__mempalace__mempalace_kg_query` (takes `entity`) for prior decisions
  and gotchas on the topic. If memories conflict with what you observe, say so.

## Verify APIs (context7, via codemode)

Before writing code against any library/framework/SDK/CLI API — or asserting
an option or flag exists — `mcp__context7__resolve_library_id` then
`mcp__context7__query_docs`, even when you think you know it. No docs found → state uncertainty, never guess.

## Delegation (pi-subagents)

Standing authorization to delegate when work has parallelizable stages, needs
fresh-context review, heavy recon, or worktree isolation. Small single-seam
tasks: work directly, no ceremony.

Hard lines:

- `reviewer` sign-off (fresh context, criteria verbatim) before accepting
  substantial changes; parent decides done/not-done — receipts are evidence
- Children never spawn subagents; one writer per worktree
- Mutation workers: explicit `usageBudget`, never hard `toolBudget`;
  subagent spend ≤40% of any goal budget
- Lane infrastructure failure → stop and report, never silent fallback
- Children lack MCP: embed needed context7/mempalace excerpts in child prompts

Goal runs: pause and ask when a done criterion proves unachievable, a step
fails two review rounds, or the spend cap is hit. Never weaken done criteria.

## Writeback (mempalace)

- Durable decisions (with rejected alternatives + why) →
  `mcp__mempalace__mempalace_kg_add`, after
  `mcp__mempalace__mempalace_check_duplicate`
- Gotchas (symptom → cause → fix) → `mcp__mempalace__mempalace_kg_add`
- New info contradicts a stored fact → `mcp__mempalace__mempalace_kg_supersede`
  / `mcp__mempalace__mempalace_kg_invalidate` — never parallel contradictions
- Store only what code, git, and docs can't answer. Never secrets.
  KG objects ≤128 chars; long-form → drawers.
