package commands

import (
	"fmt"

	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all worktrees",
	Long:  `List all Git worktrees with their paths, branches, and commit hashes.`,
	Aliases: []string{"ls"},
	RunE: func(cmd *cobra.Command, args []string) error {
		worktrees, err := worktree.List()
		if err != nil {
			return err
		}

		if len(worktrees) == 0 {
			fmt.Println("No worktrees found")
			return nil
		}

		for _, wt := range worktrees {
			if wt.Bare {
				fmt.Printf("%s (bare)\n", wt.Path)
				continue
			}

			branch := wt.Branch
			if branch == "" {
				branch = wt.Commit[:7]
			}

			prunable := ""
			if wt.Prunable {
				prunable = " [prunable]"
			}

			fmt.Printf("%s [%s]%s\n", wt.Path, branch, prunable)
		}

		return nil
	},
}
