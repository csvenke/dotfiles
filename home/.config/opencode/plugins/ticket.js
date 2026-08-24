import { Plugin } from "@opencode-ai/plugin";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const SAFE_TOKEN = /^[A-Za-z0-9._-]+$/;

/**
 * @typedef {Object} TicketInput
 * @property {string} operation - Name of the operation to perform.
 * @property {string} [id] - Ticket identifier.
 * @property {string} [dependency] - Ticket identifier for a dependency edge.
 * @property {string} [parent] - Parent ticket identifier.
 * @property {string} [title] - Title for ticket creation.
 * @property {string} [description] - Description for ticket creation.
 * @property {string} [lane] - Lane tag to append to team tasks.
 * @property {string} [note] - Note text to add to a ticket.
 * @property {"open" | "in_progress" | "closed"} [status] - Status filter.
 */

/**
 * Extract a required non-empty string field from the tool input.
 *
 * @param {TicketInput} value - Tool input object.
 * @param {string} key - Field name to extract.
 * @returns {string} The field value.
 */
function required(value, key) {
  const result = /** @type {Record<string, unknown>} */ (value)[key];
  if (typeof result !== "string" || result.length === 0) {
    throw new Error(
      `ticket_tracker requires '${key}' for '${value.operation}'`,
    );
  }
  return result;
}

/**
 * Extract a required field and validate it as a shell-safe ticket id.
 *
 * @param {TicketInput} value - Tool input object.
 * @param {string} [key="id"] - Field name holding the id.
 * @returns {string} The validated ticket id.
 */
function ticketId(value, key = "id") {
  const result = required(value, key);
  if (!SAFE_TOKEN.test(result)) {
    throw new Error(`ticket_tracker received an invalid ${key}`);
  }
  return result;
}

/**
 * Build `tk create` arguments.
 *
 * @param {string} type - Ticket type (e.g. "epic" or "task").
 * @param {string} title - Ticket title.
 * @param {string[]} extra - Additional CLI arguments.
 * @returns {string[]} Full argument list.
 */
const tkCreate = (type, title, extra) => [
  "create",
  title,
  "-t",
  type,
  ...extra,
];

/**
 * Build `tk query` arguments.
 *
 * @param {string} filter - jq filter expression.
 * @returns {string[]} Full argument list.
 */
const tkQuery = (filter) => ["query", filter];

/**
 * Build the `--tags` value for a new task, optionally appending a lane tag.
 *
 * @param {string | undefined} lane - Optional lane tag.
 * @returns {string} Comma-separated tags.
 */
function taskTags(lane) {
  if (lane === undefined) {
    return "team-task";
  }
  if (!SAFE_TOKEN.test(lane)) {
    throw new Error("ticket_tracker received an invalid lane");
  }
  return `team-task,${lane}`;
}

/**
 * Map of operation name to a builder that produces the `tk` CLI arguments.
 *
 * @type {Record<string, (v: TicketInput) => string[]>}
 */
const OPERATIONS = {
  create_epic: (v) =>
    tkCreate("epic", required(v, "title"), [
      "--tags",
      "team-epic",
      "-d",
      required(v, "description"),
    ]),
  create_task: (v) =>
    tkCreate("task", required(v, "title"), [
      "--parent",
      ticketId(v, "parent"),
      "--tags",
      taskTags(v.lane),
      "-d",
      "See SPEC notes.",
      "--acceptance",
      "See ACCEPTANCE notes.",
    ]),
  add_note: (v) => ["add-note", ticketId(v), required(v, "note")],
  query_epics: () => tkQuery('select(.type == "epic")'),
  query_open_epics: () =>
    tkQuery(
      'select(.type == "epic" and (.tags // [] | index("team-epic")) and .status != "closed")',
    ),
  query_tasks: () =>
    tkQuery('select(.type == "task" and (.tags // [] | index("team-task")))'),
  query_children: (v) =>
    tkQuery(
      `select(.type == "task" and .parent == "${ticketId(v, "parent")}")`,
    ),
  list: (v) => ["ls", `--status=${required(v, "status")}`, "-T", "team-task"],
  ready: () => ["ready", "-T", "team-task"],
  show: (v) => ["show", ticketId(v)],
  start: (v) => ["start", ticketId(v)],
  reopen: (v) => ["status", ticketId(v), "open"],
  close: (v) => ["close", ticketId(v)],
  add_dependency: (v) => ["dep", ticketId(v), ticketId(v, "dependency")],
  remove_dependency: (v) => ["undep", ticketId(v), ticketId(v, "dependency")],
  dependency_tree: (v) => ["dep", "tree", ticketId(v)],
  dependency_cycle: () => ["dep", "cycle"],
};

const OPERATION_NAMES = Object.keys(OPERATIONS);

/**
 * Resolve the tool input to the `tk` CLI argument list for its operation.
 *
 * @param {TicketInput} value - Tool input object.
 * @returns {string[]} The CLI argument list.
 */
const argsFor = (value) => {
  const operation = OPERATIONS[value.operation];

  if (typeof operation !== "function") {
    throw new Error(`Unsupported ticket operation: ${value.operation}`);
  }

  return operation(value);
};

export default Plugin.define({
  id: "local.ticket-tracker",
  setup: async (ctx) => {
    await ctx.tool.transform((tools) => {
      tools.add({
        name: "ticket_tracker",
        description:
          "Read and update the current repository's tk issue tracker without using shell commands.",
        input: {
          type: "object",
          properties: {
            operation: { type: "string", enum: OPERATION_NAMES },
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
        },
        options: { codemode: true, permission: "ticket_tracker" },
        execute: async (input, context) => {
          const value = /** @type {TicketInput} */ (input);
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
