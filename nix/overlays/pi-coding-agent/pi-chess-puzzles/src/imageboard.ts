/**
 * Composes the chess board into a single RGBA image (square colors, state
 * highlights, piece sprites) for the kitty/iterm2 image path. Piece sprites
 * are raw 64x64 RGBA files in assets/pieces (see scripts/fetch-pieces.sh).
 */

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { encodePng } from "./png.ts";

export const SQUARE_PX = 64;
export const BOARD_PX = SQUARE_PX * 8;

export interface BoardImageState {
  /** board[y][x], y 0..7 bottom-up (y=0 is rank 1), x 0..7 file a..h. */
  at(x: number, y: number): { type: string; color: "w" | "b" } | null;
  /** true when rank 1 should be at the bottom (solver plays white). */
  whiteAtBottom: boolean;
  cursor: string | null; // square "e4"
  selected: string | null; // square "e4"
  targets: string[]; // legal target squares for the selection
  hinted: string | null;
  lastMove: { from: string; to: string } | null;
}

interface Rgb {
  r: number;
  g: number;
  b: number;
}

// Classic lichess board colors.
export const LIGHT_SQ: Rgb = { r: 0xf0, g: 0xd9, b: 0xb5 };
export const DARK_SQ: Rgb = { r: 0xb5, g: 0x88, b: 0x63 };

/** State tints (single source of truth — also used to build the text palette). */
export const BOARD_TINTS = {
  cursor: { r: 0x1c, g: 0x90, b: 0xff, a: 0.5 },
  selected: { r: 0x1c, g: 0x90, b: 0xff, a: 0.38 },
  hinted: { r: 0xff, g: 0xaa, b: 0x00, a: 0.45 },
  target: { r: 0xd0, g: 0x30, b: 0x30, a: 0.4 },
  lastMove: { r: 0xff, g: 0xf0, b: 0x40, a: 0.28 },
} as const;

type Tint = { r: number; g: number; b: number; a: number };

function tintOf(
  state: BoardImageState,
  square: string,
  hasPiece: boolean,
): Tint | null {
  if (state.cursor === square) return BOARD_TINTS.cursor;
  if (state.selected === square) return BOARD_TINTS.selected;
  if (state.hinted === square) return BOARD_TINTS.hinted;
  // Legal capture: red tint under the target piece (empty targets get a dot).
  if (hasPiece && state.targets.includes(square)) return BOARD_TINTS.target;
  if (
    state.lastMove &&
    (state.lastMove.from === square || state.lastMove.to === square)
  ) {
    return BOARD_TINTS.lastMove;
  }
  return null;
}

let pieceCache: Map<string, Uint8Array> | null = null;

/** Load raw RGBA piece sprites from assets/pieces (next to the extension). */
export function loadPieces(): Map<string, Uint8Array> {
  if (pieceCache) return pieceCache;
  const dir = fileURLToPath(new URL("../assets/pieces/", import.meta.url));
  const map = new Map<string, Uint8Array>();
  for (const color of ["w", "b"]) {
    for (const type of ["k", "q", "r", "b", "n", "p"]) {
      const name = `${color}${type.toUpperCase()}`;
      const data = new Uint8Array(readFileSync(dir + name + ".rgba"));
      if (data.length !== SQUARE_PX * SQUARE_PX * 4) {
        throw new Error(
          `piece ${name}: expected ${SQUARE_PX * SQUARE_PX * 4} bytes, got ${data.length}`,
        );
      }
      map.set(color + type, data);
    }
  }
  pieceCache = map;
  return map;
}

function blitPiece(
  out: Uint8Array,
  piece: Uint8Array,
  ox: number,
  oy: number,
): void {
  for (let y = 0; y < SQUARE_PX; y++) {
    for (let x = 0; x < SQUARE_PX; x++) {
      const si = (y * SQUARE_PX + x) * 4;
      const a = piece[si + 3];
      if (a === 0) continue;
      const di = ((oy + y) * BOARD_PX + (ox + x)) * 4;
      if (a === 255) {
        out[di] = piece[si];
        out[di + 1] = piece[si + 1];
        out[di + 2] = piece[si + 2];
        out[di + 3] = 255;
      } else {
        const alpha = a / 255;
        const inv = 1 - alpha;
        out[di] = Math.round(piece[si] * alpha + out[di] * inv);
        out[di + 1] = Math.round(piece[si + 1] * alpha + out[di + 1] * inv);
        out[di + 2] = Math.round(piece[si + 2] * alpha + out[di + 2] * inv);
        out[di + 3] = 255;
      }
    }
  }
}

function drawDot(out: Uint8Array, cx: number, cy: number): void {
  const radius = SQUARE_PX * 0.16;
  const r2 = radius * radius;
  for (let y = Math.floor(cy - radius); y <= cy + radius; y++) {
    for (let x = Math.floor(cx - radius); x <= cx + radius; x++) {
      if ((x - cx) * (x - cx) + (y - cy) * (y - cy) > r2) continue;
      if (x < 0 || y < 0 || x >= BOARD_PX || y >= BOARD_PX) continue;
      const i = (y * BOARD_PX + x) * 4;
      const a = 0.35;
      out[i] = Math.round(0x14 * a + out[i] * (1 - a));
      out[i + 1] = Math.round(0x14 * a + out[i + 1] * (1 - a));
      out[i + 2] = Math.round(0x14 * a + out[i + 2] * (1 - a));
    }
  }
}

/** Compose the board into raw RGBA pixels. */
export function composeBoard(state: BoardImageState): Uint8Array {
  const pieces = loadPieces();
  const out = new Uint8Array(BOARD_PX * BOARD_PX * 4);
  for (let dr = 0; dr < 8; dr++) {
    for (let dx = 0; dx < 8; dx++) {
      // display (dx, dr), dr 0 = top row of the image
      const bx = state.whiteAtBottom ? dx : 7 - dx;
      const by = state.whiteAtBottom ? 7 - dr : dr;
      const square = String.fromCharCode(97 + bx) + (by + 1);
      const base = (bx + by) % 2 === 0 ? DARK_SQ : LIGHT_SQ;
      const piece = state.at(bx, by);
      const tint = tintOf(state, square, piece !== null);
      const ox = dx * SQUARE_PX;
      const oy = dr * SQUARE_PX;
      for (let y = 0; y < SQUARE_PX; y++) {
        for (let x = 0; x < SQUARE_PX; x++) {
          const i = ((oy + y) * BOARD_PX + (ox + x)) * 4;
          let r = base.r;
          let g = base.g;
          let b = base.b;
          if (tint) {
            r = Math.round(tint.r * tint.a + r * (1 - tint.a));
            g = Math.round(tint.g * tint.a + g * (1 - tint.a));
            b = Math.round(tint.b * tint.a + b * (1 - tint.a));
          }
          out[i] = r;
          out[i + 1] = g;
          out[i + 2] = b;
          out[i + 3] = 255;
        }
      }
      if (piece) {
        blitPiece(out, pieces.get(piece.color + piece.type)!, ox, oy);
      }
      if (state.targets.includes(square) && !piece) {
        drawDot(out, ox + SQUARE_PX / 2, oy + SQUARE_PX / 2);
      }
    }
  }
  return out;
}

/** Compose and PNG-encode the board. */
export function renderBoardPng(state: BoardImageState): {
  base64: string;
  widthPx: number;
  heightPx: number;
} {
  const png = encodePng(composeBoard(state), BOARD_PX, BOARD_PX);
  return {
    base64: Buffer.from(png).toString("base64"),
    widthPx: BOARD_PX,
    heightPx: BOARD_PX,
  };
}
