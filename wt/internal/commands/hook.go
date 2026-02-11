package commands

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var hookCmd = &cobra.Command{
	Use:   "hook",
	Short: "Manage worktree hooks",
	Long: `Manage and run worktree hooks.

Hooks are executable scripts stored in .hooks/ that are run at
different stages of worktree operations.

Available hooks:
  after-worktree-add.sh  - Run after a new worktree is created`,
}

var hookListCmd = &cobra.Command{
	Use:   "list",
	Short: "List available hooks",
	Long:  `List all available hooks in the .hooks/ directory.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return listHooks()
	},
}

var hookRunCmd = &cobra.Command{
	Use:   "run <name> <path>",
	Short: "Run a hook manually",
	Long: `Run a specific hook at a given worktree path.

The hook must be an executable file in the .hooks/ directory.
If the hook doesn't exist or isn't executable, an error is returned.`,
	Args: cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		hookName := args[0]
		worktreePath := args[1]
		return runHook(hookName, worktreePath)
	},
}

func init() {
	hookCmd.AddCommand(hookListCmd)
	hookCmd.AddCommand(hookRunCmd)
}

func listHooks() error {
	hooksDir := ".hooks"

	// Check if .hooks directory exists
	info, err := os.Stat(hooksDir)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Println("No hooks directory found (.hooks/)")
			fmt.Println("Create it with: mkdir .hooks")
			return nil
		}
		return fmt.Errorf("failed to access .hooks directory: %w", err)
	}

	if !info.IsDir() {
		return fmt.Errorf(".hooks is not a directory")
	}

	// Read directory contents
	entries, err := os.ReadDir(hooksDir)
	if err != nil {
		return fmt.Errorf("failed to read .hooks directory: %w", err)
	}

	if len(entries) == 0 {
		fmt.Println("No hooks found in .hooks/")
		fmt.Println("Add executable scripts to .hooks/ to create hooks")
		return nil
	}

	fmt.Println()
	fmt.Println("Available Hooks")
	fmt.Println("===============")
	fmt.Println()

	var activeHooks []os.DirEntry
	var sampleHooks []os.DirEntry
	var otherFiles []os.DirEntry

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()
		if strings.HasSuffix(name, ".sample") {
			sampleHooks = append(sampleHooks, entry)
		} else {
			info, err := entry.Info()
			if err == nil && info.Mode()&0111 != 0 {
				activeHooks = append(activeHooks, entry)
			} else {
				otherFiles = append(otherFiles, entry)
			}
		}
	}

	if len(activeHooks) > 0 {
		fmt.Println("Active Hooks:")
		for _, hook := range activeHooks {
			fmt.Printf("  ✓ %s\n", hook.Name())
		}
		fmt.Println()
	}

	if len(sampleHooks) > 0 {
		fmt.Println("Sample Hooks:")
		for _, hook := range sampleHooks {
			fmt.Printf("  ⓘ %s (rename to enable)\n", hook.Name())
		}
		fmt.Println()
	}

	if len(otherFiles) > 0 {
		fmt.Println("Other Files (not executable):")
		for _, file := range otherFiles {
			fmt.Printf("  - %s (chmod +x to enable)\n", file.Name())
		}
		fmt.Println()
	}

	fmt.Println("Usage:")
	fmt.Println("  wt hook run <name> <path>  - Run a hook at a worktree path")
	fmt.Println()

	return nil
}

func runHook(hookName, worktreePath string) error {
	hookPath := filepath.Join(".hooks", hookName)

	// Check if hook exists
	info, err := os.Stat(hookPath)
	if err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("hook '%s' not found in .hooks/", hookName)
		}
		return fmt.Errorf("failed to access hook '%s': %w", hookName, err)
	}

	// Check if it's executable
	if info.Mode()&0111 == 0 {
		return fmt.Errorf("hook '%s' is not executable (run: chmod +x %s)", hookName, hookPath)
	}

	// Check if worktree path exists
	if _, err := os.Stat(worktreePath); err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("worktree path '%s' does not exist", worktreePath)
		}
		return fmt.Errorf("failed to access worktree path '%s': %w", worktreePath, err)
	}

	fmt.Printf("Running hook '%s' at '%s'...\n", hookName, worktreePath)
	fmt.Println()

	if err := worktree.RunHook(hookName, worktreePath); err != nil {
		return fmt.Errorf("hook failed: %w", err)
	}

	fmt.Println()
	fmt.Printf("✓ Hook '%s' completed successfully\n", hookName)
	return nil
}
