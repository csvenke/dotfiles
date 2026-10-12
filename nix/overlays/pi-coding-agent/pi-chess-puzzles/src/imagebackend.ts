/**
 * Bridge to pi-tui's terminal image support (kitty / iterm2). Returns null
 * render results on any failure so the caller can fall back to pixel art.
 *
 * tmux: pi-tui's auto-detection disables images whenever $TMUX is set, but
 * kitty graphics still work when the outer terminal speaks kitty (ghostty,
 * kitty) and tmux has `allow-passthrough on` — sequences wrapped in a DCS
 * "tmux;" passthrough are forwarded to the outer terminal verbatim. The
 * outer terminals are probed via `tmux list-clients`; PI_IMAGE_PROTOCOL
 * (=kitty / =none) overrides the probe either way. Wrapped lines only
 * measure correctly (zero-width) when pi-tui strips DCS sequences, so
 * support is gated on that too (see utils.ts patch in the nix overlay).
 */

import { execSync } from "node:child_process";
import {
  allocateImageId,
  deleteKittyImage,
  getCapabilities,
  getCellDimensions,
  renderImage,
  setCapabilityOverrides,
  visibleWidth,
} from "@earendil-works/pi-tui";

export interface ImageBackend {
  /** True when the terminal can display images and cell sizes are known. */
  supported(): boolean;
  cellDims(): { widthPx: number; heightPx: number };
  /**
   * Render a base64 PNG. Returns the escape sequence, the number of terminal
   * rows the image occupies, and which line the sequence anchors to
   * ("first" for kitty, "last" for iterm2).
   */
  render(
    base64Png: string,
    dims: { widthPx: number; heightPx: number },
    opts: { maxWidthCells: number; maxHeightCells: number },
  ): { sequence: string; rows: number; anchor: "first" | "last" } | null;
  /**
   * Escape sequence deleting the rendered image (frees the transmission),
   * or null when nothing was rendered. Idempotent.
   */
  dispose(): string | null;
}

/** Terminal names known to speak the kitty graphics protocol. */
export function termnameSpeaksKitty(termname: string): boolean {
  const t = termname.toLowerCase();
  return t.includes("ghostty") || t.includes("kitty");
}

/** Wrap a sequence so tmux passes it verbatim to the outer terminal. */
export function tmuxPassthrough(sequence: string): string {
  return `\x1bPtmux;${sequence.replaceAll("\x1b", "\x1b\x1b")}\x1b\\`;
}

/** Termnames of every terminal attached to this tmux server. */
function tmuxClientTermnames(): string[] {
  try {
    const out = execSync("tmux list-clients -F '#{client_termname}'", {
      encoding: "utf8",
      timeout: 250,
      stdio: ["ignore", "pipe", "ignore"],
    });
    return out
      .split("\n")
      .map((s) => s.trim())
      .filter(Boolean);
  } catch {
    return [];
  }
}

/**
 * pi-tui only strips CSI/OSC/APC when measuring line width; DCS support was
 * added via the nix overlay patch. Without it a tmux-wrapped sequence counts
 * as visible columns and breaks the overlay frame — stay on the fallback.
 */
function dcsMeasuresZero(): boolean {
  return visibleWidth(tmuxPassthrough("\x1b_Gq=2;\x1b\\")) === 0;
}

export function createImageBackend(): ImageBackend {
  let supported: boolean | null = null;
  let imageId: number | undefined;
  const inTmux = !!process.env.TMUX;

  // Under tmux pi-tui reports images:null; decide ourselves by probing the
  // outer clients. PI_IMAGE_PROTOCOL=kitty|none wins over the probe.
  const tmuxKittyOk = (): boolean => {
    const forced = (process.env.PI_IMAGE_PROTOCOL ?? "").toLowerCase();
    if (forced === "none" || forced === "0") return false;
    if (forced !== "kitty" && !tmuxClientTermnames().some(termnameSpeaksKitty))
      return false;
    if (!dcsMeasuresZero()) return false;
    setCapabilityOverrides({ images: "kitty" });
    return true;
  };

  return {
    supported() {
      if (supported === null) {
        try {
          if (inTmux && !tmuxKittyOk()) {
            supported = false;
          } else {
            const caps = getCapabilities();
            const dims = getCellDimensions();
            // Only kitty for now: WezTerm erases image cells when later rows
            // are written over them (pi-tui works around this with
            // draw-images-last, which an overlay component can't do), and
            // iTerm2's inline-image cursor semantics break the frame math.
            // Both get pixel art instead.
            const termProgram = (process.env.TERM_PROGRAM ?? "").toLowerCase();
            const isWezTerm =
              termProgram === "wezterm" || !!process.env.WEZTERM_PANE;
            supported =
              caps.images === "kitty" &&
              !isWezTerm &&
              dims.widthPx > 0 &&
              dims.heightPx > 0;
          }
        } catch {
          supported = false;
        }
      }
      return supported;
    },
    cellDims() {
      return getCellDimensions();
    },
    render(base64Png, dims, opts) {
      try {
        const protocol = getCapabilities().images;
        if (protocol !== "kitty") return null;
        if (imageId === undefined) {
          imageId = allocateImageId();
        }
        const result = renderImage(base64Png, dims, {
          maxWidthCells: opts.maxWidthCells,
          maxHeightCells: opts.maxHeightCells,
          imageId,
          moveCursor: false,
        });
        if (!result) return null;
        return {
          sequence: inTmux ? tmuxPassthrough(result.sequence) : result.sequence,
          rows: result.rows,
          anchor: "first", // kitty only (see supported()); iterm2 disabled
        };
      } catch {
        return null;
      }
    },
    dispose() {
      if (imageId === undefined) return null;
      const id = imageId;
      imageId = undefined;
      const seq = deleteKittyImage(id);
      return inTmux ? tmuxPassthrough(seq) : seq;
    },
  };
}
