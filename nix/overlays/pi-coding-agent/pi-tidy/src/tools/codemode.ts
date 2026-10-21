import { Array as Arr, Match, Option, pipe, Result, Schema } from "effect";
import {
  containerSlot,
  decodeProp,
  errorLines,
  lineCount,
  textBlocks,
  truncate,
  type Theme,
  type TidyStrategy,
  type ToolResult,
} from "../shared.ts";

const CODEMODE_CALL_PREVIEW = 8;
const CALL_ARGS_CHARS = 80;

const SCRIPT_HEADER =
  /^Script (completed|failed)\nWall time [\d.]+ seconds\nOutput:\n$/;

const CodemodeArgs = Schema.Struct({
  code: Schema.optional(Schema.String),
});

const CodemodeCall = Schema.Struct({
  name: Schema.String,
  args: Schema.optional(Schema.String),
  status: Schema.Literals(["running", "ok", "error", "cancelled"]),
  durationMs: Schema.optional(Schema.Finite),
  cost: Schema.optional(Schema.Finite),
});
type CodemodeCall = typeof CodemodeCall.Type;

const CodemodeDetails = Schema.Struct({
  calls: Schema.optional(Schema.Array(CodemodeCall)),
});

function scriptOutput(result: ToolResult): string {
  const content = result?.content ?? [];
  const [first, ...rest] = content;
  const body =
    first?.type === "text" && "text" in first && SCRIPT_HEADER.test(first.text)
      ? rest
      : content;
  return pipe(body, textBlocks, Arr.join("\n")).trim();
}

function formatDuration(ms: number): string {
  return ms < 1000 ? `${Math.round(ms)}ms` : `${(ms / 1000).toFixed(1)}s`;
}

function formatCost(cost: number): string {
  return `$${cost >= 0.01 ? cost.toFixed(2) : cost.toPrecision(2)}`;
}

const statusIcon = (status: CodemodeCall["status"], theme: Theme): string =>
  Match.value(status).pipe(
    Match.when("ok", () => theme.fg("success", "✓")),
    Match.when("error", () => theme.fg("error", "✗")),
    Match.when("running", () => theme.fg("warning", "…")),
    Match.when("cancelled", () => theme.fg("muted", "⊘")),
    Match.exhaustive,
  );

/** Keep the values of present Options. */
const someValues = (
  options: ReadonlyArray<Option.Option<string>>,
): ReadonlyArray<string> =>
  Arr.filterMap(
    options,
    Option.match({
      onNone: () => Result.failVoid,
      onSome: (s) => Result.succeed(s),
    }),
  );

const truncateArgs = truncate(CALL_ARGS_CHARS);

/** One nested tool call → one preview line. */
function callLine(call: CodemodeCall, theme: Theme): string {
  return pipe(
    [
      Option.some(
        `${statusIcon(call.status, theme)} ${theme.fg("toolTitle", call.name)}`,
      ),
      pipe(
        Option.fromUndefinedOr(call.args),
        Option.filter((a) => a.length > 0),
        Option.map((a) => theme.fg("muted", truncateArgs(a))),
      ),
      pipe(
        Option.fromUndefinedOr(call.durationMs),
        Option.map((ms) => theme.fg("dim", formatDuration(ms))),
      ),
      pipe(
        Option.fromUndefinedOr(call.cost),
        Option.filter((c) => c !== 0),
        Option.map((c) => theme.fg("dim", formatCost(c))),
      ),
    ],
    someValues,
    Arr.join(" "),
  );
}

/** Notice for calls hidden above the preview window. */
const earlierCallsLine = (
  hidden: number,
  theme: Theme,
): Option.Option<string> =>
  hidden > 0
    ? Option.some(
        theme.fg("muted", `... (${hidden} earlier calls, ctrl+o to expand)`),
      )
    : Option.none();

/** Total over priced model calls, shown only when more than one has a cost. */
const modelCostLine = (
  calls: ReadonlyArray<CodemodeCall>,
  theme: Theme,
): Option.Option<string> => {
  const priced = Arr.filterMap(calls, (c) =>
    c.cost ? Result.succeed(c.cost) : Result.failVoid,
  );
  return priced.length > 1
    ? Option.some(
        theme.fg(
          "muted",
          `Model calls: ${formatCost(Arr.reduce(priced, 0, (sum, c) => sum + c))}`,
        ),
      )
    : Option.none();
};

function codemodeCallLines(
  calls: ReadonlyArray<CodemodeCall>,
  theme: Theme,
): ReadonlyArray<string> {
  const shown = calls.slice(-CODEMODE_CALL_PREVIEW);
  return pipe(
    [
      earlierCallsLine(calls.length - shown.length, theme),
      ...Arr.map(shown, (call) => Option.some(callLine(call, theme))),
      modelCostLine(calls, theme),
    ],
    someValues,
  );
}

/** First meaningful `//` comment in the script, as a dim hint. */
const codemodeHint = (args: unknown, theme: Theme): string =>
  pipe(
    decodeProp(CodemodeArgs, "code")(args),
    Option.flatMap((code) =>
      pipe(
        code.split("\n"),
        Arr.map((l) => l.trim()),
        Arr.findFirst(
          (l) => l.startsWith("//") && !l.startsWith("// @options"),
        ),
      ),
    ),
    Option.map((c) =>
      theme.fg("dim", ` ${c.replace(/^\/\/+\s?/, "").slice(0, 80)}`),
    ),
    Option.getOrElse(() => ""),
  );

/** Error preview, or a one-line pointer to the hidden script output. */
const outputTail = (
  isError: boolean,
  output: string,
  theme: Theme,
): ReadonlyArray<string> =>
  output === ""
    ? []
    : isError
      ? errorLines(output, theme)
      : [
          theme.fg(
            "dim",
            `→ ${lineCount(output)} lines of output (ctrl+o to expand)`,
          ),
        ];

export const codemodeTidy: TidyStrategy = (next) => {
  const native = next();
  return {
    renderCall(args, theme, context) {
      if (context.expanded && native?.renderCall)
        return native.renderCall(args, theme, context);
      return containerSlot(context, [
        `${theme.fg("toolTitle", theme.bold("codemode"))}${codemodeHint(args, theme)}`,
      ]);
    },
    renderResult(result, options, theme, context) {
      if ((options.expanded || options.isPartial) && native?.renderResult)
        return native.renderResult(result, options, theme, context);
      const calls = pipe(
        decodeProp(CodemodeDetails, "calls")(result.details),
        Option.getOrElse((): ReadonlyArray<CodemodeCall> => []),
      );
      return containerSlot(context, [
        ...codemodeCallLines(calls, theme),
        ...outputTail(context.isError, scriptOutput(result), theme),
      ]);
    },
  };
};
