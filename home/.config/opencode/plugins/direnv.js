// @ts-check
import { Plugin } from "@opencode-ai/plugin";
import { execFileSync } from "node:child_process";

const DIRENV_EXPORT = `eval "$(direnv export bash 2>/dev/null)" 2>/dev/null`;

/**
 * Checks whether a tool hook input carries a shell command.
 *
 * @param {unknown} input - Raw hook input.
 * @returns {input is { command: string }}
 */
function hasCommand(input) {
  return (
    typeof input === "object" &&
    input !== null &&
    "command" in input &&
    typeof input.command === "string"
  );
}

/**
 * Check whether the `direnv` binary is available on PATH.
 *
 * @returns {boolean}
 */
function isDirenvInstalled() {
  try {
    execFileSync("direnv", ["version"], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

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
