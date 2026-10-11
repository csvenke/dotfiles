---
name: nix
description: "Working with Nix projects. Load when building, checking, or modifying Nix flakes and packages."
---

# Nix

## File visibility

Nix flakes only see files tracked by git. New or modified files that are not staged will be invisible to `nix build`, `nix flake check`, and other Nix commands — builds will fail with missing file errors.

**Rule: run `git add <file>` after creating or modifying any file that Nix needs to see.** Staging is enough — committing is not required.

```bash
# Stage a single file
git add path/to/file.nix

# Stage all changes
git add -A
```

If a Nix build fails with a missing file error, check `git status` for unstaged files first.
