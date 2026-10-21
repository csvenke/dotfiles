/**
 * pi-tidy — quieter tool display.
 *
 * Uses only pi.registerToolRenderer(): no tool is re-registered or overridden,
 * execution is untouched, and expanded rows (ctrl+o) delegate to pi's native
 * renderers via next().
 *
 * One strategy per tool, each in its own file under src/tools/, sharing the
 * utilities in src/shared.ts and (for read/bash/edit/write) the skeleton in
 * src/compact.ts.
 */

import { Effect } from "effect";
import type {
  ExtensionAPI,
  ToolRendererResolver,
} from "@earendil-works/pi-coding-agent";
import type { TidyStrategy } from "./src/shared.ts";
import { bashTidy } from "./src/tools/bash.ts";
import { codemodeTidy } from "./src/tools/codemode.ts";
import { editTidy } from "./src/tools/edit.ts";
import { readTidy } from "./src/tools/read.ts";
import { writeTidy } from "./src/tools/write.ts";

const strategies: Record<string, TidyStrategy> = {
  read: readTidy,
  bash: bashTidy,
  edit: editTidy,
  write: writeTidy,
  codemode: codemodeTidy,
};

const resolveRenderer: ToolRendererResolver = (toolName, next) =>
  strategies[toolName]?.(next) ?? next();

const registerRenderers = (pi: ExtensionAPI): Effect.Effect<void> =>
  Effect.sync(() => pi.registerToolRenderer(resolveRenderer));

export default function (pi: ExtensionAPI): void {
  Effect.runSync(registerRenderers(pi));
}
