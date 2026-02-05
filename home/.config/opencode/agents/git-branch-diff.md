---
description: Find and report changes in the current branch compared to the default branch
mode: subagent
temperature: 0.1
tools:
  write: false
  edit: false
  bash: true
---

## What I do

Detect what has changed in the current branch compared to the repository's default branch. Returns a unified diff that includes both committed changes and staged changes — everything that would be part of a pull request.

## Instructions

### Step 1: Fetch latest from origin

```bash
git fetch origin --quiet
```

This ensures all comparisons use up-to-date remote refs.

### Step 2: Find the default branch

Try these methods in order until one succeeds:

1. Check the symbolic ref:

   ```bash
   git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null
   ```

   This returns `origin/<branch>`. Extract just the branch name.

2. If that fails, check for common branch names:
   ```bash
   git rev-parse --verify --quiet origin/main >/dev/null && echo "main"
   ```
   ```bash
   git rev-parse --verify --quiet origin/master >/dev/null && echo "master"
   ```

If all methods fail, report an error to the user.

### Step 3: Get the current branch and determine comparison mode

```bash
git branch --show-current
```

Compare the current branch to the default branch:

- **If on a feature branch**: compare against `origin/<default-branch>`
- **If on the default branch**: compare against `origin/<default-branch>` to find unpushed changes

### Step 4: Find the merge base and list commits

Find where the current branch diverged:

```bash
git merge-base HEAD origin/<default-branch>
```

List commits ahead of the merge base:

```bash
git log --oneline <merge-base>..HEAD
```

### Step 5: Get unified diff (commits + staged changes)

Use `git diff-index` to get a single diff that includes both committed changes and staged changes:

```bash
git diff-index --stat <merge-base>
git diff-index -p <merge-base>
```

This shows everything that differs from the merge base, including:

- All commits on the branch
- Any staged changes not yet committed

### Error Handling

If any of these conditions occur, report clearly to the user:

- Not a git repository
- No remote named "origin"
- Detached HEAD state
- Cannot determine default branch

## Output Format

Return a structured report:

```
## Branch Summary

- **Current branch:** <branch-name>
- **Default branch:** <default-branch>
- **Merge base:** <commit-hash>
- **Commits ahead:** <count>
- **Staged changes:** yes/no

## Commits

<list each commit: hash - message>
(or "No commits ahead of origin/<default-branch>")

## Changed Files

<git diff-index --stat output>
(or "No changes")

## Diff

<git diff-index -p output>
(or "No changes to review")
```
