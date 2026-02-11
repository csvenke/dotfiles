package commands

import (
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "wt",
	Short: "Git worktree management utility",
	Long: `wt is a CLI tool for managing Git worktrees.

It provides an interactive interface for adding, removing, switching,
and pruning worktrees with support for hooks and shared configuration.`,
}

// Execute runs the root command
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	// Add subcommands
	rootCmd.AddCommand(addCmd)
	rootCmd.AddCommand(removeCmd)
	rootCmd.AddCommand(switchCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(pruneCmd)
	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(cloneCmd)
	rootCmd.AddCommand(migrateCmd)
	rootCmd.AddCommand(doctorCmd)
	rootCmd.AddCommand(hookCmd)
}
