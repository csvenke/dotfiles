# pi-chess-puzzles

Solve [lichess](https://lichess.org) chess puzzles in a TUI overlay while pi's
agents work. The overlay opens automatically ~1.5s after an agent run starts
(so quick replies never flash it) and closes when the run settles.

## Keys

| Key           | Action                             |
| ------------- | ---------------------------------- |
| arrows / hjkl | move cursor                        |
| enter / space | select piece, confirm move         |
| H             | hint (highlight the piece to move) |
| n / N         | next puzzle / skip                 |
| q / esc       | close the overlay                  |
| q/r/b/n       | while promoting: pick the piece    |

A wrong move fails the puzzle (lichess rules) and shows the solution; any
checkmating move is accepted. Session stats (solved/failed/streak) are in the
header.

## Display modes

- **Terminal images** (kitty protocol — ghostty, kitty; not WezTerm/iTerm2):
  the board is a real image with the MIT-licensed "fantasy" piece set (see
  `assets/LICENSE-fantasy`; regenerate with `scripts/fetch-pieces.sh`).
  **tmux works too** when the outer terminal speaks kitty and tmux has
  `allow-passthrough on` (tmux ≥ 3.3): the outer clients are probed via
  `tmux list-clients`, pi-tui's kitty caps are force-enabled, and sequences
  are wrapped in a DCS `tmux;` passthrough. Requires the pi-tui DCS patch in
  the nix overlay (`patches/pi-tui-dcs-width.patch`) so wrapped lines measure
  zero-width; without it the probe fails and the fallback kicks in. Caveats:
  tmux doesn't track the image, so a pane resize or client reattach can leave
  a stale/vanished image until the next keypress re-render, and aspect may be
  slightly off (cell pixel size falls back to pi-tui's 9×18 default).
- **Hi-color text** (default elsewhere, e.g. Alacritty): the same composed
  board downsampled into full-color half-block cells (`▀`) — real shaded
  pieces, no image protocol needed.
- **1-bit pixel art** (assets unavailable): CC0 silhouette sprites by
  crmaykish (<https://github.com/crmaykish/chess_sprites_1bit>) with an
  auto-computed outline.
- **Single glyphs** on very small boards.

Force image mode off with `PI_IMAGE_PROTOCOL=none`; force it on under tmux
with `PI_IMAGE_PROTOCOL=kitty` (pi's own override).

## Commands

- `/chess` — open/close the puzzle overlay manually.
- `/chess-auto` — toggle auto-open during agent runs (session-scoped).

Auto-open is skipped (not postponed) while the editor has text, so typing a
follow-up is never interrupted; use `/chess` in that case. Closing the
overlay (esc/q or `/chess`) during a run dismisses it for the rest of that
run — auto-retries won't reopen it — and the next run starts fresh.
A half-solved puzzle is kept and resumed on the next open; only finished
puzzles advance the queue.

## Puzzles

Fetched anonymously from `https://lichess.org/api/puzzle/next` (~60/hour per
IP rate limit) with a small prefetch queue and a 60s cooldown after failures.
When the network is unavailable, a small bundled set
(`src/fallback-puzzles.ts`, real API responses) is used — regenerate it by
fetching fresh puzzles and pasting the JSON array.

## Install

Built from this local source tree by the dotfiles Nix overlay
(`nix/overlays/pi-coding-agent/default.nix` → `mkLocalPiExtension` in
`utils.nix`), which vendors runtime deps via `importNpmLock` and adds
`--extension <store-path>` to the pi wrapper — the same mechanism as the
external (published) extensions.

Once this package is published to npm, switch it to the published-package
path: move the entry into the `mkPiExtension` list in `default.nix` with the
registry tarball hash, and regenerate the lock here with
`npm install --package-lock-only`.

Keep the `@earendil-works/pi-coding-agent` / `@earendil-works/pi-tui`
devDependencies in sync with the pinned pi version in `default.nix`
(`pi-pinned`).

## Development

```sh
npm ci
npm run check     # tsc --noEmit
npm test          # unit tests (node --test)
npm run test:e2e  # drives the real wrapped pi in tmux (needs network + auth)
```

These run by hand or via `npm`; the Nix build only vendors and installs the
extension (running the test suite as a flake check would require the dev
dependency tree).

Dev deps are never vendored into the Nix store output (`--omit=dev`).

Note: the local `node_modules/@earendil-works/pi-tui/dist/utils.js` is
patched by hand with the same DCS fix as
`../patches/pi-tui-dcs-width.patch` (re-apply after every `npm ci`) — the
tmux tests in `test/imagebackend-tmux.test.ts` gate on it.
