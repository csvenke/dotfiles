import { Plugin } from "@opencode-ai/plugin";
import { execFileSync } from "node:child_process";

const DIRENV_EXPORT = `eval "$(direnv export bash 2>/dev/null)" 2>/dev/null`;

/**
 * @param {unknown} input
 * @returns {input is { command: string }}
 */
function hasCommand(input) {
  return (
    typeof input === "object" &&
    input !== null &&
    typeof input.command === "string"
  );
}

function isDirenvInstalled() {
  try {
    execFileSync("direnv", ["version"], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

/**
 * Loads the current project's direnv environment into every shell command
 * execution, so agents and subagents see the same env vars/dependencies
 * (nix shells, .envrc exports, tool versions, secrets, etc.) as an
 * interactive shell with direnv hooked in.
 *
 * Skips entirely on hosts without direnv installed (checked once at setup,
 * not per command). Whether a project actually has an allowed `.envrc` is
 * left to direnv itself: it walks upward from the shell's real working
 * directory and silently no-ops when none is found, which the plugin
 * process can't reliably replicate since it doesn't know a given tool
 * call's actual cwd.
 *
 * Matches on tool input shape (a string `command` field) rather than a
 * specific tool name/id, since the built-in shell tool's registered name
 * ("shell") differs from what OpenCode's own docs examples reference
 * ("bash"), and subagents may dispatch through the same tool under
 * different wrapping.
 *
 * Re-evaluated on every command (cheap, direnv caches its own state) so it
 * stays correct even if the agent cd's into a different project/subdir with
 * its own .envrc.
 */
export default Plugin.define({
  id: "local.direnv",
  setup: async (ctx) => {
    if (!isDirenvInstalled()) return;

    await ctx.tool.hook("execute.before", (event) => {
      const { input } = event;
      if (!hasCommand(input)) return;

      event.input = { ...input, command: `${DIRENV_EXPORT}\n${input.command}` };
    });
  },
});
