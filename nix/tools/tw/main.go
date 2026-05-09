package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/csvenke/dotfiles/tools/tw/cmd"
	"github.com/spf13/cobra"
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "tw",
		Short: "Team workflow CLI for AI agent orchestration",
	}

	cwd, err := os.Getwd()
	if err != nil {
		cwd = ""
	}
	home := os.Getenv("HOME")
	stateDirDefault := ""
	if home != "" {
		stateDirDefault = filepath.Join(home, ".local", "share", "team-workflow")
	}

	rootCmd.PersistentFlags().Bool("json", false, "Output structured JSON")
	rootCmd.PersistentFlags().String("project-dir", cwd, "Project directory")
	rootCmd.PersistentFlags().String("state-dir", stateDirDefault, "State storage directory")

	cmd.Setup(rootCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
