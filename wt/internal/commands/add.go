package commands

import (
	"fmt"

	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var addCmd = &cobra.Command{
	Use:   "add <branch> [path]",
	Short: "Add a new worktree",
	Long: `Add a new worktree for the specified branch.

If path is not provided, the branch name is used as the path.
After creation, .shared/ contents are copied and hooks are executed.`,
	Args: cobra.RangeArgs(1, 2),
	RunE: func(cmd *cobra.Command, args []string) error {
		branch := args[0]
		var path string
		if len(args) > 1 {
			path = args[1]
		}

		if err := worktree.Add(branch, path); err != nil {
			return err
		}

		if path == "" {
			path = branch
		}

		fmt.Printf("Created worktree '%s' for branch '%s'\n", path, branch)
		return nil
	},
}
