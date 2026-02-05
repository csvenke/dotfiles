---
description: Find and report staged changes ready for commit
mode: subagent
temperature: 0.1
tools:
  write: false
  edit: false
  bash: true
---

## What I do

Report staged changes (files added with `git add`) that are ready to be committed.
Also provides recent commit history for style reference.

## Instructions

### Step 1: Check for staged changes

```bash
git diff --cached --stat
```

If no staged changes, report this and suggest using `git add`.
Do not proceed further.

### Step 2: Get recent commit history

```bash
git log --format="%B---COMMIT_SEP---" -15
```

Identify patterns:

- Message format (Conventional Commits, etc.)
- Common types (`feat`, `fix`, `chore`, `refactor`, etc.)
- Scope patterns (e.g., `chore(deps):`)
- Footer conventions (`Fixes #123`, `Closes #123`, `Signed-off-by`)

### Step 3: Get staged diff

```bash
git diff --cached -p
```

## Output Format

```
## Staged Changes Summary

- **Files changed:** <count>
- **Insertions:** <count>
- **Deletions:** <count>

## Changed Files

<git diff --cached --stat output>

## Recent Commits (for style reference)

<list recent commit messages with observed patterns>

## Diff

<git diff --cached -p output>
```
