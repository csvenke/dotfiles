package commit

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// mockRepository is a test double for git.Repository
type mockRepository struct {
	hasStagedChanges    bool
	hasStagedChangesErr error
	branch              string
	branchErr           error
	recentCommits       string
	recentCommitsErr    error
	diffStat            string
	diffStatErr         error
	stagedDiff          string
	stagedDiffErr       error
}

func (m *mockRepository) HasStagedChanges() (bool, error) {
	return m.hasStagedChanges, m.hasStagedChangesErr
}

func (m *mockRepository) GetCurrentBranch() (string, error) {
	return m.branch, m.branchErr
}

func (m *mockRepository) GetRecentCommits(n int) (string, error) {
	return m.recentCommits, m.recentCommitsErr
}

func (m *mockRepository) GetDiffStat() (string, error) {
	return m.diffStat, m.diffStatErr
}

func (m *mockRepository) GetStagedDiff(full bool) (string, error) {
	return m.stagedDiff, m.stagedDiffErr
}

// mockClaudeClient is a test double for claude.Client
type mockClaudeClient struct {
	message    string
	messageErr error
}

func (m *mockClaudeClient) Message(ctx context.Context, prompt string) (string, error) {
	return m.message, m.messageErr
}

func TestGatherGitContext(t *testing.T) {
	tests := []struct {
		name    string
		repo    *mockRepository
		want    GitContext
		wantErr bool
		errMsg  string
	}{
		{
			name: "successful context gathering",
			repo: &mockRepository{
				branch:        "main",
				recentCommits: "commit1\ncommit2",
				diffStat:      "file.go | 5 +",
				stagedDiff:    "diff content",
			},
			want: GitContext{
				Branch:        "main",
				RecentCommits: "commit1\ncommit2",
				DiffStat:      "file.go | 5 +",
				StagedDiff:    "diff content",
			},
			wantErr: false,
		},
		{
			name: "branch error",
			repo: &mockRepository{
				branchErr: errors.New("git error"),
			},
			wantErr: true,
			errMsg:  "failed to get branch",
		},
		{
			name: "recent commits error",
			repo: &mockRepository{
				branch:           "main",
				recentCommitsErr: errors.New("git error"),
			},
			wantErr: true,
			errMsg:  "failed to get recent commits",
		},
		{
			name: "diff stat error",
			repo: &mockRepository{
				branch:        "main",
				recentCommits: "commit1",
				diffStatErr:   errors.New("git error"),
			},
			wantErr: true,
			errMsg:  "failed to get diff stat",
		},
		{
			name: "staged diff error",
			repo: &mockRepository{
				branch:        "main",
				recentCommits: "commit1",
				diffStat:      "stat",
				stagedDiffErr: errors.New("git error"),
			},
			wantErr: true,
			errMsg:  "failed to get staged diff",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := gatherGitContext(tt.repo, false)

			if tt.wantErr {
				if err == nil {
					t.Error("expected error, got nil")
					return
				}
				if !strings.Contains(err.Error(), tt.errMsg) {
					t.Errorf("error = %v, should contain %v", err.Error(), tt.errMsg)
				}
				return
			}

			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}

			if got != tt.want {
				t.Errorf("got = %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestGenerateCommitWithRepo_NoStagedChanges(t *testing.T) {
	repo := &mockRepository{
		hasStagedChanges: false,
	}

	cfg := Config{
		Model:  "claude-3-opus",
		APIKey: "test-key",
	}

	err := generateCommitWithRepo(cfg, repo)
	if err != nil {
		t.Errorf("expected no error for no staged changes, got: %v", err)
	}
}

func TestGenerateCommitWithRepo_HasStagedChangesError(t *testing.T) {
	repo := &mockRepository{
		hasStagedChangesErr: errors.New("git error"),
	}

	cfg := Config{
		Model:  "claude-3-opus",
		APIKey: "test-key",
	}

	err := generateCommitWithRepo(cfg, repo)
	if err == nil {
		t.Error("expected error for staged changes check failure")
		return
	}
	if !strings.Contains(err.Error(), "failed to check staged changes") {
		t.Errorf("error should mention staged changes check: %v", err)
	}
}

func TestGenerateCommitWithRepo_GitContextError(t *testing.T) {
	repo := &mockRepository{
		hasStagedChanges: true,
		branchErr:        errors.New("git error"),
	}

	cfg := Config{
		Model:  "claude-3-opus",
		APIKey: "test-key",
	}

	err := generateCommitWithRepo(cfg, repo)
	if err == nil {
		t.Error("expected error for git context failure")
		return
	}
	if !strings.Contains(err.Error(), "failed to gather git context") {
		t.Errorf("error should mention git context: %v", err)
	}
}

func createMockEditor(t *testing.T, exitCmd string) string {
	t.Helper()
	tempDir := t.TempDir()
	editorPath := filepath.Join(tempDir, "mock-editor")

	script := fmt.Sprintf("#!/bin/sh\n%s\n", exitCmd)
	if err := os.WriteFile(editorPath, []byte(script), 0755); err != nil {
		t.Fatalf("failed to create mock editor: %v", err)
	}

	return editorPath
}

func TestExecuteCommit(t *testing.T) {
	// These tests require git to be available
	// We'll create a temporary git repository for testing

	t.Run("commit without amend", func(t *testing.T) {
		mockEditor := createMockEditor(t, "exit 0")
		t.Setenv("EDITOR", mockEditor)

		tempDir := t.TempDir()

		// Initialize git repo
		initCmd := exec.Command("git", "init")
		initCmd.Dir = tempDir
		if err := initCmd.Run(); err != nil {
			t.Skip("git not available")
		}

		// Configure git user
		emailCmd := exec.Command("git", "config", "user.email", "test@example.com")
		emailCmd.Dir = tempDir
		if err := emailCmd.Run(); err != nil {
			t.Fatalf("failed to set git user.email: %v", err)
		}
		nameCmd := exec.Command("git", "config", "user.name", "Test User")
		nameCmd.Dir = tempDir
		if err := nameCmd.Run(); err != nil {
			t.Fatalf("failed to set git user.name: %v", err)
		}

		// Create a file and stage it
		testFile := filepath.Join(tempDir, "test.txt")
		if err := os.WriteFile(testFile, []byte("content"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		stageCmd := exec.Command("git", "add", "test.txt")
		stageCmd.Dir = tempDir
		if err := stageCmd.Run(); err != nil {
			t.Fatalf("failed to stage file: %v", err)
		}

		// Execute commit
		oldDir, _ := os.Getwd()
		os.Chdir(tempDir)
		defer os.Chdir(oldDir)

		err := executeCommit("Test commit message", false)
		if err != nil {
			t.Errorf("commit failed: %v", err)
		}

		// Verify commit was made
		logCmd := exec.Command("git", "log", "-1", "--pretty=%B")
		logCmd.Dir = tempDir
		output, err := logCmd.Output()
		if err != nil {
			t.Fatalf("failed to get log: %v", err)
		}
		if !strings.Contains(string(output), "Test commit message") {
			t.Errorf("commit message not found in log: %s", string(output))
		}
	})
}
