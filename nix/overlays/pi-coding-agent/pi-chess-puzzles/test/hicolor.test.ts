import assert from "node:assert/strict";
import test from "node:test";
import { visibleWidth } from "@earendil-works/pi-tui";
import { PuzzleBoardComponent, emptyStats } from "../src/component.ts";
import { PuzzleGame } from "../src/game.ts";
import { renderBoardText, to256 } from "../src/hicolor.ts";
import type { BoardImageState } from "../src/imageboard.ts";
import { PuzzleSource } from "../src/lichess.ts";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import { parsePuzzle, type LichessPuzzleResponse } from "../src/puzzle.ts";

const ANSI = /\x1b\[[0-9;]*m/g;
const strip = (s: string) => s.replace(ANSI, "");

function fixtureState(id = "fxiw1"): BoardImageState {
  const raw = fallbackPuzzles.find((p) => p.puzzle.id === id);
  assert.ok(raw);
  const game = new PuzzleGame(parsePuzzle(raw));
  return {
    at: (x, y) => game.board[7 - y]?.[x] ?? null,
    whiteAtBottom: true,
    cursor: null,
    selected: null,
    targets: [],
    hinted: null,
    lastMove: null,
  };
}

test("to256 maps whites, blacks, grays, and board colors sanely", () => {
  assert.equal(to256(255, 255, 255), 231); // cube white (nearer than ramp top)
  assert.equal(to256(16, 16, 20), 232 + 1); // near-black → gray ramp
  assert.equal(to256(48, 48, 48), 232 + 4); // dark square gray
  const light = to256(0xf0, 0xd9, 0xb5); // lichess light square
  assert.ok(light >= 16 && light <= 231, `light square in the cube: ${light}`);
  const dark = to256(0xb5, 0x88, 0x63);
  assert.ok(dark >= 16 && dark <= 231, `dark square in the cube: ${dark}`);
  assert.notEqual(light, dark);
});

test("posterized pieces keep clean white interiors (no hue speckle)", () => {
  const state = fixtureState();
  const lines = renderBoardText(state, 88, 80).join("\n");
  // palette whites are the ramp top (#eeeeee) and cube white (#ffffff)
  assert.match(lines, /38;5;(231|255)m/, "white piece interiors stay white");
  // and near-neutral sprite edges never become colored cube entries
  assert.doesNotMatch(lines, /38;5;18[17]m/, "no pinkish 181/187 fringe");
});

test("renderBoardText emits rows/2 half-block lines of exact width", () => {
  const lines = renderBoardText(fixtureState(), 88, 40);
  assert.equal(lines.length, 20);
  for (const line of lines) {
    assert.equal(visibleWidth(line), 88);
  }
  const raw = lines.join("\n");
  assert.match(raw, /▀/);
  assert.match(raw, /\x1b\[38;5;/, "foreground colors set");
  assert.match(raw, /\x1b\[48;5;/, "background colors set");
  assert.ok(raw.includes("\x1b[39;49m"), "colors reset per line");
});

test("renderBoardText differs between an empty and an occupied board", () => {
  const state = fixtureState();
  const withPieces = renderBoardText(state, 40, 16).join("\n");
  const empty = renderBoardText({ ...state, at: () => null }, 40, 16).join(
    "\n",
  );
  assert.notEqual(withPieces, empty);
});

test("default path renders hicolor (not 1-bit art) when assets exist", async () => {
  let i = 0;
  const fetcher = async (): Promise<LichessPuzzleResponse> =>
    fallbackPuzzles[i++ % fallbackPuzzles.length];
  const source = new PuzzleSource({ fetcher, prefetchCount: 1 });
  const component = new PuzzleBoardComponent(
    { requestRender() {} },
    { appearance: "dark", fg: (_t, s) => s },
    () => {},
    source,
    emptyStats(),
  );
  await component.whenIdle();
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: 0,
    configurable: true,
  });
  try {
    const lines = component.render(90);
    const raw = lines.join("\n");
    assert.match(raw, /▀/);
    // lichess square colors quantize to cube colors the art path never uses
    assert.match(
      raw,
      /48;5;(223|137)m/,
      "hicolor board colors present (proves hicolor, not art)",
    );
    // and an art-path render of the same state differs
    const artOnly = new PuzzleBoardComponent(
      { requestRender() {} },
      { appearance: "dark", fg: (_t, s) => s },
      () => {},
      source,
      emptyStats(),
      null,
      null,
      true,
    );
    await artOnly.whenIdle();
    assert.notEqual(raw, artOnly.render(90).join("\n"));
    // frame alignment holds with the color noise
    const trimmed = lines.map((l) => strip(l).trimEnd());
    const widths = new Set(trimmed.map((l) => visibleWidth(l)));
    assert.equal(widths.size, 1, "frame lines share one width");
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
});
