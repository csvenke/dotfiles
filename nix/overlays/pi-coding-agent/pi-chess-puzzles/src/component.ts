/**
 * Chess puzzle overlay component for the pi TUI.
 *
 * Renders a Unicode board (outline glyphs = white, filled = black) with a
 * keyboard cursor; square state is conveyed with background colors. Input:
 * arrows/hjkl move, enter/space select+confirm, H hint, N next/skip,
 * q/esc close, q/r/b/n while a promotion is pending.
 */

import {
  matchesKey,
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";
import { PuzzleGame, type PromotionPiece } from "./game.ts";
import { renderBoardText } from "./hicolor.ts";
import {
  loadPieces,
  renderBoardPng,
  type BoardImageState,
} from "./imageboard.ts";
import type { ImageBackend } from "./imagebackend.ts";
import type { PuzzleSource } from "./lichess.ts";
import type { PuzzleData } from "./puzzle.ts";

export interface SessionStats {
  solved: number;
  failed: number;
  streak: number;
  best: number;
}

export function emptyStats(): SessionStats {
  return { solved: 0, failed: 0, streak: 0, best: 0 };
}

/** Narrow slice of the pi theme API this component uses (easy to fake). */
export interface BoardTheme {
  appearance: "dark" | "light";
  fg(token: string, text: string): string;
}

interface TuiLike {
  requestRender(): void;
}

const LABEL_COLS = 2; // rank label + space, left of the board
const FRAME_COLS = 4; // "│ " + " │" around the card
const CHROME_ROWS = 8; // frame top/bottom, header, separator, status, info, footer, file labels
const MIN_WIDTH = 24; // below this a notice is shown instead of the board
const MAX_CELL_W = 12; // sanity cap on huge terminals
const CURSOR_BG = 25; // cursor square background (distinct from selection's 33)

const GLYPHS: Record<string, Record<string, string>> = {
  // \uFE0E forces text presentation so terminals keep glyphs 1 column wide.
  w: { k: "♔︎", q: "♕︎", r: "♖︎", b: "♗︎", n: "♘︎", p: "♙︎" },
  b: { k: "♚︎", q: "♛︎", r: "♜︎", b: "♝︎", n: "♞︎", p: "♟︎" },
};

/**
 * 8×8 piece sprites ('#' = filled pixel), from the CC0 1-bit chess set by
 * crmaykish (https://github.com/crmaykish/chess_sprites_1bit, see README). Rendered with half blocks (▀▄█),
 * so one 8×4 square = an 8×8 pixel canvas. An outline ring is computed
 * automatically (dark for white pieces, light for black) so pieces read on
 * both square shades in both themes. Used when cells are big enough;
 * otherwise the single-glyph fallback above is used.
 */
const PIECE_ART: Record<string, string[]> = {
  k: [
    "........",
    "...##...",
    "..####..",
    "...##...",
    ".######.",
    "...##...",
    "..####..",
    ".######.",
  ],
  q: [
    "........",
    "...##...",
    ".##..##.",
    "..####..",
    "...##...",
    "...##...",
    "..####..",
    ".######.",
  ],
  r: [
    "........",
    "..#..#..",
    "..####..",
    "..####..",
    "...##...",
    "...##...",
    "..####..",
    ".######.",
  ],
  b: [
    "........",
    "...#....",
    "..##.#..",
    "..#.##..",
    "...##...",
    "...##...",
    "..####..",
    ".######.",
  ],
  n: [
    "........",
    "...####.",
    "..#.###.",
    "..####..",
    "...###..",
    "...##...",
    "..####..",
    ".######.",
  ],
  p: [
    "........",
    "........",
    "...##...",
    "..####..",
    "..####..",
    "...##...",
    "..####..",
    ".######.",
  ],
};

// Sprite pixel: 0 empty (square color), 1 piece fill, 2 outline.
type Px = 0 | 1 | 2;

const spriteCache = new Map<string, Px[][]>();

function sprite(type: string): Px[][] {
  let rows = spriteCache.get(type);
  if (rows) return rows;
  const art = PIECE_ART[type];
  const grid: Px[][] = art.map((row) =>
    row.split("").map((ch) => (ch === "#" ? 1 : 0) as Px),
  );
  for (let y = 0; y < 8; y++) {
    for (let x = 0; x < 8; x++) {
      if (grid[y][x] !== 0) continue;
      const nearFill =
        grid[y - 1]?.[x] === 1 ||
        grid[y + 1]?.[x] === 1 ||
        grid[y][x - 1] === 1 ||
        grid[y][x + 1] === 1;
      if (nearFill) grid[y][x] = 2;
    }
  }
  spriteCache.set(type, grid);
  return grid;
}

type PendingPromotion = { from: string; to: string };

export class PuzzleBoardComponent {
  private game: PuzzleGame | null = null;
  private loading = true;
  private loadError: string | null = null;
  private offlineNotice = false;
  private cursor = { x: 0, y: 6 }; // board coords: x=file 0..7 (a..h), y=rank 0..7 (1..8)
  private selected: string | null = null;
  private targets: string[] = [];
  private hinted: string | null = null;
  private pendingPromotion: PendingPromotion | null = null;
  private message: string | null = null;
  private loadGeneration = 0;
  private loadPromise: Promise<void> | null = null;
  private cachedLines: string[] = [];
  private cachedWidth = 0;
  private cachedRows = 0;
  private version = 0;
  private cachedVersion = -1;
  private readonly darkSquare: number;
  private readonly lightSquare: number;
  private readonly lastMoveSquare: number;

  private readonly tui: TuiLike;
  private readonly theme: BoardTheme;
  private readonly done: () => void;
  private readonly source: PuzzleSource;
  private readonly stats: SessionStats;
  private readonly imageBackend: ImageBackend | null;
  private readonly forceArt: boolean;
  private hicolorOk: boolean | null = null;
  private imageCache: {
    version: number;
    base64: string;
    widthPx: number;
    heightPx: number;
  } | null = null;

  constructor(
    tui: TuiLike,
    theme: BoardTheme,
    done: () => void,
    source: PuzzleSource,
    stats: SessionStats,
    resumeGame?: PuzzleGame | null,
    imageBackend?: ImageBackend | null,
    forceArt?: boolean,
  ) {
    this.tui = tui;
    this.theme = theme;
    this.done = done;
    this.source = source;
    this.stats = stats;
    this.imageBackend = imageBackend ?? null;
    this.forceArt = forceArt ?? false;
    // Neutral square shades; 256-colors read well in both appearances.
    this.darkSquare = theme.appearance === "dark" ? 236 : 250;
    this.lightSquare = theme.appearance === "dark" ? 239 : 253;
    this.lastMoveSquare = theme.appearance === "dark" ? 240 : 252;
    if (resumeGame && resumeGame.status === "playing") {
      // Continue the puzzle that was interrupted when the agent settled.
      this.game = resumeGame;
      this.loading = false;
      this.cursor = this.initialCursor(resumeGame.puzzle);
    } else {
      void this.loadNext();
    }
  }

  /** The in-progress game, if any — the controller resumes it next open. */
  get activeGame(): PuzzleGame | null {
    return this.game && this.game.status === "playing" ? this.game : null;
  }

  /** Resolves when the current puzzle load settles (tests/controllers). */
  async whenIdle(): Promise<void> {
    await this.loadPromise;
  }

  /** Exposed for tests and for reuse by future input modes. */
  selectSquare(square: string): void {
    const game = this.game;
    if (!game || this.loading || game.status !== "playing") return;
    if (this.pendingPromotion) return;

    if (!this.selected) {
      const piece = game.pieceAt(square);
      if (
        piece &&
        piece.color === game.turn &&
        game.legalTargets(square).length > 0
      ) {
        this.selected = square;
        this.targets = game.legalTargets(square);
      }
      this.bump();
      return;
    }

    if (square === this.selected) {
      this.clearSelection();
      this.bump();
      return;
    }

    // Clicking another own piece re-selects it.
    const piece = game.pieceAt(square);
    if (piece && piece.color === game.turn && !this.targets.includes(square)) {
      this.selected = square;
      this.targets = game.legalTargets(square);
      this.bump();
      return;
    }

    const from = this.selected;
    if (
      game.isPromotion(from, square) &&
      game.legalTargets(from).includes(square)
    ) {
      this.pendingPromotion = { from, to: square };
      this.bump();
      return;
    }
    this.playMove(from, square);
  }

  handleInput(data: string): void {
    if (this.pendingPromotion) {
      if (matchesKey(data, "escape")) {
        this.pendingPromotion = null;
        this.clearSelection();
        this.bump();
        return;
      }
      const choice = { q: "q", r: "r", b: "b", n: "n", k: "n" }[data] as
        PromotionPiece | undefined;
      if (choice) {
        const { from, to } = this.pendingPromotion;
        this.pendingPromotion = null;
        this.playMove(from, to, choice);
      }
      return;
    }

    if (matchesKey(data, "escape") || data === "q") {
      this.dispose();
      this.done();
      return;
    }

    if (this.loading) return;

    if (data === "n" || data === "N") {
      this.skip();
      return;
    }

    const game = this.game;
    if (!game || game.status !== "playing") return;

    if (matchesKey(data, "up") || data === "k") this.moveCursor(0, 1);
    else if (matchesKey(data, "down") || data === "j") this.moveCursor(0, -1);
    else if (matchesKey(data, "left") || data === "h") this.moveCursor(-1, 0);
    else if (matchesKey(data, "right") || data === "l") this.moveCursor(1, 0);
    else if (data === "H") this.showHint();
    else if (matchesKey(data, "enter") || data === " ")
      this.selectSquare(this.squareAt(this.cursor.x, this.cursor.y));
  }

  private moveCursor(dx: number, dy: number): void {
    this.cursor.x = Math.max(0, Math.min(7, this.cursor.x + dx));
    this.cursor.y = Math.max(0, Math.min(7, this.cursor.y + dy));
    this.bump();
  }

  private showHint(): void {
    if (!this.game) return;
    this.hinted = this.game.hint();
    this.bump();
  }

  private skip(): void {
    void this.loadNext();
  }

  private playMove(from: string, to: string, promotion?: PromotionPiece): void {
    const game = this.game;
    if (!game) return;
    const outcome = game.tryMove(from, to, promotion);
    this.clearSelection();
    this.hinted = null;
    switch (outcome.kind) {
      case "illegal":
        break;
      case "failed":
        this.stats.failed++;
        this.stats.streak = 0;
        this.message = `✗ ${outcome.expectedSan} was the move. Solution: ${game.remainingSolutionSan().join(" ")}`;
        break;
      case "correct":
        this.message = `✓ — opponent replied ${outcome.replySan}`;
        break;
      case "solved":
        this.stats.solved++;
        this.stats.streak++;
        this.stats.best = Math.max(this.stats.best, this.stats.streak);
        this.message = outcome.replySan
          ? `✓ Solved! (opponent replied ${outcome.replySan}) — N for next`
          : "✓ Solved! — N for next";
        break;
    }
    this.bump();
  }

  private clearSelection(): void {
    this.selected = null;
    this.targets = [];
  }

  private async loadNext(): Promise<void> {
    const generation = ++this.loadGeneration;
    this.loading = true;
    this.loadError = null;
    this.game = null;
    this.message = null;
    this.clearSelection();
    this.pendingPromotion = null;
    this.hinted = null;
    this.bump();
    this.loadPromise = this.doLoad(generation);
    await this.loadPromise;
  }

  private async doLoad(generation: number): Promise<void> {
    try {
      const puzzle = await this.source.next();
      if (generation !== this.loadGeneration) return; // superseded
      this.game = new PuzzleGame(puzzle);
      this.offlineNotice = this.source.lastError !== null;
      this.cursor = this.initialCursor(puzzle);
    } catch (err) {
      if (generation !== this.loadGeneration) return;
      this.loadError = err instanceof Error ? err.message : String(err);
    } finally {
      if (generation === this.loadGeneration) {
        this.loading = false;
        this.bump();
      }
    }
  }

  private initialCursor(puzzle: PuzzleData): { x: number; y: number } {
    // Start on the first solution from-square, translated to display coords.
    const from = puzzle.solution[0].slice(0, 2);
    return this.displayCoords(from);
  }

  /** Board square (e.g. "e4") → display coords, honoring orientation. */
  private displayCoords(square: string): { x: number; y: number } {
    const file = square.charCodeAt(0) - 97;
    const rank = square.charCodeAt(1) - 49;
    if (this.game?.puzzle.color === "black") {
      return { x: 7 - file, y: 7 - rank };
    }
    return { x: file, y: rank };
  }

  /** Display coords → board square, honoring orientation. */
  private squareAt(x: number, y: number): string {
    let file = x;
    let rank = y;
    if (this.game?.puzzle.color === "black") {
      file = 7 - x;
      rank = 7 - y;
    }
    return String.fromCharCode(97 + file) + (rank + 1);
  }

  private bump(): void {
    this.version++;
    this.tui.requestRender();
  }

  invalidate(): void {
    this.cachedWidth = 0;
  }

  dispose(): void {
    // Bump generation so an in-flight puzzle fetch is ignored after close.
    this.loadGeneration++;
    // Remove a rendered board image; harmless under the text fallbacks.
    const cleanup = this.imageBackend?.dispose();
    if (cleanup) process.stdout.write(cleanup);
  }

  render(width: number): string[] {
    const rows = process.stdout.rows ?? 0;
    if (
      width === this.cachedWidth &&
      this.cachedVersion === this.version &&
      rows === this.cachedRows
    ) {
      return this.cachedLines;
    }
    const lines =
      width < MIN_WIDTH ? this.renderNarrow(width) : this.renderBoard(width);
    this.cachedLines = lines;
    this.cachedWidth = width;
    this.cachedVersion = this.version;
    this.cachedRows = rows;
    return lines;
  }

  private renderNarrow(width: number): string[] {
    return [
      this.fit(
        this.theme.fg("warning", `♞ chess puzzles: needs ${MIN_WIDTH} cols`),
        width,
      ),
    ];
  }

  /**
   * Scale the board to fill the available width, keeping squares square
   * (terminal cells are ~1:2, so cell height = cell width / 2), while
   * keeping the whole card inside the overlay's 95%-of-terminal height cap.
   */
  private layout(width: number): {
    cellW: number;
    cellH: number;
    boardW: number;
  } {
    let cellW = Math.max(
      2,
      Math.floor((width - 2 - FRAME_COLS - LABEL_COLS) / 8),
    );
    let cellH = Math.max(1, Math.floor(cellW / 2));
    const rows = process.stdout.rows ?? 0;
    if (rows > 0) {
      const maxBoardRows = Math.max(
        8,
        Math.floor(rows * 0.95) - CHROME_ROWS - 2,
      );
      const capH = Math.max(1, Math.floor(maxBoardRows / 8));
      if (cellH > capH) {
        cellH = capH;
        cellW = Math.min(cellW, cellH * 2);
      }
    }
    if (cellW > MAX_CELL_W) {
      cellW = MAX_CELL_W;
      cellH = Math.min(cellH, MAX_CELL_W / 2);
    }
    return { cellW, cellH, boardW: LABEL_COLS + 8 * cellW };
  }

  private renderBoard(width: number): string[] {
    const t = this.theme;
    const dim = (s: string) => t.fg("dim", s);
    const { cellW, cellH, boardW } = this.layout(width);

    // Text lines (header/status/info/footer) are composed first so the frame
    // can size itself to the widest of the board and the text.
    const puzzle = this.game?.puzzle;
    const header = `${t.fg("accent", "♞ CHESS")}${dim(puzzle ? ` ${puzzle.rating}` : "")} ${t.fg("success", `${this.stats.solved}`)}✓ ${t.fg("error", `${this.stats.failed}`)}✗ ⚡${this.stats.streak}`;
    const body: string[] = [];
    if (this.loading) {
      body.push(t.fg("muted", "Fetching puzzle…"));
    } else if (this.loadError) {
      body.push(t.fg("error", `Failed to load: ${this.loadError}`));
      body.push(t.fg("muted", "N to retry · esc to close"));
    } else if (this.game) {
      // kitty image when supported; else full-color half-block text; else
      // 1-bit pixel art; single glyphs on very small boards.
      const imageLines = this.boardImageLines(width);
      if (imageLines) {
        body.push(...imageLines);
      } else if (this.hicolorEnabled(cellW, cellH)) {
        try {
          body.push(...this.boardHicolorLines(cellW, cellH));
        } catch {
          this.hicolorOk = false; // never throw out of render(); degrade to art
          body.push(...this.boardLines(cellW, cellH));
        }
      } else {
        body.push(...this.boardLines(cellW, cellH));
      }
    }
    const footer = this.pendingPromotion
      ? `Promote: ${t.fg("accent", "q")}ueen ${t.fg("accent", "r")}ook ${t.fg("accent", "b")}ishop k${t.fg("accent", "n")}ight`
      : `arrows/hjkl move · ${t.fg("accent", "enter")} select · ${t.fg("accent", "H")}int · ${t.fg("accent", "N")}ext · ${t.fg("accent", "esc")} close`;
    const tail: string[] = [];
    if (!this.loading && !this.loadError && this.game && puzzle) {
      tail.push(this.statusLine());
      tail.push(
        dim(`${puzzle.themes.slice(0, 3).join(", ")} · ${puzzle.source}`),
      );
    }
    tail.push(footer);

    // Frame hugs the widest content (usually the board), capped at width.
    const textW = Math.max(
      boardW,
      ...[header, ...body, ...tail].map((l) => visibleWidth(l)),
    );
    const frameInner = Math.min(width - FRAME_COLS, textW);
    const frameW = frameInner + FRAME_COLS;
    const padLeft = " ".repeat(Math.max(0, Math.floor((width - frameW) / 2)));
    const fitLine = (content: string) => {
      const fitted = truncateToWidth(content, frameInner, "…");
      const pad = Math.max(0, frameInner - visibleWidth(fitted));
      return this.fit(
        padLeft + dim("│ ") + fitted + " ".repeat(pad) + dim(" │"),
        width,
      );
    };
    const border = (left: string, right: string) =>
      this.fit(
        padLeft + dim(`${left}${"─".repeat(frameInner + 2)}${right}`),
        width,
      );

    const lines: string[] = [border("╭", "╮")];
    lines.push(fitLine(header));
    lines.push(border("├", "┤"));
    for (const row of body) lines.push(fitLine(row));
    for (const row of tail) lines.push(fitLine(row));
    lines.push(border("╰", "╯"));
    return lines;
  }

  private statusLine(): string {
    const t = this.theme;
    const game = this.game;
    if (!game) return "";
    if (this.pendingPromotion) return t.fg("warning", "Promote the pawn");
    if (this.message) {
      return game.status === "failed"
        ? t.fg("error", this.message)
        : game.status === "solved"
          ? t.fg("success", this.message)
          : this.message;
    }
    const progress = game.progress;
    const side = game.puzzle.color;
    const offline = this.offlineNotice ? " · offline (bundled)" : "";
    return t.fg(
      "text",
      `Your move (${side}) ${progress.done + 1}/${progress.total}${offline}`,
    );
  }

  private boardLines(cellW: number, cellH: number): string[] {
    const game = this.game;
    if (!game) return [];
    const midRow = Math.floor((cellH - 1) / 2);
    const rows: string[] = [];
    for (let dy = 7; dy >= 0; dy--) {
      for (let sub = 0; sub < cellH; sub++) {
        // Rank label (orientation-aware) only on the middle row of the block.
        let row =
          sub === midRow
            ? this.theme.fg("dim", `${this.squareAt(0, dy).slice(1)} `)
            : " ".repeat(LABEL_COLS);
        for (let dx = 0; dx < 8; dx++) {
          row += this.cell(dx, dy, cellW, cellH, sub);
        }
        rows.push(row);
      }
    }
    // File labels, centered under each file
    let files = " ".repeat(LABEL_COLS);
    for (let dx = 0; dx < 8; dx++) {
      files += this.centerIn(this.squareAt(dx, 0).slice(0, 1), cellW);
    }
    rows.push(this.theme.fg("dim", files));
    return rows;
  }

  private centerIn(content: string, cellW: number): string {
    const left = Math.floor((cellW - visibleWidth(content)) / 2);
    return (
      " ".repeat(Math.max(0, left)) +
      content +
      " ".repeat(Math.max(0, cellW - visibleWidth(content) - left))
    );
  }

  /**
   * Board as a terminal image (kitty/iterm2), or null to fall back to pixel
   * art. The image is a square PNG composed from the live game state; the
   * escape sequence is zero-width, so lines are padded with spaces to the
   * image's cell width to keep the frame math working.
   */
  private boardImageLines(width: number): string[] | null {
    const backend = this.imageBackend;
    const game = this.game;
    if (!backend || !game || !backend.supported()) return null;

    let C = Math.floor((width - FRAME_COLS - LABEL_COLS) / 8) * 8;
    if (C < 16) return null;
    const rows = process.stdout.rows ?? 0;
    if (rows > 0) {
      // image rows + frame 2 + header/sep/files/status/info/footer 6 + 2 slack
      const maxImageRows = Math.max(8, Math.floor(rows * 0.95) - 10);
      const dims = backend.cellDims();
      const rowsFor = (c: number) =>
        Math.ceil((c * dims.widthPx) / dims.heightPx);
      while (C > 16 && rowsFor(C) > maxImageRows) C -= 8;
      if (rowsFor(C) > maxImageRows) return null;
    }

    let data = this.imageCache;
    if (!data || data.version !== this.version) {
      try {
        data = { version: this.version, ...this.composeImage() };
        this.imageCache = data;
      } catch {
        return null; // e.g. assets missing: pixel-art fallback
      }
    }
    const res = backend.render(
      data.base64,
      { widthPx: data.widthPx, heightPx: data.heightPx },
      { maxWidthCells: C, maxHeightCells: C },
    );
    if (!res) return null;

    const seqLineIdx = res.anchor === "first" ? 0 : res.rows - 1;
    // One label line per rank; distinct whenever rows >= 8 (always: C >= 16).
    const labelRow = new Map<number, number>();
    for (let dr = 0; dr < 8; dr++) {
      labelRow.set(Math.floor(((dr + 0.5) * res.rows) / 8), dr);
    }
    const lines: string[] = [];
    for (let i = 0; i < res.rows; i++) {
      const dr = labelRow.get(i);
      let line =
        dr !== undefined
          ? this.theme.fg("dim", `${this.squareAt(0, 7 - dr).slice(1)} `)
          : " ".repeat(LABEL_COLS);
      if (i === seqLineIdx) {
        const seq =
          res.anchor === "last" && res.rows > 1
            ? `\x1b[${res.rows - 1}A` + res.sequence
            : res.sequence;
        line += seq;
      }
      line += " ".repeat(C);
      lines.push(line);
    }
    // File labels, exactly under their files (C is a multiple of 8).
    let files = " ".repeat(LABEL_COLS);
    for (let dx = 0; dx < 8; dx++) {
      files += this.centerIn(this.squareAt(dx, 0).slice(0, 1), C / 8);
    }
    lines.push(this.theme.fg("dim", files));
    return lines;
  }

  private composeImage(): {
    base64: string;
    widthPx: number;
    heightPx: number;
  } {
    return renderBoardPng(this.imageState());
  }

  private imageState(): BoardImageState {
    const game = this.game;
    if (!game) throw new Error("imageState without a game");
    const whiteAtBottom = game.puzzle.color === "white";
    return {
      // chess.js board() is [rank8..rank1][fileA..H]; at() takes board coords
      at: (x, y) => game.board[7 - y]?.[x] ?? null,
      whiteAtBottom,
      cursor: this.squareAt(this.cursor.x, this.cursor.y),
      selected: this.selected,
      targets: this.targets,
      hinted: this.hinted,
      lastMove: game.lastMove,
    };
  }

  /** Full-color half-block board: needs the piece assets and a sane size. */
  private hicolorEnabled(cellW: number, cellH: number): boolean {
    if (this.forceArt || cellW < 4 || cellH < 2) return false;
    if (this.hicolorOk === null) {
      try {
        loadPieces();
        this.hicolorOk = true;
      } catch {
        this.hicolorOk = false;
      }
    }
    return this.hicolorOk;
  }

  private boardHicolorLines(cellW: number, cellH: number): string[] {
    const cellLines = renderBoardText(this.imageState(), 8 * cellW, 16 * cellH);
    const midRow = Math.floor((cellH - 1) / 2);
    const lines: string[] = [];
    for (let dr = 0; dr < 8; dr++) {
      for (let sub = 0; sub < cellH; sub++) {
        const label =
          sub === midRow
            ? this.theme.fg("dim", `${this.squareAt(0, 7 - dr).slice(1)} `)
            : " ".repeat(LABEL_COLS);
        lines.push(label + cellLines[dr * cellH + sub]);
      }
    }
    // File labels, centered under each file
    let files = " ".repeat(LABEL_COLS);
    for (let dx = 0; dx < 8; dx++) {
      files += this.centerIn(this.squareAt(dx, 0).slice(0, 1), cellW);
    }
    lines.push(this.theme.fg("dim", files));
    return lines;
  }

  /** Big cells render pixel-art pieces; small ones fall back to the glyph. */
  private useArt(cellW: number, cellH: number): boolean {
    return cellH >= 3 && cellW >= 6;
  }

  private cell(
    dx: number,
    dy: number,
    cellW: number,
    cellH: number,
    subRow: number,
  ): string {
    const game = this.game;
    const square = this.squareAt(dx, dy);
    const piece = game?.pieceAt(square);
    const isDark = (this.fileOf(square) + this.rankOf(square)) % 2 === 0;
    const last = game?.lastMove;
    const isLastMove =
      last !== null &&
      last !== undefined &&
      (last.from === square || last.to === square);
    const isSelected = this.selected === square;
    const isTarget = this.targets.includes(square);
    const isHinted = this.hinted === square;
    const isCursor = this.cursor.x === dx && this.cursor.y === dy;

    const sqBg = isCursor
      ? CURSOR_BG
      : isSelected
        ? 33
        : isHinted
          ? 136
          : isTarget && piece
            ? 88
            : isLastMove
              ? this.lastMoveSquare
              : isDark
                ? this.darkSquare
                : this.lightSquare;

    let inner: string;
    const midRow = Math.floor((cellH - 1) / 2);
    if (piece && this.useArt(cellW, cellH)) {
      inner = this.artRow(
        piece.type,
        piece.color === "w",
        subRow,
        cellW,
        cellH,
        sqBg,
      );
    } else if (piece && subRow === midRow) {
      const glyph = GLYPHS[piece.color][piece.type];
      const styled = piece.color === "w" ? `\x1b[1m${glyph}\x1b[22m` : glyph;
      inner = `\x1b[48;5;${sqBg}m` + this.centerIn(styled, cellW);
    } else if (isTarget && subRow === midRow) {
      inner =
        `\x1b[48;5;${sqBg}m` +
        this.centerIn(this.theme.fg("success", "·"), cellW);
    } else {
      inner = `\x1b[48;5;${sqBg}m` + " ".repeat(cellW);
    }
    inner += "\x1b[39;49m";
    return inner;
  }

  /** One terminal row of a piece sprite: half blocks, 2 art pixels per cell. */
  private artRow(
    type: string,
    white: boolean,
    subRow: number,
    cellW: number,
    cellH: number,
    sqBg: number,
  ): string {
    const art = sprite(type);
    const pxTop = art[Math.floor((subRow * 8) / cellH)];
    const pxBottom = art[Math.floor((subRow * 8 + 4) / cellH)];
    const fill = white ? 255 : 16;
    // White pieces get a dark outline; black pieces are pure silhouette.
    const outline = white ? 16 : null;
    const colorOf = (px: Px): number =>
      px === 1 ? fill : px === 2 ? (outline ?? sqBg) : sqBg;

    let out = "";
    for (let c = 0; c < cellW; c++) {
      // Center-sample: keeps sprites symmetric when down-/upscaling.
      const col = Math.floor(((2 * c + 1) * 4) / cellW);
      const top = pxTop[col];
      const bottom = pxBottom[col];
      if (top === bottom) {
        out +=
          top === 0
            ? `\x1b[48;5;${sqBg}m `
            : `\x1b[38;5;${colorOf(top)}m\x1b[48;5;${sqBg}m█`;
      } else {
        // ▀ inks the top half with fg; the bottom half shows bg.
        out += `\x1b[38;5;${colorOf(top)}m\x1b[48;5;${colorOf(bottom)}m▀`;
      }
    }
    return out;
  }

  private fileOf(square: string): number {
    return square.charCodeAt(0) - 97;
  }

  private rankOf(square: string): number {
    return square.charCodeAt(1) - 49;
  }

  /** Fit a line to exactly `width` columns: truncate, then pad. */
  private fit(line: string, width: number): string {
    const truncated =
      visibleWidth(line) > width ? truncateToWidth(line, width, "") : line;
    const padding = Math.max(0, width - visibleWidth(truncated));
    return truncated + " ".repeat(padding);
  }
}
