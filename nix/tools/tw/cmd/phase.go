package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/workflow"
	"github.com/spf13/cobra"
)

var phaseCmd = &cobra.Command{
	Use:   "phase",
	Short: "Phase management commands",
}

var phaseDetectCmd = &cobra.Command{
	Use:   "detect",
	Short: "Detect current phase from reality",
	RunE:  runPhaseDetect,
}

var phaseAdvanceCmd = &cobra.Command{
	Use:   "advance",
	Short: "Advance to next phase after gate validation",
	RunE:  runPhaseAdvance,
}

var advanceTo string

func init() {
	phaseCmd.AddCommand(phaseDetectCmd, phaseAdvanceCmd)
	phaseAdvanceCmd.Flags().StringVar(&advanceTo, "to", "", "Target phase to advance to")
}

func runPhaseDetect(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	detected, err := workflow.DetectPhase(s)
	if err != nil {
		return err
	}

	aligned := detected == s.Phase

	if jsonOutput {
		out := map[string]interface{}{
			"detected_phase": detected,
			"current_phase":  s.Phase,
			"aligned":        aligned,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
	} else {
		fmt.Printf("Detected phase: %s\n", detected)
		fmt.Printf("Current phase:  %s\n", s.Phase)
		if aligned {
			fmt.Println("Aligned: true")
		} else {
			fmt.Println("Aligned: false")
		}
	}

	if !aligned {
		return fmt.Errorf("phase mismatch: detected %s but state is %s", detected, s.Phase)
	}
	return nil
}

func runPhaseAdvance(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	target := advanceTo
	if target == "" {
		target = workflow.NextPhase(s.Phase)
	}

	if err := workflow.ValidateTransition(s.Phase, target, s); err != nil {
		return err
	}

	from := s.Phase
	s.Phase = target

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"from":    from,
			"to":      target,
			"success": true,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
	} else {
		fmt.Printf("Advanced from %s to %s\n", from, target)
	}
	return nil
}
