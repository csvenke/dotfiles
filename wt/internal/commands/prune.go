package commands

import (
	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var pruneCmd = &cobra.Command{
	Use:   "prune",
	Short: "Prune orphaned worktrees",
	Long: `Prune orphaned worktrees and delete their associated branches.

This command runs 'git worktree prune' and then deletes branches that
were associated with pruned worktrees.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return worktree.Prune()
	},
}
