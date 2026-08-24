import { Plugin } from "@opencode-ai/plugin";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const OPERATIONS = [
  "create_epic",
  "create_task",
  "add_note",
  "query_epics",
  "query_open_epics",
  "query_tasks",
  "query_children",
  "list",
  "ready",
  "show",
  "start",
  "reopen",
  "close",
  "add_dependency",
  "remove_dependency",
  "dependency_tree",
  "dependency_cycle",
];

// Runtime defense in depth: catalog visibility is restricted separately by
// V2 permissions, and only the `team` agent may execute ticket_tracker.
const OWNER_AGENT = "team";

const input = {
  type: "object",
  properties: {
    operation: { type: "string", enum: OPERATIONS },
    id: { type: "string" },
    dependency: { type: "string" },
    parent: { type: "string" },
    title: { type: "string" },
    description: { type: "string" },
    lane: { type: "string" },
    note: { type: "string" },
    status: { type: "string", enum: ["open", "in_progress", "closed"] },
  },
  required: ["operation"],
  additionalProperties: false,
};

function required(value, key) {
  const result = value[key];
  if (typeof result !== "string" || result.length === 0) {
    throw new Error(
      `ticket_tracker requires '${key}' for '${value.operation}'`,
    );
  }
  return result;
}

function ticketId(value, key = "id") {
  const result = required(value, key);
  if (!/^[A-Za-z0-9._-]+$/.test(result)) {
    throw new Error(`ticket_tracker received an invalid ${key}`);
  }
  return result;
}

function argsFor(value) {
  switch (value.operation) {
    case "create_epic":
      return [
        "create",
        required(value, "title"),
        "-t",
        "epic",
        "--tags",
        "team-epic",
        "-d",
        required(value, "description"),
      ];
    case "create_task": {
      const lane = value.lane;
      if (lane !== undefined && !/^[A-Za-z0-9._-]+$/.test(lane)) {
        throw new Error("ticket_tracker received an invalid lane");
      }
      return [
        "create",
        required(value, "title"),
        "-t",
        "task",
        "--parent",
        ticketId(value, "parent"),
        "--tags",
        lane ? `team-task,${lane}` : "team-task",
        "-d",
        "See SPEC notes.",
        "--acceptance",
        "See ACCEPTANCE notes.",
      ];
    }
    case "add_note":
      return ["add-note", ticketId(value), required(value, "note")];
    case "query_epics":
      return ["query", 'select(.type == "epic")'];
    case "query_open_epics":
      return [
        "query",
        'select(.type == "epic" and (.tags // [] | index("team-epic")) and .status != "closed")',
      ];
    case "query_tasks":
      return [
        "query",
        'select(.type == "task" and (.tags // [] | index("team-task")))',
      ];
    case "query_children":
      return [
        "query",
        `select(.type == "task" and .parent == "${ticketId(value, "parent")}")`,
      ];
    case "list":
      return ["ls", `--status=${required(value, "status")}`, "-T", "team-task"];
    case "ready":
      return ["ready", "-T", "team-task"];
    case "show":
      return ["show", ticketId(value)];
    case "start":
      return ["start", ticketId(value)];
    case "reopen":
      return ["status", ticketId(value), "open"];
    case "close":
      return ["close", ticketId(value)];
    case "add_dependency":
      return ["dep", ticketId(value), ticketId(value, "dependency")];
    case "remove_dependency":
      return ["undep", ticketId(value), ticketId(value, "dependency")];
    case "dependency_tree":
      return ["dep", "tree", ticketId(value)];
    case "dependency_cycle":
      return ["dep", "cycle"];
    default:
      throw new Error(`Unsupported ticket operation: ${value.operation}`);
  }
}

export default Plugin.define({
  id: "ticket-tracker",
  setup: async (ctx) => {
    await ctx.tool.transform((tools) => {
      tools.add({
        name: "ticket_tracker",
        description:
          "Read and update the current repository's tk issue tracker without using shell commands.",
        input,
        options: { codemode: true, permission: "ticket_tracker" },
        execute: async (value, context) => {
          if (context.agent !== OWNER_AGENT) {
            throw new Error(
              `Agent '${context.agent}' cannot perform ticket operation '${value.operation}'; only '${OWNER_AGENT}' may use ticket_tracker`,
            );
          }

          const session = await ctx.session.get({
            sessionID: context.sessionID,
          });
          const { stdout, stderr } = await execFileAsync("tk", argsFor(value), {
            cwd: session.location.directory,
            timeout: 30_000,
            maxBuffer: 1024 * 1024,
          });
          const content = [stdout.trim(), stderr.trim()]
            .filter(Boolean)
            .join("\n");

          return {
            content: content || "Ticket operation completed successfully.",
            metadata: {
              operation: value.operation,
              directory: session.location.directory,
            },
          };
        },
      });
    });
  },
});
