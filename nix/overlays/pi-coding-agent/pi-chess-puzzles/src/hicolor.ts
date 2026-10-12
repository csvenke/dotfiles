/**
 * Hi-color board renderer: downsamples the composed RGBA board (fantasy
 * piece set, lichess colors) into half-block text cells — each terminal cell
 * shows two vertically stacked pixels (▀ with fg=top, bg=bottom). Full-color
 * shaded pieces in any terminal, no image protocol required. Colors are
 * quantized to the xterm-256 palette (short escapes, exact on 256-color
 * terminals; truecolor terminals get the same palette via their own mapping).
 *
 * Downsampling is two-stage: box-average 512² → 2× canvas, then nearest →
 * canvas. Pure nearest at coarse scales lands on the sprites' dark outline
 * rows and draws black bars through every piece; pure box-average washes the
 * pieces out. Two stages keep edges crisp without either artifact.
 */

import {
  BOARD_TINTS,
  composeBoard,
  BOARD_PX,
  DARK_SQ,
  LIGHT_SQ,
  type BoardImageState,
} from "./imageboard.ts";

// xterm-256: 16-231 color cube (levels 0,95,135,175,215,255), 232-255 grays.
const CUBE_LEVELS = [0, 95, 135, 175, 215, 255];

export function to256(r: number, g: number, b: number): number {
  const spread = Math.max(r, g, b) - Math.min(r, g, b);
  const q = (v: number) => {
    let best = 0;
    for (let i = 1; i < CUBE_LEVELS.length; i++) {
      if (Math.abs(CUBE_LEVELS[i] - v) < Math.abs(CUBE_LEVELS[best] - v))
        best = i;
    }
    return best;
  };
  if (spread < 45) {
    // near-neutral: pick the nearer of the gray ramp and the cube diagonal —
    // keeps anti-aliased sprite edges neutral instead of picking up hues
    const avg = (r + g + b) / 3;
    const rampIdx = Math.max(0, Math.min(23, Math.round((avg - 8) / 10)));
    const rampLevel = 8 + rampIdx * 10;
    const cubeLevel = CUBE_LEVELS[q(Math.round(avg))];
    return (avg - rampLevel) ** 2 <= (avg - cubeLevel) ** 2
      ? 232 + rampIdx
      : 16 + 43 * q(Math.round(avg)); // cube diagonal: r=g=b
  }
  return 16 + 36 * q(r) + 6 * q(g) + q(b);
}

/**
 * Curated output palette: the board's natural tones (from a histogram of the
 * composed image) plus every state tint blended over both square colors
 * (slightly strengthened for separation). Every emitted pixel is posterized
 * to the nearest entry, so 256-color quantization can never produce speckle.
 */
const BASE_TONES: [number, number, number][] = [
  [LIGHT_SQ.r, LIGHT_SQ.g, LIGHT_SQ.b],
  [DARK_SQ.r, DARK_SQ.g, DARK_SQ.b],
  [150, 115, 85], // piece drop shadow on squares
  [240, 245, 246], // white piece highlight
  [218, 229, 231], // white piece body
  [205, 211, 212], // white piece shade
  [109, 118, 136], // black piece slate highlight
  [81, 87, 105], // black piece slate
  [55, 58, 72], // black piece slate shade
  [44, 45, 47], // black piece body
  [10, 10, 10], // outlines
  [141, 145, 146], // neutral gray (target dots)
];

function blend(
  t: { r: number; g: number; b: number },
  a: number,
  sq: { r: number; g: number; b: number },
): [number, number, number] {
  return [
    Math.round(t.r * a + sq.r * (1 - a)),
    Math.round(t.g * a + sq.g * (1 - a)),
    Math.round(t.b * a + sq.b * (1 - a)),
  ];
}

const PALETTE: { r: number; g: number; b: number; idx: number }[] = (() => {
  const tones: [number, number, number][] = [...BASE_TONES];
  for (const t of [BOARD_TINTS.cursor, BOARD_TINTS.selected]) {
    tones.push(blend(t, 0.5, LIGHT_SQ), blend(t, 0.5, DARK_SQ));
  }
  tones.push(
    blend(BOARD_TINTS.hinted, 0.55, LIGHT_SQ),
    blend(BOARD_TINTS.hinted, 0.55, DARK_SQ),
    blend(BOARD_TINTS.lastMove, 0.45, LIGHT_SQ),
    blend(BOARD_TINTS.lastMove, 0.45, DARK_SQ),
    blend(BOARD_TINTS.target, 0.55, LIGHT_SQ),
    blend(BOARD_TINTS.target, 0.55, DARK_SQ),
  );
  return tones.map(([r, g, b]) => ({ r, g, b, idx: to256(r, g, b) }));
})();

/** Nearest palette entry's 256-color index. */
function posterize(r: number, g: number, b: number): number {
  let best = 0;
  let bd = Infinity;
  for (let i = 0; i < PALETTE.length; i++) {
    const p = PALETTE[i];
    const d = (r - p.r) ** 2 + (g - p.g) ** 2 + (b - p.b) ** 2;
    if (d < bd) {
      bd = d;
      best = i;
    }
  }
  return PALETTE[best].idx;
}

/** Box-average src (RGBA) down to tw×th. */
function downsample(
  src: Uint8Array,
  sw: number,
  sh: number,
  tw: number,
  th: number,
): Uint8Array {
  const out = new Uint8Array(tw * th * 4);
  for (let y = 0; y < th; y++) {
    for (let x = 0; x < tw; x++) {
      const x0 = Math.floor((x * sw) / tw);
      const x1 = Math.max(x0 + 1, Math.floor(((x + 1) * sw) / tw));
      const y0 = Math.floor((y * sh) / th);
      const y1 = Math.max(y0 + 1, Math.floor(((y + 1) * sh) / th));
      let r = 0;
      let g = 0;
      let b = 0;
      let n = 0;
      for (let sy = y0; sy < y1; sy++) {
        for (let sx = x0; sx < x1; sx++) {
          const i = (sy * sw + sx) * 4;
          r += src[i];
          g += src[i + 1];
          b += src[i + 2];
          n++;
        }
      }
      const o = (y * tw + x) * 4;
      out[o] = Math.round(r / n);
      out[o + 1] = Math.round(g / n);
      out[o + 2] = Math.round(b / n);
      out[o + 3] = 255;
    }
  }
  return out;
}

/** Nearest pixel of the prescaled board for canvas pixel (cx, cy). */
function sample(
  img: Uint8Array,
  midW: number,
  midH: number,
  cx: number,
  cy: number,
  cols: number,
  rows: number,
): [number, number, number] {
  const x = Math.min(midW - 1, Math.floor(((cx + 0.5) * midW) / cols));
  const y = Math.min(midH - 1, Math.floor(((cy + 0.5) * midH) / rows));
  const i = (y * midW + x) * 4;
  return [img[i], img[i + 1], img[i + 2]];
}

/**
 * Render the board as half-block lines: `cols` cells wide, `rows` px tall
 * (even), returning `rows / 2` lines. State (cursor, selection, hints,
 * last move) is already baked into the composed image.
 */
export function renderBoardText(
  state: BoardImageState,
  cols: number,
  rows: number,
): string[] {
  const img = composeBoard(state);
  // Stage 1: box-average 512² → 2× canvas; stage 2: nearest → canvas.
  const midW = cols * 2;
  const midH = rows * 2;
  const mid = downsample(img, BOARD_PX, BOARD_PX, midW, midH);
  const lines: string[] = [];
  for (let row = 0; row + 1 < rows; row += 2) {
    let line = "";
    let curFg = -1;
    let curBg = -1;
    for (let c = 0; c < cols; c++) {
      const [tr, tg, tb] = sample(mid, midW, midH, c, row, cols, rows);
      const [br, bg, bb] = sample(mid, midW, midH, c, row + 1, cols, rows);
      const fg = posterize(tr, tg, tb);
      const bgc = posterize(br, bg, bb);
      if (fg !== curFg) {
        line += `\x1b[38;5;${fg}m`;
        curFg = fg;
      }
      if (bgc !== curBg) {
        line += `\x1b[48;5;${bgc}m`;
        curBg = bgc;
      }
      line += "▀";
    }
    lines.push(line + "\x1b[39;49m");
  }
  return lines;
}
