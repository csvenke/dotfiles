# Global Coding Guidelines

## Testability

- Design for testability using "functional core, imperative shell": keep pure business logic separate from code that does IO.
- Write code that is easy to test.
- Tests should verify WHAT the code does, not HOW it does it.
- Follow TDD: write the test first, then the implementation.

## Simplicity

- Prefer fewer lines of code over more.
- Minimize dependencies.
- Use flat structures over deep nesting.
- Choose obvious over clever.
- If code is hard to explain, it's too complex.

## Error Handling

- Fail fast with early returns.
- Avoid else blocks.
- Don't throw errors—let them bubble up to be handled at a higher level.
