/**
 * Lifecycle wiring: opens the puzzle overlay when the agent starts working
 * (after a short delay so fast runs never flash it) and closes it when the
 * agent settles. The overlay is owned here so event handlers stay thin and
 * everything is testable with a fake UI.
 */

import {
  PuzzleBoardComponent,
  type BoardTheme,
  type SessionStats,
} from "./component.ts";
import type { PuzzleGame } from "./game.ts";
import { createImageBackend } from "./imagebackend.ts";
import type { PuzzleSource } from "./lichess.ts";

export interface TuiLike {
  requestRender(): void;
}

export interface OverlayUi {
  custom<T>(
    factory: (
      tui: TuiLike,
      theme: BoardTheme,
      keybindings: unknown,
      done: (result: T) => void,
    ) => PuzzleBoardComponent,
    options?: { overlay?: boolean; overlayOptions?: Record<string, unknown> },
  ): Promise<T>;
  notify(message: string, type?: string): void;
  /** Present on the real pi UI; used to avoid stealing focus mid-typing. */
  getEditorText?(): string;
}

export interface ControllerContext {
  mode: string;
  ui: OverlayUi;
}

export interface ControllerOptions {
  source: PuzzleSource;
  stats: SessionStats;
  /** Delay before the overlay opens after agent_start. Default 1500ms. */
  delayMs?: number;
  /** Injectable for tests. */
  setTimeoutFn?: (fn: () => void, ms: number) => ReturnType<typeof setTimeout>;
  clearTimeoutFn?: (id: ReturnType<typeof setTimeout>) => void;
}

export const DEFAULT_DELAY_MS = 1500;

export class ChessController {
  autoEnabled = true;
  private open = false;
  private opening = false;
  private doneFn: (() => void) | null = null;
  private timer: ReturnType<typeof setTimeout> | null = null;
  /** An agent run is active (set on agent_start, cleared on settle). */
  private running = false;
  /** User closed the overlay during the current run; don't reopen until settle. */
  private dismissed = false;
  /** Half-solved game carried across overlay opens (never a finished one). */
  private resumeGame: PuzzleGame | null = null;
  private readonly delayMs: number;
  private readonly setTimeoutFn;
  private readonly clearTimeoutFn;
  private readonly source: PuzzleSource;
  private readonly stats: SessionStats;

  constructor(options: ControllerOptions) {
    this.source = options.source;
    this.stats = options.stats;
    this.delayMs = options.delayMs ?? DEFAULT_DELAY_MS;
    this.setTimeoutFn = options.setTimeoutFn ?? setTimeout;
    this.clearTimeoutFn = options.clearTimeoutFn ?? clearTimeout;
  }

  get isOpen(): boolean {
    return this.open || this.opening;
  }

  /** agent_start: schedule the overlay unless it's disabled or already up. */
  onAgentStart(ctx: ControllerContext): void {
    this.running = true;
    if (!this.autoEnabled || this.isOpen || this.timer || this.dismissed)
      return;
    if (ctx.mode !== "tui") return;
    this.timer = this.setTimeoutFn(() => {
      this.timer = null;
      try {
        if (!this.autoEnabled || this.dismissed) return;
        // Don't grab keyboard focus while the user is typing a follow-up.
        // (Skipped, not postponed: /chess always opens it manually.)
        if ((ctx.ui.getEditorText?.() ?? "") !== "") return;
      } catch {
        return;
      }
      void this.openOverlay(ctx).catch(() => {});
    }, this.delayMs);
  }

  /** agent_settled / shutdown: cancel a pending open and close the overlay. */
  onAgentSettled(): void {
    if (this.timer) {
      this.clearTimeoutFn(this.timer);
      this.timer = null;
    }
    this.running = false;
    this.dismissed = false;
    this.close();
  }

  /** /chess: toggle the overlay manually (opens instantly). */
  async toggle(ctx: ControllerContext): Promise<void> {
    if (this.isOpen) {
      // Toggled closed by hand during a run: count as dismissed for this run.
      if (this.running) this.dismissed = true;
      this.close();
      return;
    }
    if (ctx.mode !== "tui") {
      ctx.ui.notify("chess puzzles require interactive mode", "error");
      return;
    }
    await this.openOverlay(ctx);
  }

  close(): void {
    const done = this.doneFn;
    this.doneFn = null;
    done?.();
  }

  private async openOverlay(ctx: ControllerContext): Promise<void> {
    if (this.isOpen) return;
    this.opening = true;
    try {
      await ctx.ui.custom<void>(
        (tui, theme, _keybindings, done) => {
          let component: PuzzleBoardComponent;
          const finish = (userInitiated: boolean) => {
            // Closed via the component itself (esc/q): user dismissed it.
            // Settle/shutdown closes go through close() (userInitiated=false).
            if (userInitiated && this.running) this.dismissed = true;
            // Keep a half-solved puzzle so the next open resumes it.
            this.resumeGame = component.activeGame;
            done();
          };
          component = new PuzzleBoardComponent(
            tui,
            theme,
            () => finish(true),
            this.source,
            this.stats,
            this.resumeGame,
            createImageBackend(),
          );
          this.doneFn = () => finish(false);
          this.open = true;
          this.opening = false;
          return component;
        },
        {
          overlay: true,
          overlayOptions: {
            // Wide and tall: the board scales to fill the box (squares
            // stay square, so height is the real limit on big terminals).
            width: "90%",
            maxHeight: "95%",
            anchor: "center",
          },
        },
      );
    } catch (err) {
      ctx.ui.notify(
        `chess puzzles failed: ${err instanceof Error ? err.message : err}`,
        "error",
      );
    } finally {
      this.opening = false;
      this.open = false;
      this.doneFn = null;
    }
  }
}
