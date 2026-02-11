package commands

import (
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/csvenke/wt/internal/git"
	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var cloneCmd = &cobra.Command{
	Use:   "clone <url>",
	Short: "Clone a repository as a worktree",
	Long: `Clone a repository as a bare worktree repository.

This clones the repository as a bare repo, initializes shared directories,
creates a worktree for the main branch, and pushes it to origin.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		url := args[0]

		// Extract repo name from URL
		repoName := extractRepoName(url)
		if repoName == "" {
			return fmt.Errorf("could not extract repository name from URL: %s", url)
		}

		// Save original directory
		originalDir, err := os.Getwd()
		if err != nil {
			return fmt.Errorf("failed to get current directory: %w", err)
		}

		// Create directory
		if err := os.Mkdir(repoName, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", repoName, err)
		}

		// Change into directory
		if err := os.Chdir(repoName); err != nil {
			return fmt.Errorf("failed to enter directory %s: %w", repoName, err)
		}

		// Clone bare repo
		if err := git.CloneBare(url); err != nil {
			return fmt.Errorf("failed to clone bare repo: %w", err)
		}

		// Initialize worktree repo (shared dirs, hooks)
		if err := worktree.InitRepo(); err != nil {
			return fmt.Errorf("failed to initialize worktree repo: %w", err)
		}

		// Get main branch name from remote
		mainBranch, err := git.GetRemoteMainBranch()
		if err != nil {
			// Fallback to main/master
			mainBranch, err = git.GetMainBranch()
			if err != nil {
				return fmt.Errorf("failed to determine main branch: %w", err)
			}
		}

		// Add worktree for main branch
		if err := git.WorktreeAdd("--lock", mainBranch); err != nil {
			return fmt.Errorf("failed to add main worktree: %w", err)
		}

		// Push main branch to origin with upstream
		if err := os.Chdir(mainBranch); err != nil {
			return fmt.Errorf("failed to enter main worktree: %w", err)
		}

		if err := git.PushUpstream(mainBranch); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to push to origin: %v\n", err)
		}

		// Return to original directory
		if err := os.Chdir(originalDir); err != nil {
			return fmt.Errorf("failed to return to original directory: %w", err)
		}

		fmt.Printf("Cloned worktree repository '%s' from %s\n", repoName, url)
		return nil
	},
}

// extractRepoName extracts the repository name from a git URL
func extractRepoName(url string) string {
	// Remove trailing .git if present
	url = strings.TrimSuffix(url, ".git")

	// Get the last path component
	base := path.Base(url)

	// Handle URLs like git@github.com:user/repo
	if strings.Contains(base, ":") {
		parts := strings.Split(base, ":")
		if len(parts) > 1 {
			base = parts[len(parts)-1]
		}
	}

	return base
}
