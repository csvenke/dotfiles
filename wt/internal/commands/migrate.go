package commands

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/csvenke/wt/internal/git"
	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var migrateCmd = &cobra.Command{
	Use:   "migrate",
	Short: "Migrate an existing repository to worktree format",
	Long: `Migrate an existing repository to worktree format.

This checks if the current directory is a worktree repo root and ensures
proper configuration including remote.origin.fetch, shared directories,
and hook templates.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		// Check if in a worktree repo root
		if !worktree.IsWorktreeRoot() {
			return fmt.Errorf("not in a worktree repo root (no .git directory or .git/HEAD)")
		}

		// Check if remote.origin.fetch is set
		_, err := git.ConfigGet("remote.origin.fetch")
		if err != nil {
			// Set remote.origin.fetch
			if err := git.ConfigSet("remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"); err != nil {
				return fmt.Errorf("failed to set remote.origin.fetch: %w", err)
			}

			// Fetch origin
			if err := git.Fetch("origin"); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: failed to fetch origin: %v\n", err)
			} else {
				fmt.Println("Fixed missing remote.origin.fetch config")
			}
		}

		// Create .shared directory if it doesn't exist
		if err := os.MkdirAll(".shared", 0755); err != nil {
			return fmt.Errorf("failed to create .shared: %w", err)
		}

		// Create .hooks directory if it doesn't exist
		if err := os.MkdirAll(".hooks", 0755); err != nil {
			return fmt.Errorf("failed to create .hooks: %w", err)
		}

		// Create sample hook file if it doesn't exist
		sampleHookPath := filepath.Join(".hooks", "after-worktree-add.sh.sample")
		if _, err := os.Stat(sampleHookPath); os.IsNotExist(err) {
			sampleHookContent := `#!/usr/bin/env bash
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
			if err := os.WriteFile(sampleHookPath, []byte(sampleHookContent), 0755); err != nil {
				return fmt.Errorf("failed to create sample hook: %w", err)
			}
			fmt.Println("Created .hooks/after-worktree-add.sh.sample")
		}

		fmt.Println("Migration complete")
		return nil
	},
}
