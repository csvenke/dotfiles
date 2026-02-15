---
description: Review code changes (defaults to uncommitted)
subtask: true
---

You MUST first load the `code-review` skill using the skill tool before doing anything else. Follow its workflow and output format exactly.

## Target

$ARGUMENTS

## Current working tree

### Status

!`git status --short`

### Unstaged changes

!`git diff`

### Staged changes

!`git diff --cached`

### Change summary

!`git diff HEAD --stat`

## Instructions

- If a specific target was provided above (PR number, branch name, commit SHA), fetch and review that target instead of the working tree diffs. Use `gh pr diff` for PRs, `git diff main...<branch>` for branches, `git show <sha>` for commits.
- If no target was specified, review all uncommitted changes shown above.
- When reviewing staged and unstaged separately, note which changes are staged (ready to commit) vs unstaged (work in progress).
- If there are no changes to review, say so and exit.
