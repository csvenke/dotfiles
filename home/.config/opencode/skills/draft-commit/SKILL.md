---
name: draft-commit
description: "Write a high-quality Conventional Commits message for staged git changes. Triggers on requests to draft, write, or compose a commit message, or to prepare staged changes for commit."
---

# Draft Commit Message

Your reply will be inserted verbatim into a git commit buffer. Your entire
reply IS the commit message.

## Gather context

1. Run `git diff --staged --stat` and `git diff --staged`. Skip this step if
   the user already provided a diff. If nothing is staged, reply with a plain
   "nothing staged" note and stop — this is the ONLY case where your reply is
   not a commit message.
2. Run `git log -8 --oneline` to calibrate scope and wording style to the
   repository's existing history.

## Commit type selection

The type determines the version bump:

- feat: MINOR bump (new user-facing functionality)
- fix: PATCH bump (bug fixes to existing functionality)
- BREAKING CHANGE footer (or `!` after type): MAJOR bump (incompatible changes)

No version bump:

- chore: maintenance, dependency updates, config changes, tooling
- refactor: code restructuring without behavior change
- docs: documentation-only changes
- ci: CI/CD pipeline changes
- build: build system/dependency changes
- test: test-only changes
- perf: performance improvements
- style: formatting, whitespace, semicolons

When in doubt, prefer non-versioning types over feat/fix.

## Format

    type(scope): concise imperative description

    - bullet point per distinct change (body is optional, see rules)

    Optional footer (Closes: #issue, BREAKING CHANGE, etc.)

## Examples

Each indented block below is one complete reply for a different staged diff.
Plain text only — no fences, no backticks, nothing before or after.

Subject line only:

    fix(auth): return 401 instead of 500 when session token is expired

    chore: upgrade linting dependencies to latest minor versions

    refactor: extract validation logic into reusable helper functions

    perf: cache parsed config to avoid re-reading from disk on each request

With body:

    feat(api): add rate limiting to public endpoints

    - Add token bucket middleware with configurable limits per route
    - Add rate limit headers to responses
    - Return 429 with Retry-After header when limit exceeded

    refactor: rename mock types to stub in test files

    - Rename mockProvider to stubProvider
    - Rename mockClient to stubClient
    - Update method receivers from m to s

With breaking-change footer:

    feat!: replace integer IDs with UUIDs across all entities

    - Update model definitions and repository methods to use UUIDs
    - Add database migration to alter primary key column types

    BREAKING CHANGE: all API responses now return string UUIDs instead of integer IDs

Wrong — preamble, fences, prose body:

    Based on the staged changes, here's the commit message:
    ```
    fix(api): fix rate limiting
    ```
    The changes fix the rate limiter by adding a token bucket middleware.

Right — the message and nothing else:

    fix(api): reject requests with 429 after rate limit is exceeded

## Rules

- Subject: imperative, ≤72 chars, self-sufficient. Infer scope from changed
  file paths; match the repo's recent-commit style and tone.
- Body ONLY when the diff has 2+ logically distinct changes (unrelated
  concerns, or a fix mixed with a refactor). When in doubt, subject only.
- Bullets: imperative, concrete, one per distinct change, starting with a
  verb. Never restate the subject; never narrate the diff.
- Footer: reference issues (Closes: #123) when a number is available;
  BREAKING CHANGE for incompatible changes.

## Final check — read before replying

- Reply is ONLY the commit message: first character is the subject line's
  first character, last character is the message's last character.
- No preamble, no commentary, no closing remarks.
- No markdown fences, no backticks, anywhere in the reply.
- Body (if any) is `- ` bullets, never prose paragraphs.
