# Agent Guidelines

## Dotfiles Configuration Rules

NEVER guess config options, APIs, or settings. ALWAYS verify they exist first.

- If unsure whether an option exists, say so and offer to look it up
- Do not invent plausible-sounding options that may not exist

### Documentation References

- Zellij: https://zellij.dev/documentation/configuration.html
- Ghostty: https://ghostty.org/docs/config/reference
- Alacritty: https://alacritty.org/config-alacritty.html
- Direnv: https://direnv.net/man/direnv.1.html
- OpenCode: https://opencode.ai/config.json

## Build/Test Commands

- Check/test flake: `nix flake check`
- Enter dev shell: `nix develop`

## Code Style

### Nix (.nix files)

- Use 2-space indentation
- Function parameters on separate lines in attribute set format
- Use `let...in` blocks for local bindings
- Prefer `lib.readFile` for external file content
- Use `callPackage` pattern for package imports
- Import order: pkgs functions, then specific packages, alphabetically

### Python (.py files)

- Use type hints: `def foo(bar: str) -> None:`
- Import order: stdlib, third-party, local (separated by blank lines)
- Use snake_case for functions/variables

### Bash (.bash, shell scripts)

- Use functions with descriptive names in snake_case
- Call `main "$@"` at the end of scripts
- Use local variables in functions

### General

- LF line endings, insert final newline (.editorconfig)
- No comments unless necessary for clarity
