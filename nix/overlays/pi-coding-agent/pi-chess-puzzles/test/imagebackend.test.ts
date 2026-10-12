import assert from "node:assert/strict";
import test from "node:test";
import {
  resetCapabilitiesCache,
  setCapabilities,
} from "@earendil-works/pi-tui";
import { createImageBackend } from "../src/imagebackend.ts";

function withEnv(key: string, value: string | undefined, fn: () => void) {
  const saved = process.env[key];
  if (value === undefined) delete process.env[key];
  else process.env[key] = value;
  try {
    fn();
  } finally {
    if (saved === undefined) delete process.env[key];
    else process.env[key] = saved;
  }
}

function withKittyCaps(fn: () => void) {
  setCapabilities({ images: "kitty", trueColor: true, hyperlinks: true });
  try {
    fn();
  } finally {
    resetCapabilitiesCache();
  }
}

test("supported on kitty-capable terminals", () => {
  withKittyCaps(() => {
    withEnv("TMUX", undefined, () => {
      withEnv("WEZTERM_PANE", undefined, () => {
        withEnv("TERM_PROGRAM", "ghostty", () => {
          assert.equal(createImageBackend().supported(), true);
        });
      });
    });
  });
});

test("not supported on WezTerm (kitty cells get erased by later row writes)", () => {
  withKittyCaps(() => {
    withEnv("WEZTERM_PANE", "1", () => {
      assert.equal(createImageBackend().supported(), false);
    });
  });
});

test("not supported without an image protocol", () => {
  setCapabilities({ images: null, trueColor: true, hyperlinks: false });
  try {
    assert.equal(createImageBackend().supported(), false);
  } finally {
    resetCapabilitiesCache();
  }
});

test("render returns null for non-kitty protocols (iterm2 → art fallback)", () => {
  setCapabilities({ images: "iterm2", trueColor: true, hyperlinks: true });
  try {
    const backend = createImageBackend();
    assert.equal(
      backend.render(
        "",
        { widthPx: 1, heightPx: 1 },
        { maxWidthCells: 8, maxHeightCells: 4 },
      ),
      null,
    );
  } finally {
    resetCapabilitiesCache();
  }
});
