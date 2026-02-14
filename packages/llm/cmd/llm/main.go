package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"dotfiles/packages/llm/internal/commit"
)

var (
	version = "dev"
	model   string
	apiKey  string
	full    bool
	amend   bool
)

var rootCmd = &cobra.Command{
	Use:   "llm",
	Short: "AI-powered developer tools",
	Long:  "A collection of AI-powered developer tools.",
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number of llm",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(version)
	},
}

var commitCmd = &cobra.Command{
	Use:   "commit",
	Short: "AI-powered commit message generator",
	Long:  "Generates conventional commit messages using Claude AI.",
	RunE: func(cmd *cobra.Command, args []string) error {
		// Get API key from env if not provided via flag
		if apiKey == "" {
			apiKey = os.Getenv("ANTHROPIC_API_KEY")
		}
		if apiKey == "" {
			return fmt.Errorf("ANTHROPIC_API_KEY not set")
		}

		cfg := commit.Config{
			Model:  model,
			APIKey: apiKey,
			Full:   full,
			Amend:  amend,
		}

		return commit.GenerateCommit(cfg, ".")
	},
}

func init() {
	rootCmd.AddCommand(commitCmd)
	rootCmd.AddCommand(versionCmd)
	commitCmd.Flags().StringVarP(&model, "model", "m", "claude-sonnet-4-20250514", "Claude model to use")
	commitCmd.Flags().StringVar(&apiKey, "api-key", "", "Anthropic API key (or ANTHROPIC_API_KEY env var)")
	commitCmd.Flags().BoolVarP(&full, "full", "f", false, "Include full file diff context")
	commitCmd.Flags().BoolVarP(&amend, "amend", "a", false, "Amend the previous commit")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
