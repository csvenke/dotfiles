import assert from "node:assert/strict";
import test from "node:test";
import { getPngDimensions } from "@earendil-works/pi-tui";
import { PuzzleGame } from "../src/game.ts";
import {
  BOARD_PX,
  SQUARE_PX,
  composeBoard,
  loadPieces,
  renderBoardPng,
  type BoardImageState,
} from "../src/imageboard.ts";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import { parsePuzzle } from "../src/puzzle.ts";

function stateFor(id: string, whiteAtBottom: boolean): BoardImageState {
  const raw = fallbackPuzzles.find((p) => p.puzzle.id === id);
  assert.ok(raw);
  const game = new PuzzleGame(parsePuzzle(raw));
  return {
    at: (x, y) => game.board[7 - y]?.[x] ?? null,
    whiteAtBottom,
    cursor: null,
    selected: null,
    targets: [],
    hinted: null,
    lastMove: null,
  };
}

function px(img: Uint8Array, x: number, y: number): number[] {
  const i = (y * BOARD_PX + x) * 4;
  return [img[i], img[i + 1], img[i + 2], img[i + 3]];
}

test("loadPieces loads all 12 sprites at 64x64 RGBA", () => {
  const pieces = loadPieces();
  assert.equal(pieces.size, 12);
  for (const [name, data] of pieces) {
    assert.equal(data.length, 64 * 64 * 4, name);
    assert.ok(
      data.some((b) => b > 0),
      `${name} has content`,
    );
  }
});

function emptyState(whiteAtBottom: boolean): BoardImageState {
  return {
    at: () => null,
    whiteAtBottom,
    cursor: null,
    selected: null,
    targets: [],
    hinted: null,
    lastMove: null,
  };
}

test("composeBoard paints lichess colors, dark a1 at bottom-left for white", () => {
  const img = composeBoard(emptyState(true));
  // bottom-left display pixel = a1 = dark square (#b58863)
  const a1 = px(img, 5, BOARD_PX - 5);
  assert.deepEqual(a1.slice(0, 3), [0xb5, 0x88, 0x63]);
  // a2 = light square (#f0d9b5)
  const a2 = px(img, 5, BOARD_PX - SQUARE_PX - 5);
  assert.deepEqual(a2.slice(0, 3), [0xf0, 0xd9, 0xb5]);
});

test("composeBoard flips the board for black", () => {
  const black = composeBoard(emptyState(false));
  // black at bottom: bottom-left display pixel = h8 = dark square
  const bottomLeft = px(black, 5, BOARD_PX - 5);
  assert.deepEqual(bottomLeft.slice(0, 3), [0xb5, 0x88, 0x63]);
  // top-left = h1 = light square
  const topLeft = px(black, 5, 5);
  assert.deepEqual(topLeft.slice(0, 3), [0xf0, 0xd9, 0xb5]);
});

test("composeBoard blits pieces (non-square pixels where a piece stands)", () => {
  const state = stateFor("fxiw1", true);
  const img = composeBoard(state);
  // find a square with a piece on it and check its pixels differ from the flat square color
  let found = false;
  for (let y = 0; y < 8 && !found; y++) {
    for (let x = 0; x < 8 && !found; x++) {
      if (!state.at(x, y)) continue;
      const cx = x * SQUARE_PX + SQUARE_PX / 2;
      const cy = (7 - y) * SQUARE_PX + SQUARE_PX / 2;
      const light = (x + y) % 2 !== 0;
      const base = light ? [0xf0, 0xd9, 0xb5] : [0xb5, 0x88, 0x63];
      if (
        px(img, cx, cy)
          .slice(0, 3)
          .some((v, i) => Math.abs(v - base[i]) > 10)
      ) {
        found = true;
      }
    }
  }
  assert.ok(found, "some piece pixel differs from its square color");
});

test("composeBoard tints the cursor square", () => {
  const state = emptyState(true);
  state.cursor = "e4"; // empty light square
  const img = composeBoard(state);
  const cx = 4 * SQUARE_PX + SQUARE_PX / 2;
  const cy = (7 - 3) * SQUARE_PX + SQUARE_PX / 2;
  const tinted = px(img, cx, cy);
  // light square [240,217,181] + blue tint at a=0.5 → blue up, red down
  assert.ok(tinted[2] > 200, `blue channel lifted: ${tinted}`);
  assert.ok(tinted[0] < 200, `red channel dimmed: ${tinted}`);
});

test("renderBoardPng emits a valid 512x512 PNG", () => {
  const { base64, widthPx, heightPx } = renderBoardPng(stateFor("fxiw1", true));
  assert.equal(widthPx, BOARD_PX);
  assert.equal(heightPx, BOARD_PX);
  const bytes = Buffer.from(base64, "base64");
  assert.deepEqual([...bytes.subarray(0, 4)], [0x89, 0x50, 0x4e, 0x47]);
  // pi-tui's own parser accepts it
  const dims = getPngDimensions(base64);
  assert.deepEqual(dims, { widthPx: BOARD_PX, heightPx: BOARD_PX });
});

test("composeBoard tints capture targets under their piece", () => {
  const state = stateFor("fxiw1", true);
  // find an occupied square to use as a capture target
  let target: string | null = null;
  for (let y = 0; y < 8 && !target; y++) {
    for (let x = 0; x < 8 && !target; x++) {
      if (state.at(x, y)) target = String.fromCharCode(97 + x) + (y + 1);
    }
  }
  assert.ok(target);
  const plain = composeBoard(state);
  state.targets = [target];
  const tinted = composeBoard(state);
  // a corner pixel of that square (away from the piece's center) shifts red
  const file = target.charCodeAt(0) - 97;
  const rank = target.charCodeAt(1) - 49;
  const cx = file * SQUARE_PX + 4;
  const cy = (7 - rank) * SQUARE_PX + 4;
  const before = px(plain, cx, cy);
  const after = px(tinted, cx, cy);
  // red tint at a=0.4: green drops on both light and dark squares
  assert.ok(after[1] < before[1], `green channel down: ${before} -> ${after}`);
  assert.notDeepEqual(after, before);
});
