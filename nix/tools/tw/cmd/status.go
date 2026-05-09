package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
	"github.com/csvenke/dotfiles/tools/tw/internal/workflow"
	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show current workflow status",
	RunE:  runStatus,
}

func runStatus(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	open, _ := tk.LS("open", "team-task")
	closed, _ := tk.LS("closed", "team-task")
	ready, _ := tk.Ready("team-task")

	stepName := workflow.StepName(s.Wave.CurrentStep)

	if jsonOutput {
		out := map[string]interface{}{
			"phase":       s.Phase,
			"wave":        s.Wave.Number,
			"step":        s.Wave.CurrentStep,
			"step_name":   stepName,
			"epic_id":     s.EpicID,
			"memory_mode": s.MemoryMode,
			"wing":        s.Wing,
			"task_counts": map[string]int{
				"active": len(s.Tasks.Active),
				"closed": len(closed),
				"open":   len(open),
				"ready":  len(ready),
			},
		}
		data, err := json.MarshalIndent(out, "", "  ")
		if err != nil {
			return err
		}
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Phase: %s\n", s.Phase)
	fmt.Printf("Wave: %d\n", s.Wave.Number)
	fmt.Printf("Step: %d (%s)\n", s.Wave.CurrentStep, stepName)
	fmt.Printf("Epic: %s\n", s.EpicID)
	fmt.Printf("Memory: %s\n", s.MemoryMode)
	fmt.Printf("Wing: %s\n", s.Wing)
	fmt.Printf("Tasks: %d active, %d closed, %d open, %d ready\n", len(s.Tasks.Active), len(closed), len(open), len(ready))
	return nil
}
