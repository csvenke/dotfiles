import assert from "node:assert/strict";
import test from "node:test";
import {
  PuzzleBoardComponent,
  emptyStats,
  type BoardTheme,
} from "../src/component.ts";
import {
  ChessController,
  type ControllerContext,
  type OverlayUi,
  type TuiLike,
} from "../src/controller.ts";
import { PuzzleSource } from "../src/lichess.ts";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import type { LichessPuzzleResponse, PuzzleData } from "../src/puzzle.ts";

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

type Factory = (
  tui: TuiLike,
  theme: BoardTheme,
  keybindings: unknown,
  done: (result: void) => void,
) => PuzzleBoardComponent;

class FakeUi {
  notifications: { message: string; type?: string }[] = [];
  customCalls = 0;
  options:
    { overlay?: boolean; overlayOptions?: Record<string, unknown> } | undefined;
  lastComponent: PuzzleBoardComponent | null = null;
  editorText = "";
  failCustom = false;

  getEditorText(): string {
    return this.editorText;
  }

  custom<T>(
    factory: Factory,
    options?: { overlay?: boolean; overlayOptions?: Record<string, unknown> },
  ): Promise<T> {
    this.customCalls++;
    this.options = options;
    if (this.failCustom) {
      return Promise.reject(new Error("ui exploded"));
    }
    let resolveCustom: () => void = () => {};
    const promise = new Promise<T>((resolve) => {
      resolveCustom = () => resolve(undefined as T);
    });
    // Mirror pi: the factory runs immediately and done() resolves custom().
    this.lastComponent = factory(
      { requestRender() {} },
      { appearance: "dark", fg: (_t, s) => s },
      null,
      () => resolveCustom(),
    );
    return promise;
  }

  notify(message: string, type?: string) {
    this.notifications.push({ message, type });
  }
}

function make(delayMs = 5) {
  const ui = new FakeUi();
  let i = 0;
  const fetcher = async (): Promise<LichessPuzzleResponse> =>
    fallbackPuzzles[i++ % fallbackPuzzles.length];
  const controller = new ChessController({
    source: new PuzzleSource({ fetcher, prefetchCount: 1 }),
    stats: emptyStats(),
    delayMs,
  });
  const ctx: ControllerContext = {
    mode: "tui",
    ui: ui as unknown as OverlayUi,
  };
  return { ui, controller, ctx };
}

function openComponent(ui: FakeUi): PuzzleBoardComponent {
  assert.ok(ui.lastComponent, "overlay component created");
  return ui.lastComponent;
}

test("agent_start opens the overlay after the delay", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx);
  assert.equal(ui.customCalls, 0, "not before the delay");
  await sleep(30);
  assert.equal(ui.customCalls, 1);
  assert.equal(ui.options?.overlay, true);
  assert.ok(ui.options?.overlayOptions);
  // the factory builds a real component
  openComponent(ui).dispose();
});

test("settle before the delay elapses never opens", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx);
  controller.onAgentSettled();
  await sleep(30);
  assert.equal(ui.customCalls, 0);
});

test("agent_settled closes an open overlay", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 1);
  assert.equal(controller.isOpen, true);
  controller.onAgentSettled(); // → close() → done() → custom() resolves
  await sleep(0);
  assert.equal(controller.isOpen, false);
});

test("a second agent_start while open does not open again", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx);
  await sleep(30);
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 1);
});

test("non-TUI modes never open", async () => {
  const { ui, controller, ctx } = make();
  (ctx as { mode: string }).mode = "print";
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 0);
});

test("autoEnabled=false suppresses auto-open", async () => {
  const { ui, controller, ctx } = make();
  controller.autoEnabled = false;
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 0);
});

test("/chess toggles the overlay manually, instantly", async () => {
  const { ui, controller, ctx } = make();
  const opening = controller.toggle(ctx);
  await sleep(0);
  assert.equal(ui.customCalls, 1, "no delay for manual open");
  assert.equal(controller.isOpen, true);
  // toggle again closes
  const closing = controller.toggle(ctx);
  await sleep(0);
  assert.equal(controller.isOpen, false);
  await opening;
  await closing;
  // and it can reopen
  const reopening = controller.toggle(ctx);
  await sleep(0);
  assert.equal(ui.customCalls, 2);
  controller.close();
  await reopening;
});

test("/chess in print mode notifies instead of opening", async () => {
  const { ui, controller, ctx } = make();
  (ctx as { mode: string }).mode = "print";
  await controller.toggle(ctx);
  assert.equal(ui.customCalls, 0);
  assert.match(
    ui.notifications.map((n) => n.message).join("\n"),
    /interactive/,
  );
});

test("user closing the overlay (done) resets controller state", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx);
  await sleep(30);
  const component = openComponent(ui);
  assert.equal(controller.isOpen, true);
  component.handleInput("\x1b"); // user closes via ESC → done() → resolves
  await sleep(0);
  assert.equal(controller.isOpen, false);
  // dismissed mid-run; next run (after settle) can open again
  controller.onAgentSettled();
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 2);
  controller.close();
});

test("dismissing mid-run prevents reopening until the run settles", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 1);
  // user presses ESC (component-initiated close)
  openComponent(ui).handleInput("\x1b");
  await sleep(0);
  // an auto-retry fires agent_start again within the same run
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 1, "not reopened after a user dismiss");
  // run ends: the next run may auto-open again
  controller.onAgentSettled();
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 2);
  controller.close();
});

test("auto-open is skipped while the editor has text", async () => {
  const { ui, controller, ctx } = make();
  ui.editorText = "half-typed follow-up";
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 0);
});

test("/chess during a pending auto-open timer opens exactly once", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx); // timer pending
  const opening = controller.toggle(ctx); // manual open wins immediately
  await sleep(30); // timer fires during the open overlay
  assert.equal(ui.customCalls, 1);
  controller.close();
  await opening;
});

test("a failing ui.custom notifies and resets state", async () => {
  const { ui, controller, ctx } = make();
  ui.failCustom = true;
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 1);
  assert.match(
    ui.notifications.map((n) => n.message).join("\n"),
    /chess puzzles failed: ui exploded/,
  );
  assert.equal(controller.isOpen, false);
  // next run can try again
  ui.failCustom = false;
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 2);
  controller.close();
});

test("closing an idle manual overlay does not suppress the next run", async () => {
  const { ui, controller, ctx } = make();
  const opening = controller.toggle(ctx); // open while idle (no run active)
  await sleep(0);
  assert.equal(ui.customCalls, 1);
  await controller.toggle(ctx); // close while idle: dismissed must NOT stick
  await opening;
  controller.onAgentStart(ctx);
  await sleep(30);
  assert.equal(ui.customCalls, 2, "auto-open still works on the next run");
  controller.close();
});

test("a half-solved puzzle resumes on the next run", async () => {
  const { ui, controller, ctx } = make();
  controller.onAgentStart(ctx);
  await sleep(30);
  const first = openComponent(ui);
  await first.whenIdle();
  // play the first correct move of the loaded puzzle
  const g1 = (first as never as { game: { puzzle: PuzzleData } }).game;
  const uci = g1.puzzle.solution[0];
  first.selectSquare(uci.slice(0, 2));
  first.selectSquare(uci.slice(2, 4));
  // the run settles mid-puzzle: overlay closes, game is kept
  controller.onAgentSettled();
  await sleep(0);
  // next run reopens with the same puzzle at the same progress
  controller.onAgentStart(ctx);
  await sleep(30);
  const second = openComponent(ui);
  await second.whenIdle();
  const g2 = (
    second as never as {
      game: { puzzle: PuzzleData; progress: { done: number } };
    }
  ).game;
  assert.equal(g2.puzzle.id, g1.puzzle.id);
  assert.equal(g2.progress.done, 1);
  controller.close();
});
