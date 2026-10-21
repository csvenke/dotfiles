import { Option, pipe, Schema } from "effect";
import { makeCompactTidy } from "../compact.ts";
import {
  decodeProp,
  lineCount,
  type RenderContext,
  type Theme,
  type TidyStrategy,
  type ToolResult,
} from "../shared.ts";

const WriteArgs = Schema.Struct({
  file_path: Schema.optional(Schema.String),
  path: Schema.optional(Schema.String),
  content: Schema.optional(Schema.String),
});

/** Collapsed write call: path line only (native shows a content preview). */
const writeCallLine = (args: unknown, theme: Theme): string => {
  const a = pipe(
    Schema.decodeUnknownOption(WriteArgs)(args),
    Option.getOrElse((): typeof WriteArgs.Type => ({})),
  );
  const n = pipe(
    Option.fromUndefinedOr(a.content),
    Option.map(lineCount),
    Option.getOrElse(() => 0),
  );
  return `${theme.fg("toolTitle", theme.bold("write"))} ${theme.fg("accent", a.file_path ?? a.path ?? "...")}${n ? theme.fg("dim", ` (${n} lines)`) : ""}`;
};

const summary = (
  _result: ToolResult,
  context: RenderContext,
  theme: Theme,
): string => {
  const n = pipe(
    decodeProp(WriteArgs, "content")(context.args),
    Option.map(lineCount),
    Option.getOrElse(() => 0),
  );
  return theme.fg("muted", n ? `${n} lines written` : "written");
};

export const writeTidy: TidyStrategy = makeCompactTidy({
  summary,
  callLine: writeCallLine,
});
