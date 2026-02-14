package commit

import (
	"context"
	"fmt"
	"os"
	"os/exec"

	"dotfiles/packages/llm/internal/claude"
	"dotfiles/packages/llm/internal/git"
	"dotfiles/packages/llm/internal/spinner"
)

// Config holds configuration for commit generation
type Config struct {
	Model  string
	APIKey string
	Full   bool // include full diff context
	Amend  bool // amend previous commit
}

// GitRepository defines the interface for git operations needed by the generator
type GitRepository interface {
	HasStagedChanges() (bool, error)
	GetCurrentBranch() (string, error)
	GetRecentCommits(n int) (string, error)
	GetDiffStat() (string, error)
	GetStagedDiff(full bool) (string, error)
}

// ClaudeClient defines the interface for Claude API operations
type ClaudeClient interface {
	Message(ctx context.Context, prompt string) (string, error)
}

// GenerateCommit orchestrates the commit workflow:
// 1. Checks for staged changes
// 2. Gathers git context
// 3. Builds prompt and calls Claude
// 4. Opens editor with drafted message
// 5. Commits if editor exits successfully, aborts otherwise
func GenerateCommit(cfg Config, repoPath string) error {
	// Open repository
	repo, err := git.Open(repoPath)
	if err != nil {
		return fmt.Errorf("failed to open repository: %w", err)
	}

	return generateCommitWithRepo(cfg, repo)
}

// generateCommitWithRepo allows for dependency injection in tests
func generateCommitWithRepo(cfg Config, repo GitRepository) error {
	// 1. Check if there are staged changes
	hasChanges, err := repo.HasStagedChanges()
	if err != nil {
		return fmt.Errorf("failed to check staged changes: %w", err)
	}
	if !hasChanges {
		fmt.Fprintln(os.Stderr, "No changes to commit")
		return nil
	}

	// 2. Gather git context
	ctx, err := gatherGitContext(repo, cfg.Full)
	if err != nil {
		return fmt.Errorf("failed to gather git context: %w", err)
	}

	// 3. Build prompt
	prompt, err := BuildPrompt(ctx)
	if err != nil {
		return fmt.Errorf("failed to build prompt: %w", err)
	}

	// 4. Call Claude API
	client, err := claude.New(cfg.Model, cfg.APIKey)
	if err != nil {
		return fmt.Errorf("failed to create Claude client: %w", err)
	}

	s := spinner.New()
	s.Start("Generating commit message with Claude...")
	message, err := client.Message(context.Background(), prompt)
	s.Stop()

	if err != nil {
		return fmt.Errorf("failed to generate commit message: %w", err)
	}

	// 5. Commit the message, allowing user to edit
	if err := executeCommit(message, cfg.Amend); err != nil {
		return fmt.Errorf("failed to commit: %w", err)
	}

	return nil
}

// gatherGitContext collects all necessary git information
func gatherGitContext(repo GitRepository, full bool) (GitContext, error) {
	var ctx GitContext
	var err error

	ctx.Branch, err = repo.GetCurrentBranch()
	if err != nil {
		return ctx, fmt.Errorf("failed to get branch: %w", err)
	}

	ctx.RecentCommits, err = repo.GetRecentCommits(5)
	if err != nil {
		return ctx, fmt.Errorf("failed to get recent commits: %w", err)
	}

	ctx.DiffStat, err = repo.GetDiffStat()
	if err != nil {
		return ctx, fmt.Errorf("failed to get diff stat: %w", err)
	}

	ctx.StagedDiff, err = repo.GetStagedDiff(full)
	if err != nil {
		return ctx, fmt.Errorf("failed to get staged diff: %w", err)
	}

	return ctx, nil
}

// executeCommit runs git commit with the message file
func executeCommit(message string, amend bool) error {
	// Create temp file for commit message
	tempDir := os.TempDir()
	tempFile, err := os.CreateTemp(tempDir, "commit-msg-*.txt")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())

	// Write message to temp file
	if _, err := tempFile.WriteString(message); err != nil {
		tempFile.Close()
		return fmt.Errorf("failed to write commit message: %w", err)
	}
	tempFile.Close()

	// Build git commit command with -e to open editor
	args := []string{"commit", "-e", "-F", tempFile.Name()}
	if amend {
		args = append(args, "--amend")
	}

	cmd := exec.Command("git", args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git commit failed: %w", err)
	}

	return nil
}
