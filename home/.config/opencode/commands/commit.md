---
description: Draft and commit staged changes
---

@git-staged-diff

Draft a commit message from the staged changes above following the repository's conventions.

## Instructions

1. If no staged changes, tell the user to stage changes first with `git add` and stop.

2. Analyze commit history to identify patterns (Conventional Commits, types, scopes, footers)

3. Draft commit message options:
   - Primary message: Best fit based on changes and patterns (subject + body + footer as needed)
   - Alternative messages (optional, max 2): Only if genuinely relevant

4. **MUST**: Display ALL proposed messages with full details labeled as:

   ### Option A (Recommended)

   <subject>

   <body if applicable>

   <footer if applicable>

   ### Option B

   ...

5. **MUST**: Use the Question tool to ask which option to use. Do NOT skip this step.
   - Options: "Option A (Recommended)", "Option B", "Option C", "Cancel"
   - Descriptions: Just the subject line
   - Allow custom input

6. **ONLY AFTER** user selects an option: Execute `git commit` with the selected message

7. Confirm success with the commit hash
