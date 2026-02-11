# wt - Git Worktree Manager

A Go CLI tool for managing Git worktrees with interactive selection, hook support, and health diagnostics.

## Features

- **add** - Add new worktrees with automatic `.shared/` copying and hook execution
- **remove** - Interactive removal with fzf-style selection (using bubbles)
- **switch** - Interactive switching with fzf-style selection (using bubbles)
- **list** - List all worktrees with their branches and status
- **prune** - Prune orphaned worktrees and delete their branches
- **init** - Initialize a repository for worktree use
- **clone** - Clone a repository as a worktree-ready bare repo
- **migrate** - Migrate an existing bare repo to worktree setup
- **doctor** - Diagnose worktree health and configuration
- **hook** - Manage and run worktree hooks

## Installation

### Quick Install (Recommended)

```bash
cd /path/to/wt
./install.sh
```

This will:
- Check that Go is installed
- Build the `wt` binary
- Install to `$GOPATH/bin` or `~/go/bin`
- Verify the installation

### From Source

```bash
cd /path/to/wt
go build ./cmd/wt
# Binary will be created as ./wt

# Or install directly to $GOPATH/bin:
go install ./cmd/wt
```

### Prerequisites

- Git 2.15+
- Go 1.21+ (for building)
- Optional: [direnv](https://direnv.net/) for environment management
- Optional: [nix](https://nixos.org/) for development shells

### Shell Integration

After installation, add these aliases to your `.bashrc` or `.zshrc`:

```bash
# Worktree aliases
alias gwi='wt init'
alias gwc='wt clone'
alias gws='wt switch'
alias gwa='wt add'
alias gwr='wt remove'
alias gwp='wt prune'
alias gwm='wt migrate'
alias gwd='wt doctor'
alias gwh='wt hook'
```

The `.bashrc` in this dotfiles repo already includes these aliases and will warn if `wt` is not installed.

### Migrating from Bash Functions

If you were using the old bash functions from `.bashrc`, here's how to migrate:

| Old Bash Function | New wt Command | Example |
|-------------------|----------------|---------|
| `_git_worktree_init <name>` | `wt init` | `wt init` |
| `_git_worktree_clone <url>` | `wt clone <url>` | `wt clone https://github.com/user/repo.git` |
| `_git_worktree_add <args>` | `wt add <branch>` | `wt add feature-branch` |
| `_git_worktree_switch` | `wt switch` | `wt switch` (interactive) |
| `_git_worktree_remove` | `wt remove` | `wt remove` (interactive) |
| `_git_worktree_prune` | `wt prune` | `wt prune` |
| `_migrate_worktree_repo` | `wt migrate` | `wt migrate` |
| `_init_worktree_repo` | `wt init` | `wt init` |

**Migration steps:**

1. Install `wt` using `./install.sh`
2. Update your `.bashrc` to remove old bash functions and add new aliases
3. The old functions are no longer needed - `wt` handles everything

**Key differences:**
- `wt switch` outputs the path instead of directly changing directories (see [Shell Integration](#directory-switching) for cd support)
- `wt remove` and `wt switch` use an interactive TUI instead of fzf
- `wt doctor` is a new command for diagnosing worktree health
- `wt hook list` and `wt hook run` provide hook management

## Quick Start

```bash
# Initialize a new worktree repository
wt init

# Or clone an existing repository as worktree-ready
wt clone https://github.com/user/repo.git

# Add a new worktree
wt add feature-branch

# List all worktrees
wt list

# Switch to a worktree (interactive)
wt switch

# Check worktree health
wt doctor
```

## Commands

### `wt init`

Initialize the current bare repository for worktree use.

```bash
wt init
```

This command:
- Sets up `remote.origin.fetch` to track all remote branches
- Creates `.shared/` directory for files to copy to new worktrees
- Creates `.hooks/` directory for automation hooks
- Optionally creates a `nix` worktree with development environment

### `wt clone <url>`

Clone a repository as a worktree-ready bare repository.

```bash
wt clone https://github.com/user/repo.git
```

### `wt add <branch> [path]`

Add a new worktree for the specified branch.

```bash
# Add worktree at path matching branch name
wt add feature-x

# Add worktree at custom path
wt add feature-x ./worktrees/my-feature
```

The command:
1. Creates the worktree at the specified path
2. Copies contents from `.shared/` to the new worktree
3. Runs `direnv allow` if `.envrc` exists
4. Executes `after-worktree-add.sh` hook if present

### `wt remove`

Interactively remove a worktree.

```bash
wt remove
```

Uses an interactive fzf-style interface to select which worktree to remove.

### `wt switch`

Interactively switch to a worktree.

```bash
wt switch
```

Outputs the path of the selected worktree. For actual directory switching, see [Shell Integration](#shell-integration).

### `wt list`

List all worktrees.

```bash
wt list
# or
wt ls
```

Output format:
```
/path/to/repo/.git (bare)
/path/to/repo/main [main]
/path/to/repo/feature [feature]
/path/to/repo/old [old-branch] [prunable]
```

### `wt prune`

Prune orphaned worktrees and delete their associated branches.

```bash
wt prune
```

Orphaned worktrees occur when worktree directories are deleted without using `git worktree remove`. This command cleans them up.

### `wt migrate`

Migrate an existing repository to worktree setup.

```bash
wt migrate
```

Fixes missing configurations and creates required directories.

### `wt doctor`

Diagnose the health of a worktree setup.

```bash
wt doctor
```

Performs the following checks:
- ✓ Git repository detection
- ✓ Bare repository configuration
- ✓ `.shared/` directory existence
- ✓ `.hooks/` directory existence
- ✓ `remote.origin.fetch` configuration
- ✓ Prunable worktrees detection
- ✓ Invalid worktrees detection
- ✓ direnv availability (if `.envrc` files exist)

Output includes:
- ✓/✗/⚠ indicators for each check
- Helpful suggestions for fixing issues
- Summary of errors and warnings

### `wt hook list`

List available hooks.

```bash
wt hook list
```

Shows:
- Active hooks (executable scripts)
- Sample hooks (`.sample` suffix)
- Non-executable files (require `chmod +x`)

### `wt hook run <name> <path>`

Manually run a hook at a specific worktree path.

```bash
wt hook run after-worktree-add.sh ./my-feature
```

## Configuration

### `.shared/` Directory

Files and directories in `.shared/` are automatically copied to new worktrees when they are created.

Common uses:
- `.envrc` files for direnv
- IDE configuration files
- Local development settings

Example:
```bash
# Create shared .envrc
echo 'use flake "../nix"' > .shared/.envrc

# Future worktrees will automatically get this .envrc
wt add new-feature
# new-feature/.envrc now exists
```

### `.hooks/` Directory

Executable scripts in `.hooks/` are run at specific points in the worktree lifecycle.

#### Available Hooks

- **`after-worktree-add.sh`** - Runs after a new worktree is created
  - Executed from inside the new worktree directory
  - Use for: installing dependencies, running setup scripts, etc.

#### Creating Hooks

```bash
# Create a hook
cat > .hooks/after-worktree-add.sh << 'EOF'
#!/usr/bin/env bash
# This hook runs after a new worktree is created

if [ -f "package-lock.json" ]; then
    echo "Installing npm dependencies..."
    npm ci
fi

if [ -f "composer.json" ]; then
    echo "Installing composer dependencies..."
    composer install
fi
EOF

# Make it executable
chmod +x .hooks/after-worktree-add.sh
```

#### Hook Execution Context

Hooks run with the following context:
- Working directory: The new worktree path
- Environment: Same as the `wt` command
- If `direnv` is installed and `.envrc` exists, hooks run with direnv's environment

## Shell Integration

### Directory Switching

The `wt switch` command outputs the selected path, but cannot change the shell's working directory directly. Add this function to your shell configuration:

**Bash/Zsh:**
```bash
wt() {
    if [[ "$1" == "switch" ]]; then
        local dir
        dir=$(command wt switch)
        if [[ -n "$dir" && -d "$dir" ]]; then
            cd "$dir"
        fi
    else
        command wt "$@"
    fi
}
```

**Fish:**
```fish
function wt
    if test "$argv[1]" = "switch"
        set dir (command wt switch)
        if test -n "$dir" -a -d "$dir"
            cd "$dir"
        end
    else
        command wt $argv
    end
end
```

### Tab Completion

Generate completion scripts:

```bash
# Bash
wt completion bash > /etc/bash_completion.d/wt

# Zsh
wt completion zsh > "${fpath[1]}/_wt"

# Fish
wt completion fish > ~/.config/fish/completions/wt.fish
```

## Comparison with Original Bash Functions

| Bash Function | wt Command | Notes |
|--------------|------------|-------|
| `_init_worktree_repo` | `wt init` | Initializes worktree setup |
| `_add_worktree` | `wt add` | Adds worktree + runs hooks |
| `_remove_worktree` | `wt remove` | Interactive removal |
| `_switch_worktree` | `wt switch` | Interactive switching |
| `_list_worktrees` | `wt list` | Lists with prunable status |
| `_prune_worktrees` | `wt prune` | Prunes + deletes branches |
| `_migrate_worktree_repo` | `wt migrate` | Fixes missing config |
| `_setup_worktree` | (automatic) | Runs during `wt add` |
| `_run_worktree_hook` | `wt hook run` | Hook execution |
| - | `wt doctor` | NEW: Health diagnostics |
| - | `wt hook list` | NEW: Hook management |
| - | `wt clone` | NEW: Clone as worktree |

## Error Handling

`wt` provides clear error messages with helpful suggestions:

```bash
# Example: Running outside git repo
$ wt list
Error: not a git repository
→ Run this command from a git repository root directory

# Example: Hook not executable
$ wt hook run my-hook.sh ./feature
Error: hook 'my-hook.sh' is not executable
→ Run: chmod +x .hooks/my-hook.sh
```

Exit codes:
- `0` - Success
- `1` - General error
- `2` - Invalid arguments

## Development

### Running Tests

```bash
cd /path/to/wt
go test ./...
```

### Building

```bash
go build ./cmd/wt
```

### Project Structure

```
wt/
├── cmd/wt/              # Main entry point
├── internal/
│   ├── commands/        # Cobra commands
│   │   ├── root.go      # Root command
│   │   ├── add.go       # Add command
│   │   ├── remove.go    # Remove command
│   │   ├── switch.go    # Switch command
│   │   ├── list.go      # List command
│   │   ├── prune.go     # Prune command
│   │   ├── init.go      # Init command
│   │   ├── clone.go     # Clone command
│   │   ├── migrate.go   # Migrate command
│   │   ├── doctor.go    # Doctor command
│   │   └── hook.go      # Hook command
│   ├── git/             # Git operations
│   │   ├── git.go
│   │   └── git_test.go
│   └── worktree/        # Worktree logic
│       ├── worktree.go
│       ├── init.go
│       ├── hooks.go
│       ├── worktree_test.go
│       └── init_test.go
├── go.mod
├── go.sum
└── README.md
```

## License

MIT
