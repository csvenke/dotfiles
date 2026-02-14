package git

import (
	"bytes"
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/go-git/go-git/v5/plumbing/format/diff"
	"github.com/go-git/go-git/v5/plumbing/format/index"
	"github.com/go-git/go-git/v5/plumbing/object"
)

// Repository wraps a go-git repository
type Repository struct {
	repo *git.Repository
}

// Open opens a git repository at the given path
func Open(path string) (*Repository, error) {
	repo, err := git.PlainOpenWithOptions(path, &git.PlainOpenOptions{
		DetectDotGit: true,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to open repository: %w", err)
	}
	return &Repository{repo: repo}, nil
}

// HasStagedChanges returns true if there are staged changes in the repository
func (r *Repository) HasStagedChanges() (bool, error) {
	worktree, err := r.repo.Worktree()
	if err != nil {
		return false, fmt.Errorf("failed to get worktree: %w", err)
	}

	status, err := worktree.Status()
	if err != nil {
		return false, fmt.Errorf("failed to get status: %w", err)
	}

	for _, fileStatus := range status {
		if fileStatus.Staging != git.Unmodified {
			return true, nil
		}
	}

	return false, nil
}

// GetStagedDiff returns the diff of staged changes
// If full is true, includes all context lines (equivalent to -W)
// If full is false, includes default context lines
func (r *Repository) GetStagedDiff(full bool) (string, error) {
	head, err := r.repo.Head()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD: %w", err)
	}

	headCommit, err := r.repo.CommitObject(head.Hash())
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD commit: %w", err)
	}

	headTree, err := headCommit.Tree()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD tree: %w", err)
	}

	// Get the index and build index tree
	idx, err := r.repo.Storer.Index()
	if err != nil {
		return "", fmt.Errorf("failed to get index: %w", err)
	}

	indexTree := buildTreeFromIndex(idx)

	// Get diff between HEAD tree and index tree (staged changes)
	changes, err := object.DiffTree(headTree, indexTree)
	if err != nil {
		return "", fmt.Errorf("failed to diff trees: %w", err)
	}

	// Encode the diff
	var buf bytes.Buffer
	contextLines := diff.DefaultContextLines
	if full {
		contextLines = 1000000 // Large number to effectively show all context
	}

	encoder := diff.NewUnifiedEncoder(&buf, contextLines)

	for _, change := range changes {
		var patch *object.Patch
		var patchErr error
		func() {
			defer func() {
				if r := recover(); r != nil {
					patchErr = fmt.Errorf("recovered from panic in change.Patch: %v", r)
				}
			}()
			patch, patchErr = change.Patch()
		}()

		if patchErr != nil {
			continue
		}

		if err := encoder.Encode(patch); err != nil {
			return "", fmt.Errorf("failed to encode patch: %w", err)
		}
	}

	return buf.String(), nil
}

// GetDiffStat returns a summary of staged changes (like `git diff --stat`)
func (r *Repository) GetDiffStat() (string, error) {
	head, err := r.repo.Head()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD: %w", err)
	}

	headCommit, err := r.repo.CommitObject(head.Hash())
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD commit: %w", err)
	}

	headTree, err := headCommit.Tree()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD tree: %w", err)
	}

	// Get the index and build index tree
	idx, err := r.repo.Storer.Index()
	if err != nil {
		return "", fmt.Errorf("failed to get index: %w", err)
	}

	indexTree := buildTreeFromIndex(idx)

	// Get diff between HEAD tree and index tree (staged changes)
	changes, err := object.DiffTree(headTree, indexTree)
	if err != nil {
		return "", fmt.Errorf("failed to diff trees: %w", err)
	}

	if len(changes) == 0 {
		return "", nil
	}

	// Build stat output
	var buf bytes.Buffer
	for _, change := range changes {
		var additions, deletions int
		var action, name string

		if change.From.Name == "" { // Addition
			blob, err := r.repo.BlobObject(change.To.TreeEntry.Hash)
			if err != nil {
				continue
			}
			reader, err := blob.Reader()
			if err != nil {
				continue
			}
			contentBytes, err := io.ReadAll(reader)
			reader.Close()
			if err != nil {
				continue
			}
			additions = len(strings.Split(string(contentBytes), "\n"))
			name = change.To.Name
			action = fmt.Sprintf("| %d +", additions)
		} else if change.To.Name == "" { // Deletion
			blob, err := r.repo.BlobObject(change.From.TreeEntry.Hash)
			if err != nil {
				continue
			}
			reader, err := blob.Reader()
			if err != nil {
				continue
			}
			contentBytes, err := io.ReadAll(reader)
			reader.Close()
			if err != nil {
				continue
			}
			deletions = len(strings.Split(string(contentBytes), "\n"))
			name = change.From.Name
			action = fmt.Sprintf("| %d -", deletions)
		} else { // Modification
			var patch *object.Patch
			var patchErr error
			func() {
				defer func() {
					if r := recover(); r != nil {
						patchErr = fmt.Errorf("recovered from panic in change.Patch: %v", r)
					}
				}()
				patch, patchErr = change.Patch()
			}()

			if patchErr != nil {
				continue
			}
			fileStats := patch.Stats()
			for _, s := range fileStats {
				additions += s.Addition
				deletions += s.Deletion
			}
			name = change.To.Name // or From.Name, they are the same
			action = fmt.Sprintf("| %d + %d -", additions, deletions)
		}

		buf.WriteString(fmt.Sprintf(" %s %s\n", name, action))
	}

	return buf.String(), nil
}

// GetRecentCommits returns the last n commit messages (subject and body)
func (r *Repository) GetRecentCommits(n int) (string, error) {
	head, err := r.repo.Head()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD: %w", err)
	}

	commitIter, err := r.repo.Log(&git.LogOptions{
		From: head.Hash(),
	})
	if err != nil {
		return "", fmt.Errorf("failed to get log: %w", err)
	}
	defer commitIter.Close()

	var buf bytes.Buffer
	count := 0
	err = commitIter.ForEach(func(commit *object.Commit) error {
		if count >= n {
			return io.EOF
		}

		// Write subject (first line of message)
		buf.WriteString(commit.Message)
		buf.WriteString("\n")

		count++
		return nil
	})

	if err != nil && err != io.EOF {
		return "", fmt.Errorf("failed to iterate commits: %w", err)
	}

	return buf.String(), nil
}

// buildTreeFromIndex creates a tree object from the git index
func buildTreeFromIndex(idx *index.Index) *object.Tree {
	tree := &object.Tree{}
	for _, entry := range idx.Entries {
		tree.Entries = append(tree.Entries, object.TreeEntry{
			Name: entry.Name,
			Mode: entry.Mode,
			Hash: entry.Hash,
		})
	}
	// Sort entries to match git's tree entry ordering
	sort.Slice(tree.Entries, func(i, j int) bool {
		return tree.Entries[i].Name < tree.Entries[j].Name
	})
	return tree
}

// GetCurrentBranch returns the name of the current branch
func (r *Repository) GetCurrentBranch() (string, error) {
	head, err := r.repo.Head()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD: %w", err)
	}

	if head.Type() != plumbing.HashReference {
		return "", fmt.Errorf("HEAD is not a hash reference")
	}

	// Get the short branch name from the reference name
	refName := head.Name()
	if refName.IsBranch() {
		return refName.Short(), nil
	}

	// If detached HEAD, return the hash
	return head.Hash().String()[:7], nil
}
