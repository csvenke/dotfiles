/**
 * pi-chess-puzzles — solve lichess chess puzzles in an overlay while the
 * agent works. The overlay opens automatically during agent runs (after a
 * short delay, so fast replies never flash it) and closes when the agent
 * settles. `/chess` opens it manually; `/chess-auto` toggles auto-open.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { emptyStats } from "./src/component.ts";
import { ChessController } from "./src/controller.ts";
import { PuzzleSource } from "./src/lichess.ts";

export default function (pi: ExtensionAPI) {
  const controller = new ChessController({
    source: new PuzzleSource(),
    stats: emptyStats(),
  });

  pi.on("agent_start", (_event, ctx) => controller.onAgentStart(ctx));
  pi.on("agent_settled", () => controller.onAgentSettled());
  pi.on("session_shutdown", () => controller.onAgentSettled());

  pi.registerCommand("chess", {
    description: "Solve a lichess chess puzzle",
    handler: async (_args, ctx) => {
      await controller.toggle(ctx);
    },
  });

  pi.registerCommand("chess-auto", {
    description: "Toggle auto-opening chess puzzles while the agent works",
    handler: async (_args, ctx) => {
      controller.autoEnabled = !controller.autoEnabled;
      ctx.ui.notify(
        `chess puzzles auto-open ${controller.autoEnabled ? "on" : "off"}`,
        "info",
      );
    },
  });
}
