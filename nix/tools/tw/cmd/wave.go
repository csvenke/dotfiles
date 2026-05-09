package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
	"github.com/csvenke/dotfiles/tools/tw/internal/workflow"
	"github.com/spf13/cobra"
)

var waveCmd = &cobra.Command{
	Use:   "wave",
	Short: "Wave execution commands",
}

var waveStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Start a new wave",
	RunE:  runWaveStart,
}

var waveStepCmd = &cobra.Command{
	Use:   "step",
	Short: "Evaluate current step and report instructions",
	RunE:  runWaveStep,
}

var waveNextCmd = &cobra.Command{
	Use:   "next",
	Short: "Advance to next step",
	RunE:  runWaveNext,
}

var waveSummaryCmd = &cobra.Command{
	Use:   "summary",
	Short: "Show wave summary",
	RunE:  runWaveSummary,
}

func init() {
	waveCmd.AddCommand(waveStartCmd, waveStepCmd, waveNextCmd, waveSummaryCmd)
}

func runWaveStart(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if err := workflow.StartWave(s); err != nil {
		return err
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"wave":             s.Wave.Number,
			"current_step":     s.Wave.CurrentStep,
			"started_at":       s.Wave.StartedAt,
			"closed_this_wave": s.Tasks.ClosedThisWave,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Started wave %d\n", s.Wave.Number)
	return nil
}

func runWaveStep(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	step, skipped, done, err := workflow.EvaluateStep(s)
	if err != nil {
		return err
	}

	if done {
		if jsonOutput {
			out := map[string]interface{}{
				"done":       true,
				"next_phase": "EPIC_CLOSURE",
			}
			data, _ := json.MarshalIndent(out, "", "  ")
			fmt.Println(string(data))
			return nil
		}
		fmt.Println("No work remains. Transition to EPIC_CLOSURE.")
		return nil
	}

	// Persist auto-skipped steps
	if skipped && step != s.Wave.CurrentStep {
		s.Wave.CurrentStep = step
		if err := state.Write(statePath, s); err != nil {
			return err
		}
	}

	stepName := workflow.StepName(step)

	if jsonOutput {
		out := map[string]interface{}{
			"wave":      s.Wave.Number,
			"step":      step,
			"step_name": stepName,
			"skip":      skipped,
		}

		switch step {
		case 4:
			readyDetails, _ := tk.ReadyDetails("team-task")
			activeTasks, _ := tk.LS("in_progress", "team-task")
			out["ready_tasks"] = readyDetails
			out["active_tasks"] = activeTasks
			out["instructions"] = "Dispatch software-engineer for ready tasks. Include <global_rules> and <task_brief> with repo bootstrap, invariant brief, memory context, and UX notes when present."
			out["next_agent_hint"] = "software-engineer"
		case 8:
			baseBranch := s.Bootstrap.BaseBranch
			if baseBranch == "" {
				baseBranch = "main"
			}
			reviewCmd := fmt.Sprintf("git diff %s", baseBranch)
			out["instructions"] = fmt.Sprintf("Run staff-engineer review. Review surface: %s.", reviewCmd)
			out["review_surface_command"] = reviewCmd
		default:
			out["instructions"] = stepInstructions(step)
		}

		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Wave: %d\n", s.Wave.Number)
	fmt.Printf("Step: %d (%s)\n", step, stepName)
	if skipped {
		fmt.Println("Note: skipped conditional steps")
	}
	fmt.Printf("Instructions: %s\n", stepInstructions(step))
	return nil
}

func stepInstructions(step int) string {
	switch step {
	case 0:
		return "Run repo bootstrap commands."
	case 1:
		return "Find ready work. Call `tw task ready` for details."
	case 2:
		return "Run domain brief for domain-heavy or underspecified tasks."
	case 3:
		return "Run UX design for UI tasks."
	case 4:
		return "Dispatch software-engineer for ready tasks."
	case 5:
		return "Run heavy validation (regression/e2e tests)."
	case 6:
		return "Run QA on closed tasks."
	case 7:
		return "Generate wave summary and review progress."
	case 8:
		return "Run staff-engineer review."
	default:
		return "Unknown step."
	}
}

func runWaveNext(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if err := workflow.NextStep(s); err != nil {
		return err
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"wave":         s.Wave.Number,
			"current_step": s.Wave.CurrentStep,
			"step_name":    workflow.StepName(s.Wave.CurrentStep),
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Advanced to step %d (%s)\n", s.Wave.CurrentStep, workflow.StepName(s.Wave.CurrentStep))
	return nil
}

func runWaveSummary(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if jsonOutput {
		closed, _ := tk.LS("closed", "team-task")
		openTasks, _ := tk.LS("open", "team-task")
		inProgressTasks, _ := tk.LS("in_progress", "team-task")
		ready, _ := tk.Ready("team-task")

		out := map[string]interface{}{
			"wave":                   s.Wave.Number,
			"phase":                  s.Phase,
			"memory_mode":            s.MemoryMode,
			"tasks_closed_this_wave": len(s.Tasks.ClosedThisWave),
			"tasks_in_progress":      len(inProgressTasks),
			"tasks_ready":            len(ready),
			"tasks_closed_total":     len(closed),
			"tasks_open":             len(openTasks),
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	summary, err := workflow.WaveSummary(s)
	if err != nil {
		return err
	}
	fmt.Print(summary)
	return nil
}
