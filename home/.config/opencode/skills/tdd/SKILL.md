---
name: tdd
description: "Test-driven development skill. Triggers on requests to write tests, refactor for testability, add test coverage, or apply TDD practices. Guides structuring code for testability through dependency injection of only external boundaries (I/O, network, databases), writing pure input/output tests that never verify implementation details, and keeping abstractions minimal. Language-agnostic principles applied with idiomatic patterns for the target language."
---

# Test-Driven Development Skill

Guide writing tests and structuring code for testability. Focus on testing behavior, not implementation. Keep abstractions minimal. Only stub what you must.

## The Red-Green-Refactor Cycle

TDD follows a strict loop:

1. **Red** — Write a failing test that describes the behavior you want. Run it. It must fail. If it passes, the test is not testing anything new.
2. **Green** — Write the minimum code to make the test pass. Resist the urge to generalize or clean up. Just make it green.
3. **Refactor** — Clean up the implementation while keeping all tests green. Remove duplication, improve naming, simplify structure. Do not add new behavior in this step.

Repeat. Each cycle should be small — minutes, not hours. If a step feels large, break the behavior into smaller increments.

**When adding to existing code:** Start from Green. The existing tests pass. Write a new failing test (Red), make it pass (Green), then refactor.

**When fixing a bug:** Write a test that reproduces the bug (Red). Fix the bug (Green). Refactor if needed.

## Core Principles

### 1. Only Stub External Boundaries

The only things that need dependency injection and test doubles are true external boundaries:

- **Network calls** (HTTP clients, APIs, third-party services)
- **Database access**
- **Filesystem I/O** (when it's a core dependency, not incidental)
- **System interfaces** (stdin/stdout/stderr, clocks for time-sensitive logic)
- **External processes** (shell commands, subprocesses)

Everything else should be tested with real code. If a function calls another function in the same codebase, test them together. Internal logic is tested implicitly through the public API.

### 2. Test Behavior, Not Implementation

Tests answer: "given this input, do I get this output?" They never answer: "did you call this internal function?" or "did you pass this exact argument to the stub?"

**Good test structure:**

```
input → function under test → assert output or error
```

**Signs of implementation testing (avoid these):**

- Verifying a stub was called with specific arguments (that is mock behavior — avoid it)
- Asserting exact error message strings (check error type/kind/code, not message text)
- Tracking call counts (that is mock behavior — avoid it)
- Verifying internal state of objects
- Testing private/internal functions directly

### 3. Keep Abstractions Minimal

Do not create abstractions solely for testability. Every abstraction must earn its place.

**Avoid:**

- Service/manager classes that wrap a single function
- Builder/option/factory patterns when plain parameters work
- Interface/protocol/trait types duplicated across modules
- Constructor functions when a plain function call suffices
- Wrapper types that just delegate to another type

**Prefer:**

- Plain functions that take dependencies as parameters
- A single interface definition where the implementation lives — never redefine the same contract in multiple modules
- Letting the caller compose, not the library

### 4. Pure Input/Output Tests

Tests should be structured as pure data: inputs in, outputs out.

**Stub design:** Use stubs (pre-configured return values), not mocks (interaction verifiers). A stub holds the values it should return. It has no logic, conditionals, counters, or assertion capabilities. If your test double verifies how it was called, it is a mock — replace it with a stub.

**Test case design:** Each test case specifies only:

- Input values
- Stub return values (response and/or error)
- Expected output or whether an error is expected

Do not specify: exact error message strings (error type/kind is fine), expected stub call arguments, expected call order, or expected internal state.

### 5. Implicit Coverage Over Explicit Unit Tests

If a behavior is exercised by a higher-level test, don't write a separate lower-level test for it.

- If a test for the main entry point exercises parsing, validation, and formatting in its flow, you don't need separate tests for each — unless the function has complex logic with many edge cases that are hard to reach through the entry point.
- Pure functions with interesting edge cases (regex parsing, data transformation) are worth testing directly because the edge cases are cheap to enumerate.
- Don't test framework/runtime behavior (context cancellation, timeout propagation) unless your code has explicit logic handling it.

### 6. When Not to Test

Not all code benefits from tests. Skip tests for:

- **Thin wrappers** that only delegate to another function or library with no logic
- **Declarative configuration** (route tables, DI wiring, static mappings)
- **Glue code** that just connects components without branching or transformation
- **Generated code** that is produced by a tool and not manually edited

If the only way to test something is to restate its implementation in the test, the test adds no value.

### 7. Functions Over Services

Prefer plain functions with explicit parameters over service classes with injected dependencies — unless the service genuinely manages state or has many dependencies that would make function signatures unwieldy.

A function that takes its dependencies as parameters is simpler to understand, simpler to test, and simpler to compose than a class that takes them in a constructor and stores them as fields.

## Workflow

### When Asked to Write Tests

1. Identify the external boundaries that need stubbing
2. Create simple value-based stubs (configured return values, not behavior functions)
3. Write table-driven/parameterized tests with only inputs and expected outputs
4. Verify: error vs no error, output value. Nothing else.
5. Check if any test is redundant because a higher-level test already covers the path

### When Asked to Refactor for Testability

1. Identify what's currently untestable (direct calls to external systems)
2. Extract an interface at the boundary — define it where the implementation lives
3. Make functions accept the interface as a parameter (not via class/constructor injection)
4. Remove unnecessary abstractions (service classes, option patterns, wrapper types)
5. Ensure no interface is defined more than once across the codebase

### When Reviewing Test Quality

Ask these questions:

- **Is this testing behavior or implementation?** If the test would break when refactoring internals without changing behavior, it's testing implementation.
- **Is this test double a stub or a mock?** If it has logic (conditionals, counters, argument verification), it is a mock. Replace it with a stub that just returns configured values.
- **Is this test redundant?** If a higher-level test already exercises this code path, remove the lower-level test.
- **Is this abstraction necessary?** If a type/interface/pattern exists only to make testing possible, find a simpler way.
- **Are we checking too much?** If the test asserts error message strings, call arguments, or internal state, reduce to just input/output verification.
