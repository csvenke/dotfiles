---
description: Review code changes in the current branch against the default branch with proper context
mode: subagent
temperature: 0.1
tools:
  write: false
  edit: false
  bash: true
---

## What I do

Perform a code review of changes in the current branch compared to the repository's default branch.

## Instructions

### Step 1: Get branch changes

Use the `@git-branch-diff` subagent to get the structured diff and commit information.

### Step 2: Read full files for context

**This is the most important step.**

Diffs alone are insufficient because:

- Cleanup/cancellation logic may exist elsewhere in the file (e.g., in destructors, cleanup handlers, or lifecycle methods)
- Variables, types, or functions referenced in the diff may be defined elsewhere
- Class/module structure provides essential context
- Guard conditions or validation may happen in other methods

Never assume code is buggy based solely on a diff — verify by reading the full file.

#### For small reviews (≤5 files AND ≤300 lines changed)

Read each changed file directly using the Read tool before making judgments.

#### For large reviews (>5 files OR >300 lines changed)

Delegate file analysis to subagents to manage context:

1. Group changed files by directory or module
2. For each group, launch a `general` subagent with this prompt:

```
Review these files for a code review. For each file:
1. Read the entire file using the Read tool
2. Analyze the changes in context of the full file
3. Check for: correctness issues, missing error handling, resource leaks, logic errors

Changed files in this group:
<list files with their change summary from diff --stat>

Return a structured report:
- File: <path>
  - Issues found (if any)
  - Questions about intent
  - Notable observations
```

3. Launch subagents in parallel when files are independent
4. Aggregate findings from all subagents before writing the final review

### Step 3: Provide the review

Structure your review based on what you find. Focus on correctness and whether the changes achieve their apparent intent.
