import { Array as Arr, Option, pipe, Result, Schema } from "effect";
import type { ToolRenderers } from "@earendil-works/pi-coding-agent";
import { Container, Text } from "@earendil-works/pi-tui";

// Types derived from the public renderer signatures (Theme itself is not exported).
export type RenderCallFn = NonNullable<ToolRenderers["renderCall"]>;
type RenderResultFn = NonNullable<ToolRenderers["renderResult"]>;
export type Theme = Parameters<RenderCallFn>[1];
export type RenderContext = Parameters<RenderCallFn>[2];
export type ToolResult = Parameters<RenderResultFn>[0];
export type ContentBlock = NonNullable<ToolResult["content"]>[number];

/**
 * A tool-specific tidy: builds renderers that wrap pi's native ones.
 * Registered per tool name in the index.ts registry.
 */
export type TidyStrategy = (
  next: () => ToolRenderers | undefined,
) => ToolRenderers;

// Content extraction

/** Text payloads of a result's content blocks (v4 filterMap consumes Results). */
export const textBlocks = (
  content: ReadonlyArray<ContentBlock>,
): ReadonlyArray<string> =>
  Arr.filterMap(content, (c) =>
    c.type === "text" && "text" in c
      ? Result.succeed(c.text as string)
      : Result.failVoid,
  );

export function outputText(result: ToolResult): string {
  return pipe(result?.content ?? [], textBlocks, Arr.join("\n"));
}

export function lineCount(text: string): number {
  const t = text.trim();
  return t ? t.split("\n").length : 0;
}

/** Clamp `text` to `max` chars, ending with an ellipsis when cut. */
export const truncate =
  (max: number) =>
  (text: string): string =>
    text.length > max ? `${text.slice(0, max - 3)}...` : text;

// Decoding

/** Decode one optional field of an untyped tool payload. */
export const decodeProp =
  <S extends Schema.Codec<any>, K extends keyof S["Type"]>(schema: S, key: K) =>
  (value: unknown): Option.Option<NonNullable<S["Type"][K]>> =>
    pipe(
      Schema.decodeUnknownOption(schema)(value),
      Option.flatMap((d) => Option.fromUndefinedOr(d[key])),
    );

// Component slots (reused by native renderers via context.lastComponent)

export function textSlot(context: RenderContext, text: string): Text {
  const t =
    context.lastComponent instanceof Text
      ? context.lastComponent
      : new Text("", 0, 0);
  t.setText(text);
  return t;
}

export function containerSlot(
  context: RenderContext,
  lines: ReadonlyArray<string>,
): Container {
  const c =
    context.lastComponent instanceof Container
      ? context.lastComponent
      : new Container();
  c.clear();
  if (lines.length > 0) c.addChild(new Text(lines.join("\n"), 0, 0));
  return c;
}

// Error preview

const ERROR_PREVIEW_LINES = 8;

/** Truncation notice when `lines` exceeds the preview, else nothing. */
const overflowLine = (lines: ReadonlyArray<string>): ReadonlyArray<string> =>
  lines.length > ERROR_PREVIEW_LINES
    ? [
        `... (${lines.length - ERROR_PREVIEW_LINES} more lines, ctrl+o to expand)`,
      ]
    : [];

export function errorLines(output: string, theme: Theme): string[] {
  const lines = output.trim().split("\n");
  return pipe(
    [...Arr.take(lines, ERROR_PREVIEW_LINES), ...overflowLine(lines)],
    Arr.map((l) => theme.fg("error", l)),
  );
}

/** Default one-line summary for tools with no special case ("N lines" / "no output"). */
export function defaultSummary(result: ToolResult, theme: Theme): string {
  const n = lineCount(outputText(result));
  return theme.fg("muted", n ? `${n} lines` : "no output");
}
