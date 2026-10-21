/**
 * Shared skeleton for the compact tools (read, bash, edit, write): collapsed,
 * successful results render a one-line summary; errors show a short preview;
 * streaming renders delegate to pi's native renderers, and expanded (ctrl+o)
 * renders delegate too unless a tool provides `expandedLines`.
 *
 * The protocol (interval clearing, delegation, error detection, slot choice)
 * lives only here — tool files in tools/ supply just their variation points.
 */

import {
  containerSlot,
  defaultSummary,
  errorLines,
  outputText,
  textSlot,
} from "./shared.ts";
import type { ToolRenderers } from "@earendil-works/pi-coding-agent";
import type {
  RenderContext,
  Theme,
  TidyStrategy,
  ToolResult,
} from "./shared.ts";

export interface CompactTidyConfig {
  /** One-line summary for a collapsed, successful result (default: "N lines"). */
  readonly summary?: (
    result: ToolResult,
    context: RenderContext,
    theme: Theme,
  ) => string;
  /** Collapsed call line; the builder renders it in a Text slot and still
   * delegates to native when expanded. */
  readonly callLine?: (args: unknown, theme: Theme) => string;
  /**
   * Settled expanded-result lines, rendered ourselves in an unpadded
   * containerSlot instead of delegating to native. When set, the expanded
   * call also stays the flat callLine. Expanded errors and streaming
   * (isPartial) still delegate to native.
   */
  readonly expandedLines?: (
    result: ToolResult,
    theme: Theme,
  ) => ReadonlyArray<string>;
  /** Component shape native renderers reuse via context.lastComponent. */
  readonly slot?: "text" | "container";
}

/**
 * Clear native bash's 1s streaming elapsed-time interval: when the settled
 * render goes to us, native never clears it. state is internal host
 * bookkeeping, not external data, so the cast stays.
 */
function clearNativeInterval(context: RenderContext): void {
  const state = context.state as { interval?: NodeJS.Timeout };
  if (state.interval) {
    clearInterval(state.interval);
    state.interval = undefined;
  }
}

export const makeCompactTidy =
  (config: CompactTidyConfig): TidyStrategy =>
  (next): ToolRenderers => {
    const native = next();
    // Annotate: ?? would union the 3-arg and 2-arg signatures, and calling a
    // union synthesizes intersection parameter types.
    const summary: NonNullable<CompactTidyConfig["summary"]> =
      config.summary ??
      ((result, _context, theme) => defaultSummary(result, theme));
    const callLine = config.callLine;
    const expandedLines = config.expandedLines;
    return {
      renderCall: callLine
        ? (args, theme, context) => {
            if (context.expanded && !expandedLines && native?.renderCall)
              return native.renderCall(args, theme, context);
            return textSlot(context, callLine(args, theme));
          }
        : native?.renderCall,
      renderResult(result, options, theme, context) {
        clearNativeInterval(context);
        if (options.isPartial && native?.renderResult)
          return native.renderResult(result, options, theme, context);
        const output = outputText(result);
        const failed = context.isError || output.startsWith("Error");
        if (options.expanded) {
          if (expandedLines && !failed)
            return containerSlot(context, expandedLines(result, theme));
          if (native?.renderResult)
            return native.renderResult(result, options, theme, context);
        }
        const lines = failed
          ? errorLines(output, theme)
          : [summary(result, context, theme)];
        return config.slot === "text"
          ? textSlot(context, lines.join("\n"))
          : containerSlot(context, lines);
      },
    };
  };
