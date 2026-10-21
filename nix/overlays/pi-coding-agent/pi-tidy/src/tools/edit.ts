import { Array as Arr, Option, pipe, Schema } from "effect";
import { makeCompactTidy } from "../compact.ts";
import {
  decodeProp,
  type RenderContext,
  type Theme,
  type TidyStrategy,
  type ToolResult,
} from "../shared.ts";

/** Native edit reads `file_path` first, then `path`. */
const EditArgs = Schema.Struct({
  file_path: Schema.optional(Schema.String),
  path: Schema.optional(Schema.String),
});

const EditDetails = Schema.Struct({
  diff: Schema.optional(Schema.String),
});

/** Collapsed edit call: path line only, in an unpadded Text like other tools. */
const editCallLine = (args: unknown, theme: Theme): string => {
  const a = pipe(
    Schema.decodeUnknownOption(EditArgs)(args),
    Option.getOrElse((): typeof EditArgs.Type => ({})),
  );
  return `${theme.fg("toolTitle", theme.bold("edit"))} ${theme.fg("accent", a.file_path ?? a.path ?? "...")}`;
};

/** Unified-diff line predicates (ignore the +++/--- file headers). */
const isAddedLine = (l: string): boolean =>
  l.startsWith("+") && !l.startsWith("+++");
const isRemovedLine = (l: string): boolean =>
  l.startsWith("-") && !l.startsWith("---");

/** Full diff for the settled expanded view: + green, - red, the rest plain. */
const colorDiffLine = (l: string, theme: Theme): string =>
  isAddedLine(l)
    ? theme.fg("success", l)
    : isRemovedLine(l)
      ? theme.fg("error", l)
      : l;

const expandedLines = (
  result: ToolResult,
  theme: Theme,
): ReadonlyArray<string> =>
  pipe(
    decodeProp(EditDetails, "diff")(result.details),
    Option.map((diff) =>
      Arr.map(diff.split("\n"), (l) => colorDiffLine(l, theme)),
    ),
    Option.getOrElse((): ReadonlyArray<string> => [
      theme.fg("muted", "no changes"),
    ]),
  );

const summary = (
  result: ToolResult,
  _context: RenderContext,
  theme: Theme,
): string =>
  pipe(
    decodeProp(EditDetails, "diff")(result.details),
    Option.match({
      onNone: () => theme.fg("muted", "no changes"),
      onSome: (diff) => {
        const lines = diff.split("\n");
        return `${theme.fg("success", `+${Arr.filter(lines, isAddedLine).length}`)} ${theme.fg("error", `-${Arr.filter(lines, isRemovedLine).length}`)}`;
      },
    }),
  );

export const editTidy: TidyStrategy = makeCompactTidy({
  summary,
  callLine: editCallLine,
  expandedLines,
});
