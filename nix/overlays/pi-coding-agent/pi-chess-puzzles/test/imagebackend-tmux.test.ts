import assert from "node:assert/strict";
import test from "node:test";
import { getCapabilities, visibleWidth } from "@earendil-works/pi-tui";
import {
  createImageBackend,
  termnameSpeaksKitty,
  tmuxPassthrough,
} from "../src/imagebackend.ts";
import { encodePng } from "../src/png.ts";

/** Minimal valid PNG (solid red 4x4) for renderImage. */
const PNG_B64 = Buffer.from(
  encodePng(
    new Uint8Array(4 * 4 * 4).fill(0xff).map((v, i) => (i % 4 === 3 ? 255 : v)),
    4,
    4,
  ),
).toString("base64");

function withEnv<T>(vars: Record<string, string | undefined>, fn: () => T): T {
  const saved = new Map<string, string | undefined>();
  for (const k of Object.keys(vars)) {
    saved.set(k, process.env[k]);
    if (vars[k] === undefined) delete process.env[k];
    else process.env[k] = vars[k];
  }
  try {
    return fn();
  } finally {
    for (const [k, v] of saved) {
      if (v === undefined) delete process.env[k];
      else process.env[k] = v;
    }
  }
}

test("tmuxPassthrough wraps with DCS and doubles inner ESC bytes", () => {
  const wrapped = tmuxPassthrough("\x1b_Ga=T;\x1b\\");
  assert.equal(wrapped, "\x1bPtmux;\x1b\x1b_Ga=T;\x1b\x1b\\\x1b\\");
  assert.ok(wrapped.startsWith("\x1bPtmux;"));
  assert.ok(wrapped.endsWith("\x1b\\"));
  // No undoubled inner ESC: every ESC after the opener is followed by ESC or \
  const inner = wrapped.slice("\x1bPtmux;".length, -2);
  for (let i = 0; i < inner.length; i++) {
    if (inner[i] === "\x1b") {
      assert.ok(
        inner[i + 1] === "\x1b" || inner[i + 1] === "\\",
        `ESC at ${i} is escaped`,
      );
      i++;
    }
  }
});

test("termnameSpeaksKitty matches ghostty/kitty only", () => {
  assert.ok(termnameSpeaksKitty("xterm-ghostty"));
  assert.ok(termnameSpeaksKitty("xterm-kitty"));
  assert.ok(!termnameSpeaksKitty("alacritty"));
  assert.ok(!termnameSpeaksKitty("foot"));
  assert.ok(!termnameSpeaksKitty("xterm-256color"));
});

test("pi-tui measures a tmux-wrapped kitty sequence as zero width", () => {
  // This is the property supported() gates on under tmux; it holds once the
  // nix overlay's pi-tui DCS patch is applied. Kept explicit so an unpatched
  // pi-tui fails loudly here instead of breaking the overlay frame.
  assert.equal(visibleWidth(tmuxPassthrough("\x1b_Gq=2;\x1b\\")), 0);
});

test("backend render/dispose are tmux-wrapped; dispose is idempotent", () => {
  withEnv({ TMUX: "/tmp/tmux-test", PI_IMAGE_PROTOCOL: "kitty" }, () => {
    const backend = createImageBackend();
    assert.equal(getCapabilities().images, "kitty");
    const res = backend.render(
      PNG_B64,
      { widthPx: 4, heightPx: 4 },
      { maxWidthCells: 8, maxHeightCells: 8 },
    );
    assert.ok(res, "render succeeds");
    assert.equal(res.anchor, "first");
    assert.ok(
      res.sequence.startsWith("\x1bPtmux;"),
      "sequence wrapped for tmux",
    );
    assert.ok(res.sequence.includes("\x1b\x1b_G"), "doubled-ESC kitty APC");
    const cleanup = backend.dispose();
    assert.ok(cleanup, "cleanup emitted after render");
    assert.ok(cleanup.startsWith("\x1bPtmux;"), "cleanup wrapped for tmux");
    assert.ok(cleanup.includes("a=d"), "kitty delete action");
    assert.equal(backend.dispose(), null, "idempotent");
  });
});

test("outside tmux the sequence is passed through unwrapped", () => {
  withEnv(
    { TMUX: undefined, PI_IMAGE_PROTOCOL: "kitty", KITTY_WINDOW_ID: "1" },
    () => {
      const backend = createImageBackend();
      const res = backend.render(
        PNG_B64,
        { widthPx: 4, heightPx: 4 },
        { maxWidthCells: 8, maxHeightCells: 8 },
      );
      assert.ok(res);
      assert.ok(res.sequence.startsWith("\x1b_G"), "raw kitty APC");
      const cleanup = backend.dispose();
      assert.ok(cleanup?.startsWith("\x1b_G"), "raw delete");
    },
  );
});

test("PI_IMAGE_PROTOCOL=none disables kitty even when forced-capable", () => {
  withEnv({ TMUX: "/tmp/tmux-test", PI_IMAGE_PROTOCOL: "none" }, () => {
    const backend = createImageBackend();
    assert.equal(backend.supported(), false);
  });
});
