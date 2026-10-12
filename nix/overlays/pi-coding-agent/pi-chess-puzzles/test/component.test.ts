import assert from "node:assert/strict";
import test from "node:test";
import { visibleWidth } from "@earendil-works/pi-tui";
import {
  PuzzleBoardComponent,
  emptyStats,
  type SessionStats,
} from "../src/component.ts";
import { PuzzleSource } from "../src/lichess.ts";
import { PuzzleGame } from "../src/game.ts";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import {
  parsePuzzle,
  type LichessPuzzleResponse,
  type PuzzleData,
} from "../src/puzzle.ts";

const ANSI = /\x1b\[[0-9;]*m/g;
const strip = (s: string) => s.replace(ANSI, "");

class FakeTui {
  renders = 0;
  requestRender() {
    this.renders++;
  }
}

const fakeTheme = {
  appearance: "dark" as const,
  fg: (_token: string, text: string) => text,
};

function makeSource(ids: string[]): PuzzleSource {
  let i = 0;
  const fetcher = async (): Promise<LichessPuzzleResponse> => {
    const raw = fallbackPuzzles.find(
      (p) => p.puzzle.id === ids[i % ids.length],
    );
    assert.ok(raw, `fixture ${ids[i % ids.length]} missing`);
    i++;
    return raw;
  };
  return new PuzzleSource({ fetcher, prefetchCount: 1 });
}

async function makeComponent(
  ids: string[],
  stats: SessionStats = emptyStats(),
) {
  const tui = new FakeTui();
  let closed = false;
  const component = new PuzzleBoardComponent(
    tui,
    fakeTheme,
    () => (closed = true),
    makeSource(ids),
    stats,
  );
  await component.whenIdle();
  return { component, tui, stats, isClosed: () => closed };
}

/** Force the 1-bit pixel-art path (skips hicolor + images). */
async function makeArtComponent(
  ids: string[],
  stats: SessionStats = emptyStats(),
) {
  const tui = new FakeTui();
  let closed = false;
  const component = new PuzzleBoardComponent(
    tui,
    fakeTheme,
    () => (closed = true),
    makeSource(ids),
    stats,
    null,
    null,
    true,
  );
  await component.whenIdle();
  return { component, tui, stats, isClosed: () => closed };
}

function puzzleOf(ids: string[]): PuzzleData {
  const raw = fallbackPuzzles.find((p) => p.puzzle.id === ids[0]);
  assert.ok(raw);
  return parsePuzzle(raw);
}

test("renders within the given width at various sizes", async () => {
  const { component } = await makeComponent(["fxiw1"]);
  for (const width of [80, 40, 26]) {
    component.invalidate();
    for (const line of component.render(width)) {
      // exact fit: fit() truncates and pads to the width
      assert.equal(
        visibleWidth(line),
        width,
        `line fits width ${width} exactly: "${strip(line)}"`,
      );
    }
  }
});

test("renders a notice when the terminal is too narrow", async () => {
  const { component } = await makeComponent(["fxiw1"]);
  const lines = component.render(20);
  assert.equal(lines.length, 1);
  assert.ok(strip(lines[0]).length <= 20);
  assert.match(strip(lines[0]), /chess/);
});

test("caches render output until state changes", async () => {
  const { component, tui } = await makeComponent(["fxiw1"]);
  const first = component.render(60);
  const second = component.render(60);
  assert.equal(first, second, "same array instance when nothing changed");
  component.handleInput("l"); // move cursor
  assert.ok(tui.renders > 0);
  const third = component.render(60);
  assert.notEqual(first, third);
});

test("full solve via selectSquare updates stats and message", async () => {
  const { component, stats } = await makeComponent(["fxiw1"]);
  const puzzle = puzzleOf(["fxiw1"]);
  const [from, to] = [
    puzzle.solution[0].slice(0, 2),
    puzzle.solution[0].slice(2, 4),
  ];
  component.selectSquare(from);
  component.selectSquare(to);
  assert.equal(stats.solved, 1);
  assert.equal(stats.streak, 1);
  const text = component.render(60).map(strip).join("\n");
  assert.match(text, /Solved!/);
  assert.match(text, /1✓/);
});

test("failed move reports the expected move in SAN", async () => {
  const { component, stats } = await makeComponent(["afPQd"]);
  const puzzle = puzzleOf(["afPQd"]);
  // Find a legal but wrong first move by probing candidates.
  const from = puzzle.solution[0].slice(0, 2);
  // Move the correct piece to a wrong (but legal) square: use its second legal target.
  const game = (
    component as never as { game: { legalTargets(s: string): string[] } }
  ).game;
  const targets = game.legalTargets(from);
  const wrongTo = targets.find((sq) => sq !== puzzle.solution[0].slice(2, 4));
  assert.ok(wrongTo);
  component.selectSquare(from);
  component.selectSquare(wrongTo);
  assert.equal(stats.failed, 1);
  const text = component.render(80).map(strip).join("\n");
  assert.match(text, /was the move/);
});

test("promotion prompts for the piece and completes the puzzle", async () => {
  const { component } = await makeComponent(["afPQd"]);
  const puzzle = puzzleOf(["afPQd"]);
  // Play all user moves up to the promotion
  const promoIndex = puzzle.solution.findIndex((m) => m.length === 5);
  for (let i = 0; i < promoIndex; i += 2) {
    const uci = puzzle.solution[i];
    component.selectSquare(uci.slice(0, 2));
    component.selectSquare(uci.slice(2, 4));
  }
  const uci = puzzle.solution[promoIndex];
  component.selectSquare(uci.slice(0, 2));
  component.selectSquare(uci.slice(2, 4));
  // Not applied yet: waiting for the promotion choice
  let text = component.render(60).map(strip).join("\n");
  assert.match(text, /Promote/);
  component.handleInput(uci[4]); // the solution's promotion piece
  text = component.render(60).map(strip).join("\n");
  assert.match(text, /Solved!/);
});

test("escape during a pending promotion cancels the promotion, not the overlay", async () => {
  const { component, isClosed } = await makeComponent(["afPQd"]);
  const puzzle = puzzleOf(["afPQd"]);
  const promoIndex = puzzle.solution.findIndex((m) => m.length === 5);
  for (let i = 0; i < promoIndex; i += 2) {
    const uci = puzzle.solution[i];
    component.selectSquare(uci.slice(0, 2));
    component.selectSquare(uci.slice(2, 4));
  }
  const uci = puzzle.solution[promoIndex];
  component.selectSquare(uci.slice(0, 2));
  component.selectSquare(uci.slice(2, 4));
  component.handleInput("\x1b"); // escape
  assert.equal(isClosed(), false);
  // the move was not played: still playing, no pending prompt in render
  assert.doesNotMatch(component.render(60).map(strip).join("\n"), /Promote/);
});

test("escape closes the overlay", async () => {
  const { component, isClosed } = await makeComponent(["fxiw1"]);
  component.handleInput("\x1b");
  assert.equal(isClosed(), true);
});

test("q closes the overlay when no promotion is pending", async () => {
  const { component, isClosed } = await makeComponent(["fxiw1"]);
  component.handleInput("q");
  assert.equal(isClosed(), true);
});

test("N skips to the next puzzle", async () => {
  const { component } = await makeComponent(["fxiw1", "MLU82"]);
  component.handleInput("n");
  await component.whenIdle();
  const game = (component as never as { game: { puzzle: PuzzleData } | null })
    .game;
  assert.equal(game?.puzzle.id, "MLU82");
});

test("dispose during an in-flight load ignores the late result", async () => {
  let resolveFetch: (raw: LichessPuzzleResponse) => void = () => {};
  const fetcher = () =>
    new Promise<LichessPuzzleResponse>((resolve) => {
      resolveFetch = resolve;
    });
  const source = new PuzzleSource({ fetcher, prefetchCount: 1 });
  const tui = new FakeTui();
  const component = new PuzzleBoardComponent(
    tui,
    fakeTheme,
    () => {},
    source,
    emptyStats(),
  );
  // let the fetch chain reach the fetcher call before disposing/resolving
  await new Promise((r) => setImmediate(r));
  // fetch is pending; close the overlay before it resolves
  component.dispose();
  component.dispose();
  const raw = fallbackPuzzles.find((p) => p.puzzle.id === "fxiw1");
  assert.ok(raw);
  resolveFetch(raw);
  await component.whenIdle();
  const game = (component as never as { game: unknown }).game;
  assert.equal(game, null, "superseded load result is discarded");
});

test("N during loading is ignored (first skip wins)", async () => {
  const { component } = await makeComponent(["fxiw1", "MLU82", "i3JgW"]);
  component.handleInput("n"); // starts loading MLU82
  component.handleInput("n"); // dropped: loading in progress
  await component.whenIdle();
  const game = (component as never as { game: { puzzle: PuzzleData } | null })
    .game;
  assert.equal(game?.puzzle.id, "MLU82");
  const text = component.render(60).map(strip).join("\n");
  assert.doesNotMatch(text, /Fetching/);
});

test("hint highlight clears after the next move", async () => {
  const { component } = await makeArtComponent(["MLU82"]);
  const puzzle = puzzleOf(["MLU82"]);
  component.handleInput("j"); // move cursor off the hint square (cursor wins)
  component.handleInput("H");
  let raw = component.render(60).join("\n");
  assert.ok(raw.includes("\x1b[48;5;136m"), "hint square highlighted");
  component.selectSquare(puzzle.solution[0].slice(0, 2));
  component.selectSquare(puzzle.solution[0].slice(2, 4));
  raw = component.render(60).join("\n");
  assert.ok(!raw.includes("\x1b[48;5;136m"), "hint highlight cleared");
});

test("a fresh puzzle shows no stale message from the previous one", async () => {
  const { component, stats } = await makeComponent(["fxiw1", "MLU82"]);
  const puzzle = puzzleOf(["fxiw1"]);
  component.selectSquare(puzzle.solution[0].slice(0, 2));
  component.selectSquare(puzzle.solution[0].slice(2, 4));
  assert.equal(stats.solved, 1);
  assert.match(component.render(60).map(strip).join("\n"), /Solved!/);
  component.handleInput("n");
  await component.whenIdle();
  const text = component.render(60).map(strip).join("\n");
  assert.doesNotMatch(text, /Solved!/);
  assert.match(text, /Your move/);
});

test("solves via handleInput cursor keys (clamped navigation)", async () => {
  const whiteRaw = fallbackPuzzles.find(
    (p) => parsePuzzle(p).color === "white",
  );
  assert.ok(whiteRaw);
  const { component, stats } = await makeComponent([whiteRaw.puzzle.id]);
  const puzzle = parsePuzzle(whiteRaw);

  const goto = (square: string) => {
    // clamp to a1 corner, then walk to the target: white orientation
    // maps display x = file, y = rank - 1
    for (let i = 0; i < 7; i++) component.handleInput("h");
    for (let i = 0; i < 7; i++) component.handleInput("j");
    const file = square.charCodeAt(0) - 97;
    const rank = square.charCodeAt(1) - 49;
    for (let i = 0; i < file; i++) component.handleInput("l");
    for (let i = 0; i < rank; i++) component.handleInput("k");
  };

  for (let i = 0; i < puzzle.solution.length; i += 2) {
    const uci = puzzle.solution[i];
    goto(uci.slice(0, 2));
    component.handleInput(" "); // select
    goto(uci.slice(2, 4));
    if (uci.length === 5) {
      component.handleInput(" "); // arm the promotion prompt
      component.handleInput(uci[4]);
    } else {
      component.handleInput(" "); // confirm
    }
  }
  assert.equal(stats.solved, 1);
  assert.match(component.render(60).map(strip).join("\n"), /Solved!/);
});

test("board orientation flips for black-to-move puzzles", async () => {
  const blackRaw = fallbackPuzzles.find(
    (p) => parsePuzzle(p).color === "black",
  );
  assert.ok(blackRaw, "need a black-to-move fixture");
  const { component } = await makeComponent([blackRaw.puzzle.id]);
  const text = component.render(60).map(strip);
  // rank labels appear once per rank, inside the frame on the block's
  // middle row; black orientation shows 1 at top
  const labels = text
    .map((l) => l.trim().match(/^│ (\d) /)?.[1])
    .filter((v): v is string => v !== undefined);
  assert.deepEqual(labels, ["1", "2", "3", "4", "5", "6", "7", "8"]);
});

test("white-to-move puzzles render ranks 8 to 1", async () => {
  const whiteRaw = fallbackPuzzles.find(
    (p) => parsePuzzle(p).color === "white",
  );
  assert.ok(whiteRaw, "need a white-to-move fixture");
  const { component } = await makeComponent([whiteRaw.puzzle.id]);
  const text = component.render(60).map(strip);
  const labels = text
    .map((l) => l.trim().match(/^│ (\d) /)?.[1])
    .filter((v): v is string => v !== undefined);
  assert.deepEqual(labels, ["8", "7", "6", "5", "4", "3", "2", "1"]);
});

test("board scales to fill the width, keeping squares square", async () => {
  const { component } = await makeComponent(["fxiw1"]);
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: 0,
    configurable: true,
  });
  try {
    // width 90, no height cap: cellW = floor((90-2-4-2)/8) = 10, cellH = 5
    // lines: frame 2 + header 1 + sep 1 + board 8*5=40 + files 1 + status+info 2 + footer 1 = 48
    const lines = component.render(90);
    assert.equal(lines.length, 48);
    for (const line of lines) {
      assert.equal(visibleWidth(line), 90);
    }
    // frame hugs the board: frameW = 2+8*10+4 = 86, plus 2 cols left padding
    // (visibleWidth: glyphs carry a zero-width VS15)
    const trimmed = lines.map((l) => strip(l).trimEnd());
    const widths = new Set(trimmed.map((l) => visibleWidth(l)));
    assert.deepEqual([...widths], [88], "all frame lines share one width");
    for (const l of trimmed) {
      assert.match(l, /[╮┤╯│]$/u, `right edge aligned: "${l.slice(-12)}"`);
    }
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
});

test("board height is capped so the card fits the terminal", async () => {
  const { component } = await makeComponent(["fxiw1"]);
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: 30,
    configurable: true,
  });
  try {
    // rows 30: maxBoardRows = floor(28.5)-8-2 = 18 → cellH 2 → cellW 4
    // lines: frame 2 + header 1 + sep 1 + board 16 + files 1 + status+info 2 + footer 1 = 24
    const lines = component.render(90);
    assert.equal(lines.length, 24);
    // but the frame widens for the footer text instead of truncating it
    const text = lines.map(strip).join("\n");
    assert.match(text, /esc close/);
    // and all frame lines stay aligned when the frame is text-driven
    const trimmed = lines.map((l) => strip(l).trimEnd());
    const widths = new Set(trimmed.map((l) => visibleWidth(l)));
    assert.equal(widths.size, 1, "frame lines share one width");
    for (const l of trimmed) {
      assert.match(l, /[╮┤╯│]$/u);
    }
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
});

test("big cells render pixel-art pieces (half blocks)", async () => {
  const { component } = await makeArtComponent(["fxiw1"]);
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: 0,
    configurable: true,
  });
  try {
    // width 90 → cellW 10, cellH 5: art mode
    const raw = component.render(90).join("\n");
    assert.match(raw, /▀/, "half-block art rendered");
    assert.match(raw, /\x1b\[38;5;255m/, "white piece fill");
    assert.match(raw, /\x1b\[38;5;16m/, "black piece fill / outline");
    // alignment holds with art (visibleWidth, VS15-safe metric)
    const trimmed = component.render(90).map((l) => strip(l).trimEnd());
    const widths = new Set(trimmed.map((l) => visibleWidth(l)));
    assert.equal(widths.size, 1);
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
});

test("small cells fall back to single glyphs", async () => {
  const { component } = await makeArtComponent(["fxiw1"]);
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: 24,
    configurable: true,
  });
  try {
    // rows 24: maxBoardRows = floor(22.8)-8-2 = 12 → capH 1 → cellW 2: glyph mode
    const raw = component.render(90).join("\n");
    assert.doesNotMatch(raw, /▀/);
    assert.match(raw, /♟/, "glyph fallback rendered");
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
});

test("cursor uses a background highlight, never reverse video", async () => {
  const { component } = await makeArtComponent(["fxiw1"]);
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: 0,
    configurable: true,
  });
  try {
    // initial cursor sits on the first solution's from-square (a piece)
    const raw = component.render(90).join("\n");
    assert.doesNotMatch(raw, /\x1b\[7m/, "no reverse video anywhere");
    assert.match(raw, /\x1b\[48;5;25m/, "cursor background present");
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
});

test("art stays aligned at the minimum art cell size (cellW 6)", async () => {
  const { component } = await makeArtComponent(["fxiw1"]);
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: 38,
    configurable: true,
  });
  try {
    // rows 38: maxBoardRows = floor(36.1)-8-2 = 26 → capH 3 → cellW 6
    const lines = component.render(90);
    const raw = lines.join("\n");
    assert.match(raw, /▀/, "art mode still active at cellW 6");
    const trimmed = lines.map((l) => strip(l).trimEnd());
    const widths = new Set(trimmed.map((l) => visibleWidth(l)));
    assert.equal(widths.size, 1, "frame lines share one width");
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
});

test("shows offline notice when the source fell back to bundled puzzles", async () => {
  const tui = new FakeTui();
  const source = new PuzzleSource({
    fetcher: async () => {
      throw new Error("offline");
    },
  });
  const component = new PuzzleBoardComponent(
    tui,
    fakeTheme,
    () => {},
    source,
    emptyStats(),
  );
  await component.whenIdle();
  const text = component.render(80).map(strip).join("\n");
  assert.match(text, /offline/);
});

test("a resumeGame renders immediately without fetching", async () => {
  const puzzle = puzzleOf(["MLU82"]);
  const game = new PuzzleGame(puzzle);
  const uci = puzzle.solution[0];
  game.tryMove(uci.slice(0, 2), uci.slice(2, 4)); // one correct move in

  let fetched = false;
  const source = new PuzzleSource({
    fetcher: async (): Promise<LichessPuzzleResponse> => {
      fetched = true;
      throw new Error("must not fetch when resuming");
    },
  });
  const component = new PuzzleBoardComponent(
    new FakeTui(),
    fakeTheme,
    () => {},
    source,
    emptyStats(),
    game,
  );
  await component.whenIdle();
  assert.equal(fetched, false);
  assert.equal(component.activeGame?.puzzle.id, "MLU82");
  const text = component.render(80).map(strip).join("\n");
  assert.match(text, /Your move \(white\) 2\/3/);
});

test("a finished resumeGame is not resumed", async () => {
  const puzzle = puzzleOf(["fxiw1"]);
  const game = new PuzzleGame(puzzle);
  const uci = puzzle.solution[0];
  game.tryMove(uci.slice(0, 2), uci.slice(2, 4)); // solved
  const component = new PuzzleBoardComponent(
    new FakeTui(),
    fakeTheme,
    () => {},
    makeSource(["MLU82"]),
    emptyStats(),
    game,
  );
  await component.whenIdle();
  assert.equal(component.activeGame?.puzzle.id, "MLU82", "fresh puzzle loaded");
});
