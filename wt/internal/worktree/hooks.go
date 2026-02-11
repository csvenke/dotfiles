package worktree

import (
	"fmt"
	"os"
	"path/filepath"
)

// Hook names
const (
	HookAfterWorktreeAdd = "after-worktree-add.sh"
)

// HookInfo represents information about a hook
type HookInfo struct {
	Name        string
	Path        string
	Active      bool
	Executable  bool
	Description string
}

// ListHooks returns a list of all hooks in the .hooks directory
func ListHooks() ([]HookInfo, error) {
	hooksDir := ".hooks"

	// Check if directory exists
	if _, err := os.Stat(hooksDir); err != nil {
		if os.IsNotExist(err) {
			return []HookInfo{}, nil
		}
		return nil, fmt.Errorf("failed to access .hooks directory: %w", err)
	}

	entries, err := os.ReadDir(hooksDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read .hooks directory: %w", err)
	}

	var hooks []HookInfo
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()
		path := filepath.Join(hooksDir, name)
		info, err := entry.Info()
		if err != nil {
			continue
		}

		hook := HookInfo{
			Name:       name,
			Path:       path,
			Executable: info.Mode()&0111 != 0,
		}

		// A hook is active if it doesn't have .sample suffix and is executable
		if !isSampleHook(name) && hook.Executable {
			hook.Active = true
		}

		hooks = append(hooks, hook)
	}

	return hooks, nil
}

// isSampleHook checks if a hook name indicates it's a sample/template
func isSampleHook(name string) bool {
	return len(name) > 7 && name[len(name)-7:] == ".sample"
}

// GetHook returns information about a specific hook
func GetHook(name string) (*HookInfo, error) {
	hooks, err := ListHooks()
	if err != nil {
		return nil, err
	}

	for _, hook := range hooks {
		if hook.Name == name {
			return &hook, nil
		}
	}

	return nil, fmt.Errorf("hook '%s' not found", name)
}

// IsValidHook checks if a hook exists and is executable
func IsValidHook(name string) bool {
	hookPath := filepath.Join(".hooks", name)
	info, err := os.Stat(hookPath)
	if err != nil {
		return false
	}
	return info.Mode()&0111 != 0
}
