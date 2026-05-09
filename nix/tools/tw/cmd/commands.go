package cmd

import "github.com/spf13/cobra"

func Setup(root *cobra.Command) {
	root.AddCommand(statusCmd, initCmd, phaseCmd, planCmd, taskCmd, waveCmd, todoCmd, memoryCmd, reviewCmd, epicCmd)
}
