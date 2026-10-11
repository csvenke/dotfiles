# User instructions

## Answer before changing

Questions get answers (investigate freely) and, if useful, a plan — not file
changes. Change files only when asked or after I approve a plan; unsure → ask.

## Codemode and MCP tools

MCP tools are flat: `tools.mcp__<server>__<tool>`. Their signatures are
hidden — `await describeTool(name)` before the first call. `searchTools` and
`describeTool` are async.

## Verify APIs (context7, via codemode)

Before writing code against any library/framework/SDK/CLI API — or asserting
an option or flag exists — `mcp__context7__resolve_library_id` then
`mcp__context7__query_docs`, even when you think you know it. No docs found → state uncertainty, never guess.
