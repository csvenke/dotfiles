package git

import (
	"fmt"
	"os/exec"
	"strings"
)

// Run executes a git command and returns the output
func Run(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("git %s: %w", strings.Join(args, " "), err)
	}
	return strings.TrimSpace(string(output)), nil
}

// WorktreeAdd adds a new worktree
func WorktreeAdd(args ...string) error {
	_, err := Run(append([]string{"worktree", "add"}, args...)...)
	return err
}

// WorktreeRemove removes a worktree
func WorktreeRemove(path string) error {
	_, err := Run("worktree", "remove", path)
	return err
}

// WorktreeList returns a list of worktrees
func WorktreeList() ([]WorktreeInfo, error) {
	output, err := Run("worktree", "list", "--porcelain")
	if err != nil {
		return nil, err
	}
	return ParseWorktreeList(output), nil
}

// WorktreePrune prunes orphaned worktrees
func WorktreePrune() error {
	_, err := Run("worktree", "prune")
	return err
}

// WorktreeListPrunable returns branches that can be pruned
func WorktreeListPrunable() ([]string, error) {
	output, err := Run("worktree", "list", "--porcelain")
	if err != nil {
		return nil, err
	}

	var branches []string
	lines := strings.Split(output, "\n")
	for i, line := range lines {
		if strings.HasPrefix(line, "prunable") && i > 0 {
			prevLine := lines[i-1]
			if strings.HasPrefix(prevLine, "branch refs/heads/") {
				branch := strings.TrimPrefix(prevLine, "branch refs/heads/")
				branches = append(branches, branch)
			}
		}
	}
	return branches, nil
}

// BranchDelete deletes a branch
func BranchDelete(branch string) error {
	_, err := Run("branch", "-D", branch)
	return err
}

// WorktreeInfo represents a single worktree entry
type WorktreeInfo struct {
	Path     string
	Commit   string
	Branch   string
	Bare     bool
	Detached bool
	Prunable bool
}

// ParseWorktreeList parses git worktree list --porcelain output
func ParseWorktreeList(output string) []WorktreeInfo {
	var worktrees []WorktreeInfo
	var current *WorktreeInfo

	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if line == "" {
			if current != nil {
				worktrees = append(worktrees, *current)
				current = nil
			}
			continue
		}

		if current == nil {
			current = &WorktreeInfo{Path: line}
			continue
		}

		parts := strings.SplitN(line, " ", 2)
		key := parts[0]
		var value string
		if len(parts) > 1 {
			value = parts[1]
		}

		switch key {
		case "HEAD":
			current.Commit = value
		case "branch":
			current.Branch = strings.TrimPrefix(value, "refs/heads/")
		case "bare":
			current.Bare = true
		case "detached":
			current.Detached = true
		case "prunable":
			current.Prunable = true
		}
	}

	if current != nil {
		worktrees = append(worktrees, *current)
	}

	return worktrees
}

// GetMainBranch returns the main branch name (main or master)
func GetMainBranch() (string, error) {
	for _, branch := range []string{"main", "master"} {
		_, err := Run("rev-parse", "--verify", branch)
		if err == nil {
			return branch, nil
		}
	}
	return "", fmt.Errorf("no main or master branch found")
}

// GetRemoteMainBranch returns the main branch name from remote
func GetRemoteMainBranch() (string, error) {
	output, err := Run("remote", "show", "origin")
	if err != nil {
		return "", err
	}

	for _, line := range strings.Split(output, "\n") {
		if strings.Contains(line, "HEAD branch:") {
			parts := strings.SplitN(line, ":", 2)
			if len(parts) == 2 {
				return strings.TrimSpace(parts[1]), nil
			}
		}
	}
	return "", fmt.Errorf("could not determine remote main branch")
}

// InitBare initializes a bare git repository
func InitBare(dir string, initialBranch string) error {
	args := []string{"init", "--bare", ".git"}
	if initialBranch != "" {
		args = append(args, "-b", initialBranch)
	}
	_, err := Run(args...)
	return err
}

// CloneBare clones a repository as a bare repo
func CloneBare(url string) error {
	_, err := Run("clone", "--bare", url, ".git")
	return err
}

// ConfigGet gets a git config value
func ConfigGet(key string) (string, error) {
	return Run("config", "--get", key)
}

// ConfigSet sets a git config value
func ConfigSet(key, value string) error {
	_, err := Run("config", key, value)
	return err
}

// Fetch fetches from remote
func Fetch(remote string) error {
	_, err := Run("fetch", remote)
	return err
}

// WorktreeAddOrphan adds an orphan worktree
func WorktreeAddOrphan(path string) error {
	_, err := Run("worktree", "add", "--orphan", "--lock", path)
	return err
}

// Commit creates a commit with the given message
func Commit(message string) error {
	_, err := Run("commit", "-m", message)
	return err
}

// Push sets upstream and pushes to origin
func PushUpstream(branch string) error {
	_, err := Run("push", "-u", "origin", branch)
	return err
}
