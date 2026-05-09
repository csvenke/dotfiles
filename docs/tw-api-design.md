# `tw` — Team Workflow CLI API Design

## 1. Architecture Overview

`tw` is a Go binary that acts as a **deterministic state machine** and **command wrapper** for the team lead workflow. It does not dispatch agents; it tells the agent what to do next and handles all `tk`/`mempalace` boilerplate.

```
Agent ──bash──► tw ──exec──► tk
                │────exec──► mempalace (encapsulated)
                │────read──► ~/.local/share/team-workflow/state.json
                │────read──► mempalace.yaml (wing/room config)
                │────exec──► git (for wing detection)
                └────write──► ~/.local/share/team-workflow/state.json
```

### Design Principles

1. **State is the source of truth** — The agent never tracks `current_phase`, `wave_number`, or `current_step` in its context. `tw` owns it.
2. **Gates are enforced in code** — Invalid transitions return exit code `1` with a clear error.
3. **Structured output** — Default to JSON so the agent can parse results deterministically.
4. **Idempotent where safe** — `tw init`, `tw wave start`, `tw task start` are safe to repeat.
5. **Exit non-zero on failure** — Any error, validation failure, or unexpected state returns non-zero.
6. **All mempalace details encapsulated** — The agent never runs `mempalace` directly. `tw` handles initialization, wing detection, room resolution, and all mempalace commands.

---

## 2. State File (`~/.local/share/team-workflow/state.json`)

```json
{
  "version": 1,
  "project_dir": "/home/chsv/.config/dotfiles",
  "epic_id": "epic-a1b2",
  "phase": "WAVE_EXECUTION",
  "plan": {
    "approved": true,
    "text_path": "~/.local/share/team-workflow/plan.md",
    "approved_at": "2026-05-08T10:00:00Z"
  },
  "wave": {
    "number": 2,
    "current_step": 4,
    "started_at": "2026-05-08T11:00:00Z"
  },
  "memory_mode": "active",
  "wing": "dotfiles",
  "mempalace": {
    "wing": "dotfiles",
    "rooms": {
      "documentation": ["docs"],
      "home": ["home"],
      "nix": ["nix"],
      "scripts": ["scripts"],
      "general": []
    }
  },
  "bootstrap": {
    "base_branch": "main",
    "lint_command": "npm run lint",
    "typecheck_command": "npm run typecheck",
    "unit_test_command": "npm test",
    "integration_test_command": "none",
    "e2e_command": "none",
    "build_command": "npm run build",
    "playwright_available": false
  },
  "tasks": {
    "active": ["TASK-123"],
    "closed_this_wave": ["TASK-120"],
    "staff_review": {
      "passed": false,
      "has_blockers": null,
      "run_at": null
    }
  }
}
```

---

## 3. Global Flags

| Flag            | Default                        | Description                             |
| --------------- | ------------------------------ | --------------------------------------- |
| `--json`        | false                          | Output structured JSON for all commands |
| `--project-dir` | `$PWD`                         | Project directory (detects `.tickets/`) |
| `--state-dir`   | `~/.local/share/team-workflow` | State storage directory                 |

---

## 4. Command Reference

### 4.1 Lifecycle & Status

#### `tw status [--json]`

**Purpose:** Single source of truth for current workflow state.

**Output (text):**

```
Phase: WAVE_EXECUTION
Wave: 2
Step: 4 (Implementation)
Epic: epic-a1b2
Memory: active
Wing: dotfiles
Tasks: 1 active, 3 closed, 2 open, 0 ready
```

**Output (json):**

```json
{
  "phase": "WAVE_EXECUTION",
  "wave": 2,
  "step": 4,
  "step_name": "Implementation",
  "epic_id": "epic-a1b2",
  "memory_mode": "active",
  "wing": "dotfiles",
  "task_counts": { "active": 1, "closed": 3, "open": 2, "ready": 0 }
}
```

**Exit:** `0` always (if state exists).

---

#### `tw init --epic "<title>" -d "<desc>" [--with-memory] [--json]`

**Purpose:** Bootstrap workflow state and create epic.

**Behavior:**

1. If state file exists and has `epic_id`, return existing epic (idempotent).
2. Otherwise: `tk create "<title>" -t epic --tags team-epic -d "<desc>"`
3. Write state with `phase=PLANNING`, `epic_id=<id>`.
4. If `--with-memory` or `memory_mode` not yet set, run mempalace bootstrap (replicating `_mempalace-init`):
   - Detect wing (git worktree base name → git repo name → directory name)
   - `mempalace init --yes --no-llm <projectDir>`
   - Restore `.gitignore` if it exists
   - `mempalace mine <projectDir> --wing <wing>`
   - `mempalace compress --wing <wing>`
   - Set `memory_mode=active` on success, `degraded` on failure.
5. Read `mempalace.yaml` to cache wing/room mapping in state.

**Output (json):**

```json
{
  "epic_id": "epic-a1b2",
  "created": true,
  "phase": "PLANNING",
  "memory_mode": "active",
  "wing": "dotfiles"
}
```

**Exit:** `0` on success, `1` on `tk` failure.

---

### 4.2 Phase Management

#### `tw phase detect [--json]`

**Purpose:** Run the 4 phase-detection checks from `team-workflow-state` against current reality.

**Logic:**

1. `plan.approved` = false → `PLANNING`
2. No tasks with `team-task` tag → `ISSUE_CREATION`
3. `tk ls --status=open -T team-task` and `tk ls --status=in_progress -T team-task` both empty AND `staff_review.passed` = true → `EPIC_CLOSURE`
4. Otherwise → `WAVE_EXECUTION`

**Output (json):**

```json
{
  "detected_phase": "WAVE_EXECUTION",
  "current_phase": "WAVE_EXECUTION",
  "aligned": true
}
```

**Exit:** `0` if aligned, `1` if detected phase differs from stored phase (with warning).

---

#### `tw phase advance [--to <phase>] [--json]`

**Purpose:** Validate transition gates and advance phase.

**Gates:**
| Transition | Validation |
|---|---|
| `PLANNING → ISSUE_CREATION` | `plan.approved == true` |
| `ISSUE_CREATION → WAVE_EXECUTION` | At least 1 task with `team-task` tag |
| `WAVE_EXECUTION → EPIC_CLOSURE` | All tasks closed + `staff_review.passed == true` |
| `EPIC_CLOSURE → COMPLETE` | `tk show <epic_id>` status = `closed` |

**Behavior:** If `--to` omitted, advances to the natural next phase. Validates gate. Updates state.

**Output (json):**

```json
{ "from": "PLANNING", "to": "ISSUE_CREATION", "success": true }
```

**Exit:** `0` on success, `1` if gate fails.

---

### 4.3 Planning

#### `tw plan draft --file <path> [--json]`

**Purpose:** Record plan markdown location.

**Behavior:** Copies/records path in state. Does not validate content.

**Exit:** `0`

---

#### `tw plan approve [--json]`

**Purpose:** Gate check before entering `ISSUE_CREATION`.

**Behavior:**

1. Verify `plan.text_path` exists and is non-empty.
2. Set `plan.approved = true`, `plan.approved_at = now()`.
3. **Does NOT auto-advance phase** — agent must still call `tw phase advance`.

**Exit:** `0` if plan exists, `1` if no plan draft recorded.

---

### 4.4 Task Management

#### `tw task create "<title>" --tags <lane> [-d "<desc>"] [--acceptance "<text>"] [--json]`

**Purpose:** Create workflow task under current epic.

**Behavior:**

- Wraps: `tk create "<title>" -t task --parent <epic_id> --tags team-task,<lane> -d "<desc>" --acceptance "<text>"`
- Auto-parents to current epic.
- Enforces short `-d` and `--acceptance` (warns if > 120 chars).

**Output (json):**

```json
{ "id": "TASK-123", "title": "...", "lane": "ui", "epic_id": "epic-a1b2" }
```

**Exit:** `0` on success, `1` on `tk` failure or validation error.

---

#### `tw task note <id> --type <spec|acceptance|metadata|handoff|rework|blocked|invariants> "<text>" [--json]`

**Purpose:** Add typed note with auto-prefix.

**Behavior:**

- Prefixes text based on `--type` (e.g., `SPEC:`, `ACCEPTANCE:`, `METADATA:`).
- Wraps: `tk add-note <id> "<prefixed text>"`

**Exit:** `0` on success, `1` on `tk` failure.

---

#### `tw task list [--status=open|in_progress|closed] [--json]`

**Purpose:** List workflow tasks.

**Behavior:**

- Wraps: `tk ls --status=<status> -T team-task`
- Returns structured list.

**Output (json):**

```json
{
  "tasks": [
    {
      "id": "TASK-123",
      "title": "...",
      "status": "open",
      "tags": ["team-task", "ui"]
    }
  ]
}
```

**Exit:** `0`

---

#### `tw task ready [--json]`

**Purpose:** Find ready work, grouped by lane.

**Behavior:**

- Wraps: `tk ready -T team-task`
- Groups by lane tag (second tag after `team-task`).
- Returns sorted: fast-lane first, then by priority.

**Output (json):**

```json
{
  "ready": [
    {
      "id": "TASK-123",
      "title": "...",
      "lane": "ui",
      "parallel_safe": true,
      "areas_touched": ["src/components"]
    }
  ],
  "blocked": [
    {
      "id": "TASK-124",
      "title": "...",
      "lane": "domain-heavy",
      "reason": "dependency TASK-123"
    }
  ]
}
```

**Exit:** `0`

---

#### `tw task start <id> [--json]`

**Purpose:** Mark task active.

**Behavior:**

- `tk start <id>`
- Record in state `tasks.active[]`.

**Exit:** `0` on success, `1` if `tk` fails.

---

#### `tw task close <id> [--outcome "<text>"] [--json]`

**Purpose:** Close task with optional memory writeback.

**Behavior:**

1. `tk close <id>`
2. If `memory_mode == active`:
   - `mempalace check_duplicate` on outcome text
   - `mempalace add_drawer` with task outcome (auto-detects wing/room)
3. Remove from `tasks.active[]`, add to `tasks.closed_this_wave[]`.

**Exit:** `0` on success, `1` on `tk` failure.

---

### 4.5 Wave Execution

#### `tw wave start [--json]`

**Purpose:** Begin a new wave.

**Behavior:**

1. Increment `wave.number`.
2. Reset `wave.current_step` to `0`.
3. Set `wave.started_at`.
4. Clear `tasks.closed_this_wave`.
5. If `wave.number == 1`, run bootstrap (set `memory_mode` by probing mempalace).

**Exit:** `0` (idempotent if wave already started this turn).

---

#### `tw wave step [--json]`

**Purpose:** The core determinism command. Tells the agent exactly what step to execute.

**Behavior:**

1. Reads `wave.current_step`.
2. Evaluates entry conditions for that step:
   - Step 0: Only if `wave.number == 1`
   - Step 2: Only if ready tasks include domain-heavy or underspecified
   - Step 3: Only if ready tasks are UI tasks
   - Step 5: Only if `test_expectation` indicates heavy validation
   - Step 8: Only if all tasks closed
3. If conditions not met, auto-increment step and re-evaluate.
4. Gather context for the step (ready tasks, active tasks, etc.).
5. **Does NOT execute the step** — only reports what the agent should do.

**Output (json) for Step 4:**

```json
{
  "wave": 2,
  "step": 4,
  "step_name": "Implementation",
  "skip": false,
  "ready_tasks": [
    {
      "id": "TASK-123",
      "title": "Add auth modal",
      "lane": "ui",
      "status": "open",
      "parallel_safe": true,
      "areas_touched": ["src/components/AuthModal.tsx"],
      "notes": ["SPEC: ...", "ACCEPTANCE: ..."]
    }
  ],
  "active_tasks": [],
  "instructions": "Dispatch software-engineer for ready tasks. Include <global_rules> and <task_brief> with repo bootstrap, invariant brief, memory context, and UX notes when present.",
  "next_agent_hint": "software-engineer"
}
```

**Output (json) for Step 8:**

```json
{
  "wave": 2,
  "step": 8,
  "step_name": "Staff Review",
  "skip": false,
  "instructions": "Run staff-engineer review. Review surface: git diff <base_branch>.",
  "review_surface_command": "git diff main"
}
```

**Exit:** `0` always. If no work remains, outputs `{"done": true, "next_phase": "EPIC_CLOSURE"}`.

---

#### `tw wave next [--json]`

**Purpose:** Advance step counter after agent completes current step.

**Behavior:** Increment `wave.current_step`. If step > 8, return error (should transition to closure).

**Exit:** `0` on success, `1` if no wave in progress.

---

#### `tw wave summary [--json]`

**Purpose:** Standardized wave summary.

**Behavior:**

- Queries `tk` for task statuses.
- Outputs the exact table format from `team-workflow-state`.

**Output (text):**

```
## Wave 2 Complete

| Task   | Status  | Last Agent        | Outcome            |
|--------|---------|-------------------|--------------------|
| TASK-123 | closed  | software-engineer | Auth modal implemented |

- Phase: WAVE_EXECUTION
- Memory: active
- Tasks closed this wave: 1
- Tasks in progress: 0
- Tasks ready: 0
- Next: Step 8 Staff Review
```

**Exit:** `0`

---

### 4.6 Memory Integration (Encapsulated)

`tw` handles all mempalace details. The agent never runs `mempalace` directly.

#### `tw memory init [--json]`

**Purpose:** Explicit mempalace bootstrap (replicates `_mempalace-init`).

**Behavior:**

1. Detect wing (git worktree base name → git repo name → directory name).
2. `mempalace init --yes --no-llm <projectDir>`.
3. Restore `.gitignore` if it exists.
4. `mempalace mine <projectDir> --wing <wing>`.
5. `mempalace compress --wing <wing>`.
6. Update state with `memory_mode=active`, `wing=<wing>`, and cached room mapping.

**Exit:** `0` on success, `1` on failure.

---

#### `tw memory status [--json]`

**Purpose:** Check mempalace health for current project.

**Behavior:**

1. Verify `mempalace.yaml` exists.
2. Check if palace DB is accessible.
3. Report wing, room count, last mine time.

**Output (json):**

```json
{
  "available": true,
  "wing": "dotfiles",
  "rooms": 6,
  "drawers": 142,
  "last_mine": "2026-05-08T09:00:00Z",
  "compressed": true
}
```

**Exit:** `0`

---

#### `tw memory mine [--json]`

**Purpose:** Re-mine current project directory.

**Behavior:** `mempalace mine <projectDir> --wing <wing>` + `mempalace compress --wing <wing>`.

**Exit:** `0`

---

#### `tw memory prime --task <id> [--context "<text>"] [--json]`

**Purpose:** Build `<memory_context>` block for worker prompts.

**Behavior:**

1. Auto-detects wing from state (cached from `mempalace.yaml` or git detection).
2. Auto-selects room based on task `areas_touched` metadata:
   - Parse task metadata for `areas_touched` paths.
   - Match against `mempalace.yaml` room keywords.
   - Use best-match room, or `general` fallback.
3. `mempalace search "<task_id> <task_title>" --wing <wing> --room <room>` (limit 5).
4. `mempalace kg_query <task_id>` and `mempalace kg_query <epic_id>`.
5. Build compact XML block.

**Output (text):**

```
<memory_context>
  <search>
    - Drawer abc-123: "auth modal previous attempt..."
  </search>
  <kg>
    - auth-modal → risk_history → "previous rework on validation"
  </kg>
</memory_context>
```

**Exit:** `0` (returns empty block if `memory_mode=degraded`).

---

#### `tw memory writeback --task <id> --content "<text>" [--room <room>] [--kg <subject> <predicate> <object>] [--json]`

**Purpose:** Durable memory capture on task events.

**Behavior:**

1. Auto-detects wing from state.
2. Uses `--room` if provided, otherwise infers from task metadata (as above).
3. `mempalace check_duplicate "<text>"`.
4. If not duplicate: `mempalace add_drawer wing=<wing> room=<room> content="<text>"`.
5. Optional: `mempalace kg_add subject=<s> predicate=<p> object=<o>`.

**Exit:** `0` on success, `1` on mempalace error.

---

#### `tw memory retrospective --outcome "<text>" [--policy "<text>"] [--json]`

**Purpose:** Epic-level retrospective.

**Behavior:**

1. `mempalace add_drawer wing=opencode room=team-retros content="<text>"`.
2. If policy given: `mempalace kg_add subject=<pattern_type> predicate=policy object=<policy>`.
3. Auto-create tunnel to project wing using cached wing name.

**Exit:** `0`

---

#### `tw memory diary --agent <role> --entry "<text>" [--json]`

**Purpose:** Worker diary entry.

**Behavior:** Wraps `mempalace diary_write agent_name=<role> entry="<text>"`.

**Exit:** `0`

---

### 4.7 Staff Review

#### `tw review staff --result <pass|fail> [--has-blockers] [--blockers "<text>"] [--json]`

**Purpose:** Record staff review result.

**Behavior:**

- If `pass`: Set `staff_review.passed = true`, `has_blockers = false`.
- If `fail` + `--has-blockers`: Set `has_blockers = true`, store blockers text.
- Creates follow-up tasks under same epic if blockers found.

**Exit:** `0` on pass, `0` on fail with blockers recorded, `1` on invalid state.

---

### 4.8 Todos

#### `tw todo sync [--json]`

**Purpose:** Auto-create standard todos for current phase/wave.

**Behavior:** Based on `team-workflow-state` spec, creates/updates todo list in state.

**Exit:** `0`

---

#### `tw todo list [--json]`

**Purpose:** List todos.

**Exit:** `0`

---

#### `tw todo set <id> <in_progress|completed|cancelled> [--json]`

**Purpose:** Update todo status.

**Exit:** `0`

---

### 4.9 Epic Closure

#### `tw epic close [--json]`

**Purpose:** Close epic.

**Gates:**

- All tasks closed.
- `staff_review.passed == true`.

**Behavior:**

1. `tk close <epic_id>`
2. Final memory writeback (if active).
3. Set phase to `COMPLETE`.

**Exit:** `0` on success, `1` if gates fail.

---

## 5. Workflow Integration Map

### PLANNING Phase

| Skill Action               | `tw` Command                           |
| -------------------------- | -------------------------------------- |
| Load `team-workflow-state` | `tw phase detect`                      |
| Draft plan                 | `tw plan draft --file plan.md`         |
| Present plan to user       | (Agent outputs markdown directly)      |
| User approves              | `tw plan approve`                      |
| Advance phase              | `tw phase advance --to ISSUE_CREATION` |

### ISSUE_CREATION Phase

| Skill Action                       | `tw` Command                                                   |
| ---------------------------------- | -------------------------------------------------------------- |
| Create epic                        | `tw init --epic "Title" -d "Desc"`                             |
| Create tasks                       | `tw task create "Title" --tags ui -d "..." --acceptance "..."` |
| Add SPEC/ACCEPTANCE/METADATA notes | `tw task note <id> --type spec "..."`                          |
| Advance phase                      | `tw phase advance --to WAVE_EXECUTION`                         |

### WAVE_EXECUTION Phase

| Step | Skill Action         | `tw` Command                                    |
| ---- | -------------------- | ----------------------------------------------- |
| 0    | Repo bootstrap       | `tw wave start` (auto-runs bootstrap on wave 1) |
| 1    | Find ready work      | `tw wave step` → reports ready tasks            |
| 2    | Domain brief         | `tw wave step` → reports if needed              |
| 3    | UX design            | `tw wave step` → reports if UI tasks present    |
| 4    | Implementation       | `tw task start <id>` + dispatch agent           |
| 5    | Validation           | `tw wave step` → reports if needed              |
| 6    | QA                   | `tw wave step` → reports ready for QA           |
| 7    | Wave summary         | `tw wave summary` + `tw wave next`              |
| 8    | Staff review         | `tw wave step` → reports review needed          |
|      | Record review result | `tw review staff --result pass`                 |

### EPIC_CLOSURE Phase

| Skill Action     | `tw` Command                              |
| ---------------- | ----------------------------------------- |
| Memory writeback | `tw memory retrospective --outcome "..."` |
| Pattern mining   | `tw memory writeback --kg ...`            |
| Close epic       | `tw epic close`                           |

---

## 6. Error Handling & Determinism

| Scenario                                  | Behavior                                                          | Exit Code        |
| ----------------------------------------- | ----------------------------------------------------------------- | ---------------- |
| `tk` command fails                        | Propagate stderr, exit non-zero                                   | `1`              |
| Invalid phase transition                  | Print gate failure, exit non-zero                                 | `1`              |
| Missing state file                        | Print "No workflow initialized. Run `tw init`."                   | `1`              |
| `mempalace` binary not found              | Set `memory_mode=degraded`, warn to stderr, continue              | `0` with warning |
| `mempalace init` fails                    | Return error, do not advance state                                | `1`              |
| `mempalace.yaml` missing                  | Use git-based wing detection, warn                                | `0` with warning |
| `mempalace search` returns no results     | Return empty `<memory_context>`                                   | `0`              |
| `mempalace add_drawer` duplicate detected | Skip write, log to stderr                                         | `0` with info    |
| No ready tasks in step 1                  | `tw wave step` returns `skip: true`, auto-advances                | `0`              |
| Staff review blockers                     | `tw review staff --result fail --has-blockers` creates follow-ups | `0`              |

---

## 7. Nix Packaging

**Location:** `nix/tools/tw/package.nix`

```nix
{ lib, buildGoModule }:

buildGoModule rec {
  pname = "tw";
  version = "0.1.0";

  src = ./.;  # Go source co-located: nix/tools/tw/main.go, go.mod, etc.

  vendorHash = lib.fakeHash;  # To be set after `vendorHash` computation

  meta = {
    description = "Team workflow CLI for AI agent orchestration";
    mainProgram = "tw";
  };
}
```

**Source layout:**

```
nix/tools/tw/
├── package.nix
├── go.mod
├── main.go
├── cmd/
│   ├── status.go
│   ├── init.go
│   ├── phase.go
│   ├── plan.go
│   ├── task.go
│   ├── wave.go
│   ├── memory.go
│   ├── review.go
│   ├── todo.go
│   └── epic.go
├── internal/
│   ├── state/      # State file I/O
│   ├── tk/         # tk command wrapper
│   ├── mempalace/  # mempalace command wrapper + bootstrap
│   └── workflow/   # Phase detection, step logic, gates
└── README.md
```

**Flake integration:** `lib.packagesFromDirectoryRecursive` will auto-discover `tw` and include it in `homePackages`.

---

## 8. Design Decisions

| Decision                                        | Rationale                                                                                                                                     |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Agent still dispatches `task` tool directly** | The CLI should not wrap agent dispatch; it would add indirection without value. The CLI tracks _that_ a dispatch happened (for state).        |
| **State stored in JSON file**                   | Survives across agent turns; agent doesn't need to hold it in context.                                                                        |
| **`tw wave step` auto-detects next step**       | Reduces step-tracking pressure. Agent calls `tw wave step` repeatedly instead of manually incrementing step counters.                         |
| **Idempotent init/start**                       | Safe to re-run if agent loses track of whether it already ran.                                                                                |
| **Mempalace ops fully encapsulated**            | `tw` replicates `_mempalace-init`, handles wing/room detection, and wraps all mempalace commands. Agent never needs to know mempalace exists. |
| **No caching**                                  | Every command runs fresh `tk`/`mempalace` queries. Eliminates stale data risk.                                                                |
| **No config overrides**                         | No `config.yaml`. All behavior derived from `mempalace.yaml`, git metadata, and `state.json`.                                                 |
