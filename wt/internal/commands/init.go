package commands

import (
	"fmt"
	"os"

	"github.com/csvenke/wt/internal/git"
	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init <name>",
	Short: "Initialize a new worktree repository",
	Long: `Initialize a new worktree repository with the given name.

This creates a bare git repository with a main worktree, initializes
shared directories, and sets up hooks. If nix is available, it also
creates a nix worktree with a flake template.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]
		mainBranch := "main"

		// Create directory
		if err := os.Mkdir(name, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", name, err)
		}

		// Change into directory
		if err := os.Chdir(name); err != nil {
			return fmt.Errorf("failed to enter directory %s: %w", name, err)
		}

		// Initialize bare repo
		if err := git.InitBare(".git", mainBranch); err != nil {
			return fmt.Errorf("failed to initialize bare repo: %w", err)
		}

		// Add orphan worktree for main branch
		if err := git.WorktreeAddOrphan(mainBranch); err != nil {
			return fmt.Errorf("failed to add main worktree: %w", err)
		}

		// Create genesis commit in main worktree
		if err := os.Chdir(mainBranch); err != nil {
			return fmt.Errorf("failed to enter main worktree: %w", err)
		}

		// Create README.md
		if err := os.WriteFile("README.md", []byte(""), 0644); err != nil {
			return fmt.Errorf("failed to create README.md: %w", err)
		}

		// Add and commit
		if _, err := git.Run("add", "."); err != nil {
			return fmt.Errorf("failed to add files: %w", err)
		}

		if err := git.Commit("genesis"); err != nil {
			return fmt.Errorf("failed to create genesis commit: %w", err)
		}

		// Go back to repo root
		if err := os.Chdir(".."); err != nil {
			return fmt.Errorf("failed to return to repo root: %w", err)
		}

		// Initialize worktree repo (shared dirs, hooks, nix)
		if err := worktree.InitRepo(); err != nil {
			return fmt.Errorf("failed to initialize worktree repo: %w", err)
		}

		// Setup worktree (copy .shared, direnv allow)
		if err := worktree.Setup(mainBranch); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to setup worktree: %v\n", err)
		}

		fmt.Printf("Initialized worktree repository '%s'\n", name)
		return nil
	},
}
