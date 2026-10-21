import { Option, pipe, Schema } from "effect";
import { makeCompactTidy } from "../compact.ts";
import {
  decodeProp,
  lineCount,
  outputText,
  type RenderContext,
  type Theme,
  type TidyStrategy,
  type ToolResult,
} from "../shared.ts";

const ReadDetails = Schema.Struct({
  truncation: Schema.optional(
    Schema.Struct({ truncated: Schema.optional(Schema.Boolean) }),
  ),
});

const summary = (
  result: ToolResult,
  _context: RenderContext,
  theme: Theme,
): string => {
  if (result.content?.[0]?.type === "image") return theme.fg("muted", "image");
  const truncated = pipe(
    decodeProp(ReadDetails, "truncation")(result.details),
    Option.map((t) => t.truncated ?? false),
    Option.getOrElse(() => false),
  );
  return theme.fg(
    "muted",
    `${lineCount(outputText(result))} lines${truncated ? " (truncated)" : ""}`,
  );
};

export const readTidy: TidyStrategy = makeCompactTidy({
  summary,
  slot: "text",
});
