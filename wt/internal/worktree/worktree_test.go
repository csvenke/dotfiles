package worktree

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCopyRecursive(t *testing.T) {
	// Create temp directories
	srcDir := t.TempDir()
	dstDir := t.TempDir()

	// Create a source file
	srcFile := filepath.Join(srcDir, "test.txt")
	content := []byte("test content")
	if err := os.WriteFile(srcFile, content, 0644); err != nil {
		t.Fatalf("failed to create test file: %v", err)
	}

	// Copy the file
	dstFile := filepath.Join(dstDir, "test.txt")
	if err := copyRecursive(srcFile, dstFile); err != nil {
		t.Fatalf("copyRecursive failed: %v", err)
	}

	// Verify file was copied
	copied, err := os.ReadFile(dstFile)
	if err != nil {
		t.Fatalf("failed to read copied file: %v", err)
	}
	if string(copied) != string(content) {
		t.Errorf("expected '%s', got '%s'", string(content), string(copied))
	}
}

func TestCopyRecursiveDirectory(t *testing.T) {
	// Create temp directories
	srcDir := t.TempDir()
	dstDir := t.TempDir()

	// Create nested directory structure
	nestedDir := filepath.Join(srcDir, "nested")
	if err := os.MkdirAll(nestedDir, 0755); err != nil {
		t.Fatalf("failed to create nested dir: %v", err)
	}

	nestedFile := filepath.Join(nestedDir, "file.txt")
	content := []byte("nested content")
	if err := os.WriteFile(nestedFile, content, 0644); err != nil {
		t.Fatalf("failed to create nested file: %v", err)
	}

	// Copy the directory
	dstNestedDir := filepath.Join(dstDir, "nested")
	if err := copyRecursive(nestedDir, dstNestedDir); err != nil {
		t.Fatalf("copyRecursive failed: %v", err)
	}

	// Verify file was copied
	dstNestedFile := filepath.Join(dstNestedDir, "file.txt")
	copied, err := os.ReadFile(dstNestedFile)
	if err != nil {
		t.Fatalf("failed to read copied file: %v", err)
	}
	if string(copied) != string(content) {
		t.Errorf("expected '%s', got '%s'", string(content), string(copied))
	}
}

func TestIsSampleHook(t *testing.T) {
	tests := []struct {
		name     string
		expected bool
	}{
		{"after-worktree-add.sh", false},
		{"after-worktree-add.sh.sample", true},
		{"test.sh.sample", true},
		{"hook.sample", true},
		{"hook", false},
		{"", false},
	}

	for _, tt := range tests {
		result := isSampleHook(tt.name)
		if result != tt.expected {
			t.Errorf("isSampleHook(%q) = %v, expected %v", tt.name, result, tt.expected)
		}
	}
}

func TestListHooks(t *testing.T) {
	// Create temp directory with .hooks
	tmpDir := t.TempDir()
	originalWd, _ := os.Getwd()
	os.Chdir(tmpDir)
	defer os.Chdir(originalWd)

	hooksDir := filepath.Join(tmpDir, ".hooks")
	if err := os.MkdirAll(hooksDir, 0755); err != nil {
		t.Fatalf("failed to create hooks dir: %v", err)
	}

	// Create test hooks
	activeHook := filepath.Join(hooksDir, "active.sh")
	if err := os.WriteFile(activeHook, []byte("#!/bin/bash\necho test"), 0755); err != nil {
		t.Fatalf("failed to create active hook: %v", err)
	}

	sampleHook := filepath.Join(hooksDir, "sample.sh.sample")
	if err := os.WriteFile(sampleHook, []byte("# sample"), 0644); err != nil {
		t.Fatalf("failed to create sample hook: %v", err)
	}

	nonExecHook := filepath.Join(hooksDir, "non-exec.sh")
	if err := os.WriteFile(nonExecHook, []byte("# not executable"), 0644); err != nil {
		t.Fatalf("failed to create non-exec hook: %v", err)
	}

	hooks, err := ListHooks()
	if err != nil {
		t.Fatalf("ListHooks failed: %v", err)
	}

	if len(hooks) != 3 {
		t.Errorf("expected 3 hooks, got %d", len(hooks))
	}

	// Find active hook
	var foundActive bool
	for _, h := range hooks {
		if h.Name == "active.sh" {
			foundActive = true
			if !h.Active {
				t.Errorf("expected active.sh to be active")
			}
			if !h.Executable {
				t.Errorf("expected active.sh to be executable")
			}
		}
	}
	if !foundActive {
		t.Errorf("did not find active.sh")
	}
}

func TestListHooksNoDirectory(t *testing.T) {
	// Create temp directory without .hooks
	tmpDir := t.TempDir()
	originalWd, _ := os.Getwd()
	os.Chdir(tmpDir)
	defer os.Chdir(originalWd)

	hooks, err := ListHooks()
	if err != nil {
		t.Fatalf("ListHooks failed: %v", err)
	}

	if len(hooks) != 0 {
		t.Errorf("expected 0 hooks, got %d", len(hooks))
	}
}

func TestGetHook(t *testing.T) {
	// Create temp directory with .hooks
	tmpDir := t.TempDir()
	originalWd, _ := os.Getwd()
	os.Chdir(tmpDir)
	defer os.Chdir(originalWd)

	hooksDir := filepath.Join(tmpDir, ".hooks")
	if err := os.MkdirAll(hooksDir, 0755); err != nil {
		t.Fatalf("failed to create hooks dir: %v", err)
	}

	// Create test hook
	hookFile := filepath.Join(hooksDir, "test.sh")
	if err := os.WriteFile(hookFile, []byte("#!/bin/bash"), 0755); err != nil {
		t.Fatalf("failed to create hook: %v", err)
	}

	hook, err := GetHook("test.sh")
	if err != nil {
		t.Fatalf("GetHook failed: %v", err)
	}

	if hook.Name != "test.sh" {
		t.Errorf("expected name 'test.sh', got '%s'", hook.Name)
	}

	// Test non-existent hook
	_, err = GetHook("nonexistent.sh")
	if err == nil {
		t.Errorf("expected error for non-existent hook")
	}
}

func TestIsValidHook(t *testing.T) {
	// Create temp directory with .hooks
	tmpDir := t.TempDir()
	originalWd, _ := os.Getwd()
	os.Chdir(tmpDir)
	defer os.Chdir(originalWd)

	hooksDir := filepath.Join(tmpDir, ".hooks")
	if err := os.MkdirAll(hooksDir, 0755); err != nil {
		t.Fatalf("failed to create hooks dir: %v", err)
	}

	// Create executable hook
	execHook := filepath.Join(hooksDir, "valid.sh")
	if err := os.WriteFile(execHook, []byte("#!/bin/bash"), 0755); err != nil {
		t.Fatalf("failed to create hook: %v", err)
	}

	// Create non-executable hook
	nonExecHook := filepath.Join(hooksDir, "invalid.sh")
	if err := os.WriteFile(nonExecHook, []byte("#!/bin/bash"), 0644); err != nil {
		t.Fatalf("failed to create hook: %v", err)
	}

	if !IsValidHook("valid.sh") {
		t.Errorf("expected valid.sh to be valid")
	}

	if IsValidHook("invalid.sh") {
		t.Errorf("expected invalid.sh to be invalid")
	}

	if IsValidHook("nonexistent.sh") {
		t.Errorf("expected nonexistent.sh to be invalid")
	}
}
