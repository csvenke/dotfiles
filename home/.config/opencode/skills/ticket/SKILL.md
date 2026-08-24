---
name: ticket
description: "Command reference and workflow conventions for the tk issue tracker. Use before any tracker operation."
---

# Issue Tracker (tk)

`tk` is the source of truth for workflow tickets. Only the `team` agent may call the
typed `ticket_tracker` tool; the tool is hidden from and rejects every other agent as
defense in depth. Never invoke `tk` through shell. Any `tk` command syntax in another
workflow document is semantic shorthand for the equivalent `ticket_tracker` operation
below, performed by `team` alone. Workers never call `ticket_tracker` or `tk`; they
receive a `ticket_context` in their dispatch prompt and return `ticket_notes` in their
handoff for `team` to persist.

## Operations

### Create

- Epic: `create_epic` with `title` and a short `description`
- Task: `create_task` with `title`, `parent`, and optional `lane`
- Team workflow tasks automatically receive the `team-task` tag and placeholder
  description/acceptance; put details in separate notes.

### Query

- `query_epics`: all epics
- `query_open_epics`: open `team-epic` tickets
- `query_tasks`: all `team-task` tickets
- `query_children` with `parent`: tasks under one epic
- `list` with `status=open|in_progress|closed`: workflow tasks by status
- `ready`: ready workflow tasks
- `show` with `id`: one ticket

### Update

- `start` with `id`: set a task to `in_progress`
- `reopen` with `id`: return a ticket to `open`
- `add_note` with `id` and `note`: append a durable note
- `close` with `id`: close a ticket

The team lead starts active tasks and is the only role that closes tickets. QA never
closes; it returns `READY_TO_CLOSE` and `team` performs the actual close after
verifying acceptance and mechanical gates.

### Dependencies

- `add_dependency` with `id` and `dependency`
- `remove_dependency` with `id` and `dependency`
- `dependency_tree` with `id`
- `dependency_cycle`

## Team Workflow Recipe

Group adjacent operations in one Code Mode `execute` call. Keep one nested
`ticket_tracker` call per operation, await writes sequentially, and capture each
returned ticket ID before the next dependent call. Only independent reads may use
`Promise.all`:

1. `create_epic` with the approved plan title and a short description.
2. `create_task` for each task using the returned epic ID as `parent`.
3. Add separate notes with `add_note`:
   - `SPEC: <what to change, why, and where to start>`
   - `ACCEPTANCE: <verifiable acceptance criteria>`
   - `METADATA: risk=<low|medium|high>; test_expectation=<none|targeted|regression|e2e>; areas_touched=<paths>; parallel_safe=<true|false>`
   - Optional `MEMORY:` and `REVERSAL_CONFIRMATION:` notes when applicable.
4. Add real ordering constraints with `add_dependency` only when needed.
5. Start active work with `start` before the first implementation dispatch.

Lane names should be concise: `ui`, `domain-heavy`, `validation`, `fast-lane`,
`server-tests`, or a subsystem tag.

## Acceptance Criteria

Every criterion must name an observable behavior and how QA verifies it. Reject
criteria such as "works correctly", "handles errors", or "code is clean". State
whether coverage is targeted, regression, or E2E when tests are expected.

## Recovery

Classify every tracker failure before deciding whether to retry:

- **Pre-exec failure** (schema validation, missing required field, or the
  `team`-only authorization check rejects the call before `tk` ever runs): this is
  definitely non-mutating. Fix the input and retry once.
- **Post-launch failure** (the `tk` process was invoked and then errored, timed
  out, or the transport itself failed): the outcome is **ambiguous** — `tk` may
  have partially applied the mutation before failing. Never blindly retry a
  post-launch failure; a blind retry can create a duplicate epic/task, double-apply
  a note, or double-toggle a dependency.

### Reconciling an ambiguous post-launch failure

Before retrying, prove what actually happened by reading live tracker state — never
infer it from the error text alone, and never adopt a pre-existing ticket just
because its title matches:

- `add_note`: run `show` on the ticket and check whether the exact note text is
  already present. Present → do not retry. Absent → retry once.
- `start` / `reopen` / `close`: run `show` and check `status` directly. Already in
  the target status → do not retry. Not yet → retry once.
- `add_dependency` / `remove_dependency`: run `dependency_tree` (or `show`) and
  check whether the dependency edge is already present/absent as intended. Matches
  intended end state → do not retry. Does not → retry once.

#### `create_epic` / `create_task`: baseline-diff correlation

A same-title ticket can already exist for unrelated reasons before you ever call
`create_epic`/`create_task`. Title matching alone can silently adopt someone else's
ticket, so title is never sufficient identity by itself. Correlate against a
**captured baseline**, not the live set alone:

1. **Before issuing the create**, capture a baseline: run `query_epics` (for an
   epic create) or `query_tasks`/`query_children` with the intended `parent` (for a
   task create), record the full set of ticket IDs currently returned as
   `baseline_ids`, and note the wall-clock time immediately before the create call
   as `launch_time`.
2. Issue the create. If it fails ambiguously (post-launch), reconcile before any
   retry by building these candidate sets, in this exact order:
   - `new_ids` = re-run the same query used for the baseline; take every ID in the
     fresh result that is **absent from `baseline_ids`**.
   - `candidates` = the subset of `new_ids` matching the attempted `type`, `title`,
     and `parent`. Compute `candidates` **before** looking at any creation
     timestamp, sequence, or other creation-identity field — identity never
     narrows which tickets count as a candidate, it only decides whether a
     candidate may later be adopted.
3. Resolve using the ordered decision table below. Evaluate rows top to bottom and
   stop at the first that applies:

   | #   | Condition                                                                                                                                                                                   | Outcome                                                                                                                                                                                                                                           |
   | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | 1   | `baseline_ids` was never captured                                                                                                                                                           | **Uncorrelatable.** Stop, do not retry, do not adopt, ask the user.                                                                                                                                                                               |
   | 2   | `candidates` is empty (zero members)                                                                                                                                                        | The create is proven absent from the baseline. Retry once — no more than one retry.                                                                                                                                                               |
   | 3   | `candidates` has exactly one member, and that ticket's own creation identity (timestamp, sequence, or equivalent field the tracker exposes) proves it was created at or after `launch_time` | Adopt that ticket's ID. Do not retry.                                                                                                                                                                                                             |
   | 4   | `candidates` has exactly one member, but the tracker exposes no creation-identity field for it, or that field does not prove creation at or after `launch_time`                             | **Uncorrelatable.** A single type/title/parent match with no valid creation-identity proof is not adoptable — a candidate without proven identity is exactly as uncertain as multiple candidates. Stop, do not retry, do not adopt, ask the user. |
   | 5   | `candidates` has two or more members                                                                                                                                                        | **Uncorrelatable.** Stop, do not retry, do not adopt, ask the user.                                                                                                                                                                               |

   A candidate reaches row 3 only by carrying its own proof of creation time; the
   absence of that proof always falls through to row 4, never back to row 2's
   retry branch — row 2 is reserved exclusively for an empty `candidates` set.

Retry (for any operation) only when the reconciliation read **proves** the mutation
is absent. If the reconciliation read itself fails, or the result cannot be
correlated to a single ticket with confidence, stop issuing new operations and ask
the user rather than guessing after a second failure.
