package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/spf13/cobra"
)

var planFilePath string

var planCmd = &cobra.Command{
	Use:   "plan",
	Short: "Plan management commands",
}

var planDraftCmd = &cobra.Command{
	Use:   "draft",
	Short: "Record plan file path",
	RunE:  runPlanDraft,
}

var planApproveCmd = &cobra.Command{
	Use:   "approve",
	Short: "Approve recorded plan",
	RunE:  runPlanApprove,
}

func init() {
	planCmd.AddCommand(planDraftCmd, planApproveCmd)
	planDraftCmd.Flags().StringVar(&planFilePath, "file", "", "Path to plan markdown file")
	_ = planDraftCmd.MarkFlagRequired("file")
}

func runPlanDraft(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	s.Plan.TextPath = planFilePath

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"text_path": s.Plan.TextPath,
			"success":   true,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Plan draft recorded: %s\n", s.Plan.TextPath)
	return nil
}

func runPlanApprove(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if s.Plan.TextPath == "" {
		if jsonOutput {
			out := map[string]interface{}{"approved": false, "error": "no plan draft recorded"}
			data, _ := json.MarshalIndent(out, "", "  ")
			fmt.Println(string(data))
		}
		return fmt.Errorf("no plan draft recorded. Run `tw plan draft --file <path>` first")
	}

	info, err := os.Stat(s.Plan.TextPath)
	if err != nil || info.Size() == 0 {
		if jsonOutput {
			out := map[string]interface{}{"approved": false, "error": "plan file not found or empty"}
			data, _ := json.MarshalIndent(out, "", "  ")
			fmt.Println(string(data))
		}
		return fmt.Errorf("plan file not found or empty: %s", s.Plan.TextPath)
	}

	s.Plan.Approved = true
	s.Plan.ApprovedAt = time.Now().Format(time.RFC3339)

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"approved":    true,
			"approved_at": s.Plan.ApprovedAt,
			"text_path":   s.Plan.TextPath,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Plan approved: %s\n", s.Plan.TextPath)
	return nil
}
