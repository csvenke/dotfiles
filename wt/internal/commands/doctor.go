package commands

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/csvenke/wt/internal/git"
	"github.com/spf13/cobra"
)

// CheckResult represents a single diagnostic check
type CheckResult struct {
	Name      string
	Passed    bool
	Message   string
	Severity  string // error, warning, info
	Suggestion string
}

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Diagnose worktree health",
	Long: `Diagnose the health of a worktree setup.

This command checks various aspects of the worktree configuration
and reports any issues found, along with suggestions for fixes.`,
	RunE: runDoctor,
}

func runDoctor(cmd *cobra.Command, args []string) error {
	results := []CheckResult{
		checkIsGitRepository(),
		checkIsBareRepo(),
		checkSharedDirectory(),
		checkHooksDirectory(),
		checkRemoteOriginFetch(),
		checkPrunableWorktrees(),
		checkValidWorktrees(),
		checkDirenv(),
	}

	printReport(results)
	return nil
}

func checkIsGitRepository() CheckResult {
	result := CheckResult{
		Name: "Git Repository",
	}

	if _, err := os.Stat(".git"); err != nil {
		result.Passed = false
		result.Severity = "error"
		result.Message = "Not in a git repository root"
		result.Suggestion = "Run this command from a git repository root directory"
		return result
	}

	result.Passed = true
	result.Message = "Git repository detected"
	return result
}

func checkIsBareRepo() CheckResult {
	result := CheckResult{
		Name: "Bare Repository",
	}

	isBare, err := git.ConfigGet("core.bare")
	if err != nil || isBare != "true" {
		result.Passed = false
		result.Severity = "warning"
		result.Message = "Not a bare repository (worktree setup)"
		result.Suggestion = "Consider running 'wt init' to set up worktree support"
		return result
	}

	result.Passed = true
	result.Message = "Bare repository configured for worktrees"
	return result
}

func checkSharedDirectory() CheckResult {
	result := CheckResult{
		Name: ".shared/ Directory",
	}

	if _, err := os.Stat(".shared"); os.IsNotExist(err) {
		result.Passed = false
		result.Severity = "warning"
		result.Message = ".shared/ directory does not exist"
		result.Suggestion = "Run 'mkdir .shared' to create shared files directory"
		return result
	}

	result.Passed = true
	result.Message = ".shared/ directory exists"
	return result
}

func checkHooksDirectory() CheckResult {
	result := CheckResult{
		Name: ".hooks/ Directory",
	}

	if _, err := os.Stat(".hooks"); os.IsNotExist(err) {
		result.Passed = false
		result.Severity = "warning"
		result.Message = ".hooks/ directory does not exist"
		result.Suggestion = "Run 'mkdir .hooks' to create hooks directory"
		return result
	}

	result.Passed = true
	result.Message = ".hooks/ directory exists"
	return result
}

func checkRemoteOriginFetch() CheckResult {
	result := CheckResult{
		Name: "Remote Origin Fetch",
	}

	fetchConfig, err := git.ConfigGet("remote.origin.fetch")
	if err != nil || fetchConfig != "+refs/heads/*:refs/remotes/origin/*" {
		result.Passed = false
		result.Severity = "warning"
		result.Message = "remote.origin.fetch not configured correctly"
		result.Suggestion = "Run 'git config remote.origin.fetch \"+refs/heads/*:refs/remotes/origin/*\"'"
		return result
	}

	result.Passed = true
	result.Message = "remote.origin.fetch configured correctly"
	return result
}

func checkPrunableWorktrees() CheckResult {
	result := CheckResult{
		Name: "Prunable Worktrees",
	}

	branches, err := git.WorktreeListPrunable()
	if err != nil {
		result.Passed = false
		result.Severity = "error"
		result.Message = fmt.Sprintf("Failed to check prunable worktrees: %v", err)
		result.Suggestion = "Check git configuration and try again"
		return result
	}

	if len(branches) > 0 {
		result.Passed = false
		result.Severity = "warning"
		result.Message = fmt.Sprintf("Found %d prunable worktree(s): %v", len(branches), branches)
		result.Suggestion = "Run 'wt prune' to clean up orphaned worktrees"
		return result
	}

	result.Passed = true
	result.Message = "No prunable worktrees found"
	return result
}

func checkValidWorktrees() CheckResult {
	result := CheckResult{
		Name: "Valid Worktrees",
	}

	worktrees, err := git.WorktreeList()
	if err != nil {
		result.Passed = false
		result.Severity = "error"
		result.Message = fmt.Sprintf("Failed to list worktrees: %v", err)
		result.Suggestion = "Check git configuration and try again"
		return result
	}

	invalidCount := 0
	for _, wt := range worktrees {
		if wt.Prunable {
			invalidCount++
		} else if wt.Bare {
			continue
		} else {
			// Check if path exists
			if _, err := os.Stat(wt.Path); err != nil {
				invalidCount++
			}
		}
	}

	if invalidCount > 0 {
		result.Passed = false
		result.Severity = "warning"
		result.Message = fmt.Sprintf("Found %d invalid worktree(s)", invalidCount)
		result.Suggestion = "Run 'wt prune' to remove invalid worktrees"
		return result
	}

	result.Passed = true
	result.Message = fmt.Sprintf("All %d worktree(s) are valid", len(worktrees))
	return result
}

func checkDirenv() CheckResult {
	result := CheckResult{
		Name: "Direnv",
	}

	// Check if any .envrc files exist in worktrees
	hasEnvrc := false
	if entries, err := os.ReadDir("."); err == nil {
		for _, entry := range entries {
			if entry.IsDir() && entry.Name() != ".git" {
				envrcPath := filepath.Join(entry.Name(), ".envrc")
				if _, err := os.Stat(envrcPath); err == nil {
					hasEnvrc = true
					break
				}
			}
		}
	}

	// Also check .shared/.envrc
	if _, err := os.Stat(filepath.Join(".shared", ".envrc")); err == nil {
		hasEnvrc = true
	}

	if !hasEnvrc {
		result.Passed = true
		result.Severity = "info"
		result.Message = "No .envrc files found (direnv not required)"
		return result
	}

	// Check if direnv is available
	if _, err := exec.LookPath("direnv"); err != nil {
		result.Passed = false
		result.Severity = "warning"
		result.Message = "direnv not found but .envrc files exist"
		result.Suggestion = "Install direnv to enable automatic environment loading"
		return result
	}

	result.Passed = true
	result.Message = "direnv is available and .envrc files detected"
	return result
}

func printReport(results []CheckResult) {
	fmt.Println()
	fmt.Println("Worktree Health Report")
	fmt.Println("======================")
	fmt.Println()

	errors := 0
	warnings := 0

	for _, r := range results {
		symbol := "✓"
		if !r.Passed {
			if r.Severity == "error" {
				symbol = "✗"
				errors++
			} else {
				symbol = "⚠"
				warnings++
			}
		}

		fmt.Printf("%s %s\n", symbol, r.Name)
		fmt.Printf("  %s\n", r.Message)
		if r.Suggestion != "" {
			fmt.Printf("  → %s\n", r.Suggestion)
		}
		fmt.Println()
	}

	fmt.Println("======================")
	if errors == 0 && warnings == 0 {
		fmt.Println("All checks passed! ✓")
	} else {
		fmt.Printf("Found %d error(s) and %d warning(s)\n", errors, warnings)
	}
	fmt.Println()
}
