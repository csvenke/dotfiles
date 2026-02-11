package worktree

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/csvenke/wt/internal/git"
)

const sampleHookContent = `#!/usr/bin/env bash
# This hook is executed after a new worktree is created.
# To enable this hook, rename this file to "after-worktree-add.sh".
#
# The hook runs from inside the new worktree directory.
#
# Example:
#   if [ -f "package-lock.json" ]; then
#     npm ci
#   fi
`

// InitRepo initializes a worktree repository with shared directories and hooks
func InitRepo() error {
	// Set remote.origin.fetch config
	if err := git.ConfigSet("remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"); err != nil {
		return fmt.Errorf("failed to set remote.origin.fetch: %w", err)
	}

	// Fetch origin
	if err := git.Fetch("origin"); err != nil {
		// Don't fail if fetch fails (e.g., no remote configured yet)
		fmt.Fprintf(os.Stderr, "Warning: failed to fetch origin: %v\n", err)
	}

	// Create .shared directory
	if err := os.MkdirAll(".shared", 0755); err != nil {
		return fmt.Errorf("failed to create .shared: %w", err)
	}

	// Create .hooks directory
	if err := os.MkdirAll(".hooks", 0755); err != nil {
		return fmt.Errorf("failed to create .hooks: %w", err)
	}

	// Create sample hook file
	sampleHookPath := filepath.Join(".hooks", "after-worktree-add.sh.sample")
	if _, err := os.Stat(sampleHookPath); os.IsNotExist(err) {
		if err := os.WriteFile(sampleHookPath, []byte(sampleHookContent), 0755); err != nil {
			return fmt.Errorf("failed to create sample hook: %w", err)
		}
	}

	// Check if nix is available and create nix worktree if so
	if hasNix() {
		if err := createNixWorktree(); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to create nix worktree: %v\n", err)
		}
	}

	return nil
}

// hasNix checks if nix command is available
func hasNix() bool {
	_, err := exec.LookPath("nix")
	return err == nil
}

// createNixWorktree creates a nix worktree with flake template
func createNixWorktree() error {
	// Add orphan nix worktree
	if err := git.WorktreeAddOrphan("nix"); err != nil {
		return fmt.Errorf("failed to add nix worktree: %w", err)
	}

	// Initialize nix flake in the nix worktree
	nixDir := "nix"
	if err := os.Chdir(nixDir); err != nil {
		return fmt.Errorf("failed to enter nix directory: %w", err)
	}

	// Run nix flake init
	cmd := exec.Command("nix", "flake", "init", "-t", "github:csvenke/devkit")
	if err := cmd.Run(); err != nil {
		os.Chdir("..")
		return fmt.Errorf("failed to init nix flake: %w", err)
	}

	// Run nix flake lock
	cmd = exec.Command("nix", "flake", "lock")
	if err := cmd.Run(); err != nil {
		os.Chdir("..")
		return fmt.Errorf("failed to lock nix flake: %w", err)
	}

	// Add and commit
	if _, err := git.Run("add", "."); err != nil {
		os.Chdir("..")
		return fmt.Errorf("failed to add nix files: %w", err)
	}

	if err := git.Commit("genesis"); err != nil {
		os.Chdir("..")
		return fmt.Errorf("failed to commit nix files: %w", err)
	}

	// Go back to parent directory
	if err := os.Chdir(".."); err != nil {
		return fmt.Errorf("failed to return to parent directory: %w", err)
	}

	// Create .shared/.envrc
	envrcPath := filepath.Join(".shared", ".envrc")
	if err := os.WriteFile(envrcPath, []byte("use flake \"../nix\"\n"), 0644); err != nil {
		return fmt.Errorf("failed to create .envrc: %w", err)
	}

	return nil
}

// IsWorktreeRoot checks if current directory is a worktree repo root
func IsWorktreeRoot() bool {
	if _, err := os.Stat(".git"); err != nil {
		return false
	}
	if _, err := os.Stat(filepath.Join(".git", "HEAD")); err != nil {
		return false
	}
	return true
}
