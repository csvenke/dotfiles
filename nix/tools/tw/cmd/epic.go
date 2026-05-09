package cmd

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/csvenke/dotfiles/tools/tw/internal/mempalace"
	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
	"github.com/csvenke/dotfiles/tools/tw/internal/workflow"
	"github.com/spf13/cobra"
)

var epicCmd = &cobra.Command{
	Use:   "epic",
	Short: "Epic management commands",
}

var epicCloseCmd = &cobra.Command{
	Use:   "close",
	Short: "Close epic after gate validation",
	RunE:  runEpicClose,
}

func init() {
	epicCmd.AddCommand(epicCloseCmd)
}

func runEpicClose(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	openTasks, err := tk.LS("open", "team-task")
	if err != nil {
		return fmt.Errorf("gate validation error: list open tasks: %w", err)
	}
	inProgressTasks, err := tk.LS("in_progress", "team-task")
	if err != nil {
		return fmt.Errorf("gate validation error: list in_progress tasks: %w", err)
	}
	if len(openTasks) > 0 || len(inProgressTasks) > 0 {
		return fmt.Errorf("gate failed: open or in-progress tasks remain")
	}
	if !s.Tasks.StaffReview.Passed {
		return fmt.Errorf("gate failed: staff review not passed")
	}

	if s.EpicID == "" {
		return fmt.Errorf("no epic initialized")
	}

	if err := tk.Close(s.EpicID); err != nil {
		return fmt.Errorf("tk close failed: %w", err)
	}

	if s.MemoryMode == "active" {
		wing, _ := resolveWing(s, projectDir)
		if wing == "" {
			wing = "general"
		}
		outcome := fmt.Sprintf("Epic %s closed. All tasks completed. Staff review passed.", s.EpicID)
		if err := mempalace.AddDrawer(wing, "general", outcome); err != nil {
			fmt.Fprintf(os.Stderr, "warning: final memory writeback failed: %v\n", err)
		}
	}

	s.Phase = workflow.PhaseComplete
	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"epic_id": s.EpicID,
			"closed":  true,
			"phase":   s.Phase,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Epic %s closed\n", s.EpicID)
	return nil
}