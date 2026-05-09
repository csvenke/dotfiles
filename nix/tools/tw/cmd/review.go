package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
	"github.com/spf13/cobra"
)

var (
	reviewResult    string
	reviewHasBlockers bool
	reviewBlockers  string
)

var reviewCmd = &cobra.Command{
	Use:   "review",
	Short: "Review commands",
}

var reviewStaffCmd = &cobra.Command{
	Use:   "staff",
	Short: "Record staff review result",
	RunE:  runReviewStaff,
}

func init() {
	reviewCmd.AddCommand(reviewStaffCmd)
	reviewStaffCmd.Flags().StringVar(&reviewResult, "result", "", "Review result: pass or fail (required)")
	_ = reviewStaffCmd.MarkFlagRequired("result")
	reviewStaffCmd.Flags().BoolVar(&reviewHasBlockers, "has-blockers", false, "Review has blockers")
	reviewStaffCmd.Flags().StringVar(&reviewBlockers, "blockers", "", "Blocker description")
}

func runReviewStaff(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if reviewResult != "pass" && reviewResult != "fail" {
		return fmt.Errorf("invalid result: %s (must be pass or fail)", reviewResult)
	}

	passed := reviewResult == "pass"
	s.Tasks.StaffReview.Passed = passed
	s.Tasks.StaffReview.RunAt = time.Now().UTC().Format(time.RFC3339)

	if passed {
		falseVal := false
		s.Tasks.StaffReview.HasBlockers = &falseVal
	} else if reviewHasBlockers {
		trueVal := true
		s.Tasks.StaffReview.HasBlockers = &trueVal
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if !passed && reviewHasBlockers {
		if reviewBlockers != "" {
			if err := createFollowUpTask(s, reviewBlockers); err != nil {
				fmt.Fprintf(os.Stderr, "warning: failed to create follow-up task: %v\n", err)
			}
		}
	}

	if jsonOutput {
		out := map[string]interface{}{
			"result":      reviewResult,
			"passed":      passed,
			"has_blockers": s.Tasks.StaffReview.HasBlockers,
			"run_at":      s.Tasks.StaffReview.RunAt,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Staff review recorded: %s\n", reviewResult)
	if !passed && reviewHasBlockers {
		fmt.Println("Blockers recorded and follow-up task created")
	}
	return nil
}

func createFollowUpTask(s *state.State, blockers string) error {
	if s.EpicID == "" {
		return fmt.Errorf("no epic initialized")
	}
	title := "Address staff review blockers"
	extraArgs := []string{"-t", "task", "--parent", s.EpicID, "--tags", "team-task,validation", "-d", blockers}
	_, err := tk.Create(title, extraArgs...)
	return err
}