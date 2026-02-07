# Agent Guidelines

## Dotfiles Configuration Rules

NEVER guess config options, APIs, or settings. ALWAYS verify they exist first.

- If unsure whether an option exists, say so and offer to look it up
- Do not invent plausible-sounding options that may not exist

### Documentation References

Use context7 MCP to look up documentation for libraries and frameworks.

### Agents

Agents are stored in `home/.config/opencode/agents/.

### Skills

Skills are stored in `home/.config/opencode/skills/` and provide specialized knowledge:

## Build/Test Commands

- Check/test flake: `nix flake check`
- Enter dev shell: `nix develop`
- Build specific package: `nix build .#<package-name>`
- Install dotfiles: `nix run .#install`
- Update flake inputs: `nix flake update`

## Code Style

### Nix (.nix files)

- Use 2-space indentation
- Function parameters on separate lines in attribute set format
- Use `let...in` blocks for local bindings
- Prefer `lib.readFile` for external file content
- Use `callPackage` pattern for package imports
- Import order: pkgs functions, then specific packages, alphabetically
- Use `rec` only when necessary for self-reference
- Prefer `lib.optionalString` and `lib.optional` for conditional content

### Python (.py files)

- Use type hints: `def foo(bar: str) -> None:`
- Import order: stdlib, third-party, local (separated by blank lines)
- Use snake_case for functions/variables, PascalCase for classes
- Maximum line length: 88 characters (Black default)
- Use f-strings for string formatting
- Prefer `pathlib` over `os.path`

### Bash (.bash, shell scripts)

- Use functions with descriptive names in snake_case
- Call `main "$@"` at the end of scripts
- Use local variables in functions with `local` keyword
- Quote all variables: `"$variable"`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use `set -euo pipefail` for strict mode in standalone scripts
- Check command existence with `command -v` before use
- Use `#!/usr/bin/env bash` shebang

### General

- LF line endings, insert final newline (.editorconfig)
- No comments unless necessary for clarity
- Use descriptive variable names
- Keep functions small and focused
- Prefer early returns over deep nesting
