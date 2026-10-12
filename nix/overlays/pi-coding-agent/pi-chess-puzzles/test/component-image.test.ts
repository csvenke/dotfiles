import assert from "node:assert/strict";
import test from "node:test";
import { visibleWidth } from "@earendil-works/pi-tui";
import {
  PuzzleBoardComponent,
  emptyStats,
  type SessionStats,
} from "../src/component.ts";
import type { ImageBackend } from "../src/imagebackend.ts";
import { PuzzleSource } from "../src/lichess.ts";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import { parsePuzzle, type LichessPuzzleResponse } from "../src/puzzle.ts";

const ANSI = /\x1b\[[0-9;]*m/g;
const strip = (s: string) => s.replace(ANSI, "");
const FAKE_SEQ = "\x1b_GFAKE\x1b\\";

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

class FakeBackend implements ImageBackend {
  renderCalls: { maxWidthCells: number; maxHeightCells: number }[] = [];
  private readonly opts: {
    supported?: boolean;
    anchor?: "first" | "last";
    rows?: number;
    fail?: boolean;
  };
  constructor(
    opts: {
      supported?: boolean;
      anchor?: "first" | "last";
      rows?: number;
      fail?: boolean;
    } = {},
  ) {
    this.opts = opts;
  }
  supported() {
    return this.opts.supported ?? true;
  }
  dispose(): string | null {
    return null;
  }
  cellDims() {
    return { widthPx: 9, heightPx: 18 };
  }
  render(
    _base64: string,
    _dims: { widthPx: number; heightPx: number },
    opts: { maxWidthCells: number; maxHeightCells: number },
  ) {
    if (this.opts.fail) return null;
    this.renderCalls.push(opts);
    const rows = this.opts.rows ?? Math.ceil(opts.maxWidthCells / 2);
    return { sequence: FAKE_SEQ, rows, anchor: this.opts.anchor ?? "first" };
  }
}

function makeSource(ids: string[]): PuzzleSource {
  let i = 0;
  const fetcher = async (): Promise<LichessPuzzleResponse> => {
    const raw = fallbackPuzzles.find(
      (p) => p.puzzle.id === ids[i % ids.length],
    );
    assert.ok(raw);
    i++;
    return raw;
  };
  return new PuzzleSource({ fetcher, prefetchCount: 1 });
}

async function makeImageComponent(
  ids: string[],
  backend: ImageBackend,
  stats: SessionStats = emptyStats(),
) {
  const component = new PuzzleBoardComponent(
    new FakeTui(),
    fakeTheme,
    () => {},
    makeSource(ids),
    stats,
    null,
    backend,
  );
  await component.whenIdle();
  return component;
}

function withRows<T>(rows: number, fn: () => T): T {
  const saved = Object.getOwnPropertyDescriptor(process.stdout, "rows");
  Object.defineProperty(process.stdout, "rows", {
    value: rows,
    configurable: true,
  });
  try {
    return fn();
  } finally {
    if (saved) Object.defineProperty(process.stdout, "rows", saved);
    else delete (process.stdout as { rows?: number }).rows;
  }
}

test("image path renders the sequence, labels, and an aligned frame", async () => {
  const whiteRaw = fallbackPuzzles.find(
    (p) => parsePuzzle(p).color === "white",
  );
  assert.ok(whiteRaw, "need a white-to-move fixture");
  const backend = new FakeBackend();
  const component = await makeImageComponent([whiteRaw.puzzle.id], backend);
  withRows(0, () => {
    const lines = component.render(90);
    // C = floor((90-4-2)/8)*8 = 80 → rows = 40
    // lines: frame 2 + header 1 + sep 1 + image 40 + files 1 + status+info 2 + footer 1 = 48
    assert.equal(lines.length, 48);
    assert.ok(backend.renderCalls.length > 0);
    assert.equal(backend.renderCalls[0].maxWidthCells, 80);
    const raw = lines.join("\n");
    assert.ok(raw.includes(FAKE_SEQ), "kitty sequence emitted");
    // rank labels 8..1 inside the frame
    const labels = lines
      .map((l) => strip(l).match(/│ (\d) /)?.[1])
      .filter((v): v is string => v !== undefined);
    assert.deepEqual(labels, ["8", "7", "6", "5", "4", "3", "2", "1"]);
    // file labels a..h on one line
    assert.ok(
      lines.some((l) => strip(l).includes("a") && strip(l).includes("h")),
    );
    // frame alignment (VS15-safe metric)
    const trimmed = lines.map((l) => strip(l).trimEnd());
    const widths = new Set(trimmed.map((l) => visibleWidth(l)));
    assert.equal(widths.size, 1, "all frame lines share one width");
  });
});

test("image path height-caps C to fit the terminal", async () => {
  const backend = new FakeBackend();
  const component = await makeImageComponent(["fxiw1"], backend);
  withRows(30, () => {
    // maxImageRows = floor(28.5)-10 = 18 → C: 80→…→32 (ceil(32*9/18)=16 ≤ 18)
    component.render(90);
    assert.equal(backend.renderCalls.at(-1)?.maxWidthCells, 32);
  });
});

test("iterm2 anchors the sequence on the last line with a cursor-up prefix", async () => {
  const backend = new FakeBackend({ anchor: "last", rows: 10 });
  const component = await makeImageComponent(["fxiw1"], backend);
  withRows(0, () => {
    const lines = component.render(90);
    const idx = lines.findIndex((l) => l.includes(FAKE_SEQ));
    assert.ok(idx > 3, `sequence late in the card (line ${idx})`);
    assert.ok(
      lines[idx].includes("\x1b[9A"),
      "cursor-up prefix before the sequence",
    );
  });
});

test("unsupported or failing backend falls back to hicolor text", async () => {
  const unsupported = await makeImageComponent(
    ["fxiw1"],
    new FakeBackend({ supported: false }),
  );
  withRows(0, () => {
    const raw = unsupported.render(90).join("\n");
    assert.ok(raw.includes("▀"), "art mode when unsupported");
    assert.ok(!raw.includes(FAKE_SEQ));
  });
  const failing = await makeImageComponent(
    ["fxiw1"],
    new FakeBackend({ fail: true }),
  );
  withRows(0, () => {
    const raw = failing.render(90).join("\n");
    assert.ok(raw.includes("▀"), "art mode when render fails");
    assert.ok(!raw.includes(FAKE_SEQ));
  });
});

test("cursor moves recompose the image (cache keyed on version)", async () => {
  const backend = new FakeBackend();
  const component = await makeImageComponent(["fxiw1"], backend);
  withRows(0, () => {
    component.render(90);
    const first = backend.renderCalls.length;
    component.render(90); // cached: same version
    assert.equal(backend.renderCalls.length, first);
    component.handleInput("l"); // bump version → recompose
    component.render(90);
    assert.equal(backend.renderCalls.length, first + 1);
  });
});

test("every rank label appears for all image heights 8..20", async () => {
  const whiteRaw = fallbackPuzzles.find(
    (p) => parsePuzzle(p).color === "white",
  );
  assert.ok(whiteRaw);
  for (let rows = 8; rows <= 20; rows++) {
    const backend = new FakeBackend({ rows });
    const component = await makeImageComponent([whiteRaw.puzzle.id], backend);
    withRows(0, () => {
      const labels = component
        .render(90)
        .map((l) => strip(l).match(/│ (\d) /)?.[1])
        .filter((v): v is string => v !== undefined);
      assert.deepEqual(
        labels,
        ["8", "7", "6", "5", "4", "3", "2", "1"],
        `rows=${rows}: all rank labels present`,
      );
    });
  }
});

test("dispose writes the backend's image cleanup sequence to stdout", async () => {
  const CLEANUP = "\x1b_Ga=d,d=I,i=1,q=2\x1b\\";
  const backend = new FakeBackend();
  backend.dispose = () => CLEANUP;
  const component = await makeImageComponent(["fxiw1"], backend);
  const written: string[] = [];
  const saved = process.stdout.write.bind(process.stdout);
  process.stdout.write = ((chunk: string) => {
    written.push(chunk);
    return true;
  }) as typeof process.stdout.write;
  try {
    component.dispose();
  } finally {
    process.stdout.write = saved;
  }
  assert.deepEqual(written, [CLEANUP]);
  // Null cleanup (no image rendered) writes nothing.
  const plain = await makeImageComponent(["fxiw1"], new FakeBackend());
  process.stdout.write = ((chunk: string) => {
    written.push(chunk);
    return true;
  }) as typeof process.stdout.write;
  try {
    plain.dispose();
  } finally {
    process.stdout.write = saved;
  }
  assert.deepEqual(written, [CLEANUP], "no additional write");
});
