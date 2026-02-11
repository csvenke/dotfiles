package worktree

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/csvenke/wt/internal/git"
)

// Add creates a new worktree with the specified branch and path
func Add(branch string, path string) error {
	if path == "" {
		path = branch
	}

	// Run git worktree add
	if err := git.WorktreeAdd(branch, path); err != nil {
		return fmt.Errorf("failed to add worktree: %w", err)
	}

	// Setup worktree (copy .shared contents)
	if err := Setup(path); err != nil {
		return fmt.Errorf("failed to setup worktree: %w", err)
	}

	// Run hook
	if err := RunHook("after-worktree-add.sh", path); err != nil {
		// Don't fail if hook fails, just log it
		fmt.Fprintf(os.Stderr, "Warning: hook failed: %v\n", err)
	}

	return nil
}

// Remove removes a worktree at the specified path
func Remove(path string) error {
	return git.WorktreeRemove(path)
}

// List returns all worktrees
func List() ([]git.WorktreeInfo, error) {
	return git.WorktreeList()
}

// Switch changes to the specified worktree directory
func Switch(path string) error {
	// We can't actually change the working directory of the parent shell
	// from a child process. This is a limitation we work around by
	// outputting the path for shell integration.
	fmt.Println(path)
	return nil
}

// Prune prunes orphaned worktrees and deletes their branches
func Prune() error {
	branches, err := git.WorktreeListPrunable()
	if err != nil {
		return fmt.Errorf("failed to list prunable worktrees: %w", err)
	}

	if len(branches) == 0 {
		fmt.Println("No prunable worktrees")
		return nil
	}

	// Prune worktrees
	if err := git.WorktreePrune(); err != nil {
		return fmt.Errorf("failed to prune worktrees: %w", err)
	}

	// Delete branches
	for _, branch := range branches {
		if err := git.BranchDelete(branch); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to delete branch %s: %v\n", branch, err)
		} else {
			fmt.Printf("Deleted branch: %s\n", branch)
		}
	}

	return nil
}

// Setup configures a worktree by copying .shared contents and running direnv
func Setup(path string) error {
	// Copy .shared contents
	if err := copyShared(path); err != nil {
		return err
	}

	// Run direnv allow if .envrc exists
	if err := runDirenvAllow(path); err != nil {
		// Don't fail if direnv fails
		fmt.Fprintf(os.Stderr, "Warning: direnv allow failed: %v\n", err)
	}

	return nil
}

// copyShared copies contents from .shared directory to the worktree path
func copyShared(path string) error {
	sharedDir := ".shared"
	if _, err := os.Stat(sharedDir); os.IsNotExist(err) {
		return nil
	}

	entries, err := os.ReadDir(sharedDir)
	if err != nil {
		return fmt.Errorf("failed to read .shared: %w", err)
	}

	for _, entry := range entries {
		srcPath := filepath.Join(sharedDir, entry.Name())
		dstPath := filepath.Join(path, entry.Name())

		if err := copyRecursive(srcPath, dstPath); err != nil {
			return fmt.Errorf("failed to copy %s: %w", srcPath, err)
		}
	}

	return nil
}

// copyRecursive copies a file or directory recursively
func copyRecursive(src, dst string) error {
	info, err := os.Stat(src)
	if err != nil {
		return err
	}

	if info.IsDir() {
		if err := os.MkdirAll(dst, info.Mode()); err != nil {
			return err
		}

		entries, err := os.ReadDir(src)
		if err != nil {
			return err
		}

		for _, entry := range entries {
			srcChild := filepath.Join(src, entry.Name())
			dstChild := filepath.Join(dst, entry.Name())
			if err := copyRecursive(srcChild, dstChild); err != nil {
				return err
			}
		}
		return nil
	}

	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}

	return os.WriteFile(dst, data, info.Mode())
}

// runDirenvAllow runs direnv allow on the path if .envrc exists
func runDirenvAllow(path string) error {
	envrcPath := filepath.Join(path, ".envrc")
	if _, err := os.Stat(envrcPath); os.IsNotExist(err) {
		return nil
	}

	if _, err := exec.LookPath("direnv"); err != nil {
		return nil
	}

	cmd := exec.Command("direnv", "allow", path)
	return cmd.Run()
}

// RunHook executes a hook script in the worktree
func RunHook(hookName, worktreePath string) error {
	hookPath := filepath.Join(".hooks", hookName)

	info, err := os.Stat(hookPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}

	if info.Mode()&0111 == 0 {
		return nil
	}

	// Check if direnv is available and .envrc exists
	hasDirenv := false
	if _, err := exec.LookPath("direnv"); err == nil {
		envrcPath := filepath.Join(worktreePath, ".envrc")
		if _, err := os.Stat(envrcPath); err == nil {
			hasDirenv = true
		}
	}

	if hasDirenv {
		// Run with direnv
		cmd := exec.Command("direnv", "exec", worktreePath, "bash", "-c",
			fmt.Sprintf("cd '%s' && '%s'", worktreePath, hookPath))
		cmd.Dir = worktreePath
		return cmd.Run()
	}

	// Run directly
	cmd := exec.Command(hookPath)
	cmd.Dir = worktreePath
	return cmd.Run()
}
