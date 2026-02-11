package worktree

import (
	"os"
	"path/filepath"
	"testing"
)

func TestIsWorktreeRoot(t *testing.T) {
	tests := []struct {
		name     string
		setup    func(string)
		expected bool
	}{
		{
			name: "valid worktree root",
			setup: func(dir string) {
				os.MkdirAll(filepath.Join(dir, ".git"), 0755)
				os.WriteFile(filepath.Join(dir, ".git", "HEAD"), []byte("ref: refs/heads/main\n"), 0644)
			},
			expected: true,
		},
		{
			name:     "no .git directory",
			setup:    func(dir string) {},
			expected: false,
		},
		{
			name: ".git exists but no HEAD",
			setup: func(dir string) {
				os.MkdirAll(filepath.Join(dir, ".git"), 0755)
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create temp directory
			tmpDir := t.TempDir()
			originalWd, _ := os.Getwd()
			os.Chdir(tmpDir)
			defer os.Chdir(originalWd)

			// Setup test conditions
			tt.setup(tmpDir)

			// Test
			result := IsWorktreeRoot()
			if result != tt.expected {
				t.Errorf("IsWorktreeRoot() = %v, expected %v", result, tt.expected)
			}
		})
	}
}

func TestHasNix(t *testing.T) {
	// This is a simple smoke test - we can't easily test the actual behavior
	// without knowing if nix is installed on the system
	result := hasNix()

	// Just verify it doesn't panic and returns a boolean
	_ = result
}

func TestSampleHookContent(t *testing.T) {
	// Verify the sample hook content contains expected elements
	expectedElements := []string{
		"#!/usr/bin/env bash",
		"after a new worktree is created",
		"To enable this hook",
		"rename this file",
	}

	for _, element := range expectedElements {
		if !contains(sampleHookContent, element) {
			t.Errorf("sample hook content missing: %s", element)
		}
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsAt(s, substr))
}

func containsAt(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
