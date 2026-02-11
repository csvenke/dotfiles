package git

import (
	"strings"
	"testing"
)

func TestParseWorktreeList(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected int
	}{
		{
			name: "single bare worktree",
			input: `/home/user/repo/.git
HEAD abc123
bare
`,
			expected: 1,
		},
		{
			name: "multiple worktrees",
			input: `/home/user/repo/.git
HEAD abc123
bare

/home/user/repo/main
HEAD abc123
branch refs/heads/main

/home/user/repo/feature
HEAD def456
branch refs/heads/feature
`,
			expected: 3,
		},
		{
			name: "worktree with detached HEAD",
			input: `/home/user/repo/main
HEAD abc123
detached
`,
			expected: 1,
		},
		{
			name: "prunable worktree",
			input: `/home/user/repo/.git
HEAD abc123
bare

/home/user/repo/old-branch
HEAD def456
branch refs/heads/old-branch
prunable
`,
			expected: 2,
		},
		{
			name: "empty input",
			input: "",
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ParseWorktreeList(tt.input)
			if len(result) != tt.expected {
				t.Errorf("expected %d worktrees, got %d", tt.expected, len(result))
			}
		})
	}
}

func TestParseWorktreeListFields(t *testing.T) {
	input := `/home/user/repo/.git
HEAD abc123def456789
bare

/home/user/repo/main
HEAD 111111222222333
branch refs/heads/main

/home/user/repo/feature
HEAD 444444555555666
detached
prunable
`

	worktrees := ParseWorktreeList(input)

	if len(worktrees) != 3 {
		t.Fatalf("expected 3 worktrees, got %d", len(worktrees))
	}

	// Check first worktree (bare)
	if !worktrees[0].Bare {
		t.Errorf("expected first worktree to be bare")
	}
	if worktrees[0].Path != "/home/user/repo/.git" {
		t.Errorf("expected path '/home/user/repo/.git', got '%s'", worktrees[0].Path)
	}
	if worktrees[0].Commit != "abc123def456789" {
		t.Errorf("expected commit 'abc123def456789', got '%s'", worktrees[0].Commit)
	}

	// Check second worktree (main branch)
	if worktrees[1].Branch != "main" {
		t.Errorf("expected branch 'main', got '%s'", worktrees[1].Branch)
	}
	if worktrees[1].Detached {
		t.Errorf("expected main worktree to not be detached")
	}

	// Check third worktree (detached, prunable)
	if !worktrees[2].Detached {
		t.Errorf("expected third worktree to be detached")
	}
	if !worktrees[2].Prunable {
		t.Errorf("expected third worktree to be prunable")
	}
}

func TestParseWorktreeListPrunableDetection(t *testing.T) {
	input := `/home/user/repo/main
HEAD abc123
branch refs/heads/main

/home/user/repo/stale
HEAD def456
branch refs/heads/stale
prunable
`

	worktrees := ParseWorktreeList(input)

	if len(worktrees) != 2 {
		t.Fatalf("expected 2 worktrees, got %d", len(worktrees))
	}

	if worktrees[0].Prunable {
		t.Errorf("expected main worktree to not be prunable")
	}
	if !worktrees[1].Prunable {
		t.Errorf("expected stale worktree to be prunable")
	}
}

func TestParseWorktreeListBranchParsing(t *testing.T) {
	input := `/home/user/repo/main
HEAD abc123
branch refs/heads/main

/home/user/repo/feature/test
HEAD def456
branch refs/heads/feature/test
`

	worktrees := ParseWorktreeList(input)

	if len(worktrees) != 2 {
		t.Fatalf("expected 2 worktrees, got %d", len(worktrees))
	}

	if worktrees[0].Branch != "main" {
		t.Errorf("expected branch 'main', got '%s'", worktrees[0].Branch)
	}
	if worktrees[1].Branch != "feature/test" {
		t.Errorf("expected branch 'feature/test', got '%s'", worktrees[1].Branch)
	}
}

func TestWorktreeListPrunable(t *testing.T) {
	// This test parses the output format that would come from
	// 'git worktree list --porcelain' with prunable worktrees
	input := `/home/user/repo/.git
HEAD abc123
bare

/home/user/repo/main
HEAD def456
branch refs/heads/main

/home/user/repo/old-feature
HEAD 789abc
branch refs/heads/old-feature
prunable
`

	lines := strings.Split(input, "\n")
	var branches []string
	for i, line := range lines {
		if strings.HasPrefix(line, "prunable") && i > 0 {
			prevLine := lines[i-1]
			if strings.HasPrefix(prevLine, "branch refs/heads/") {
				branch := strings.TrimPrefix(prevLine, "branch refs/heads/")
				branches = append(branches, branch)
			}
		}
	}

	if len(branches) != 1 {
		t.Errorf("expected 1 prunable branch, got %d", len(branches))
	}

	if len(branches) > 0 && branches[0] != "old-feature" {
		t.Errorf("expected branch 'old-feature', got '%s'", branches[0])
	}
}
