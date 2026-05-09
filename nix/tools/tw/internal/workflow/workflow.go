package workflow

import (
	"fmt"
	"strings"
	"time"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
)

const (
	PhasePlanning      = "PLANNING"
	PhaseIssueCreation = "ISSUE_CREATION"
	PhaseWaveExecution = "WAVE_EXECUTION"
	PhaseEpicClosure   = "EPIC_CLOSURE"
	PhaseComplete      = "COMPLETE"
)

var stepNames = map[int]string{
	0: "Repo bootstrap",
	1: "Find ready work",
	2: "Domain brief",
	3: "UX design",
	4: "Implementation",
	5: "Validation",
	6: "QA",
	7: "Wave summary",
	8: "Staff review",
}

func StepName(step int) string {
	if name, ok := stepNames[step]; ok {
		return name
	}
	return "Unknown"
}

func DetectPhase(s *state.State) (string, error) {
	if !s.Plan.Approved {
		return PhasePlanning, nil
	}
	tasks, err := tk.Query(`select(.type == "task" and (.tags // [] | index("team-task")))`)
	if err != nil {
		return "", fmt.Errorf("detect phase: query tasks: %w", err)
	}
	if len(tasks) == 0 {
		return PhaseIssueCreation, nil
	}
	openTasks, err := tk.LS("open", "team-task")
	if err != nil {
		return "", fmt.Errorf("detect phase: list open tasks: %w", err)
	}
	inProgressTasks, err := tk.LS("in_progress", "team-task")
	if err != nil {
		return "", fmt.Errorf("detect phase: list in_progress tasks: %w", err)
	}
	if len(openTasks) == 0 && len(inProgressTasks) == 0 && s.Tasks.StaffReview.Passed {
		return PhaseEpicClosure, nil
	}
	return PhaseWaveExecution, nil
}

func ValidateTransition(from, to string, s *state.State) error {
	if from == to {
		return nil
	}
	switch from {
	case PhasePlanning:
		if to == PhaseIssueCreation {
			if !s.Plan.Approved {
				return fmt.Errorf("gate failed: plan not approved")
			}
			return nil
		}
	case PhaseIssueCreation:
		if to == PhaseWaveExecution {
			tasks, err := tk.Query(`select(.type == "task" and (.tags // [] | index("team-task")))`)
			if err != nil {
				return fmt.Errorf("gate validation error: %w", err)
			}
			if len(tasks) == 0 {
				return fmt.Errorf("gate failed: no team-task tickets found")
			}
			return nil
		}
	case PhaseWaveExecution:
		if to == PhaseEpicClosure {
			openTasks, err := tk.LS("open", "team-task")
			if err != nil {
				return fmt.Errorf("gate validation error: %w", err)
			}
			inProgressTasks, err := tk.LS("in_progress", "team-task")
			if err != nil {
				return fmt.Errorf("gate validation error: %w", err)
			}
			if len(openTasks) > 0 || len(inProgressTasks) > 0 {
				return fmt.Errorf("gate failed: open or in-progress tasks remain")
			}
			if !s.Tasks.StaffReview.Passed {
				return fmt.Errorf("gate failed: staff review not passed")
			}
			return nil
		}
	case PhaseEpicClosure:
		if to == PhaseComplete {
			epic, err := tk.Query(fmt.Sprintf(`select(.id == "%s")`, tk.EscapeJQ(s.EpicID)))
			if err != nil {
				return fmt.Errorf("gate validation error: %w", err)
			}
			if len(epic) == 0 {
				return fmt.Errorf("gate failed: epic not found")
			}
			status, _ := epic[0]["status"].(string)
			if status != "closed" {
				return fmt.Errorf("gate failed: epic not closed")
			}
			return nil
		}
	}
	return fmt.Errorf("invalid transition: %s -> %s", from, to)
}

func NextPhase(current string) string {
	switch current {
	case PhasePlanning:
		return PhaseIssueCreation
	case PhaseIssueCreation:
		return PhaseWaveExecution
	case PhaseWaveExecution:
		return PhaseEpicClosure
	case PhaseEpicClosure:
		return PhaseComplete
	}
	return current
}

func EvaluateStep(s *state.State) (effectiveStep int, skipped bool, done bool, err error) {
	if s.Phase != PhaseWaveExecution {
		return 0, false, false, fmt.Errorf("not in wave execution phase")
	}

	step := s.Wave.CurrentStep
	if step < 0 {
		return 0, false, false, fmt.Errorf("invalid step %d", step)
	}
	if step > 8 {
		return 0, false, true, nil
	}

	openTasks, err := tk.LS("open", "team-task")
	if err != nil {
		return 0, false, false, fmt.Errorf("list open tasks: %w", err)
	}
	inProgressTasks, err := tk.LS("in_progress", "team-task")
	if err != nil {
		return 0, false, false, fmt.Errorf("list in_progress tasks: %w", err)
	}
	allClosed := len(openTasks) == 0 && len(inProgressTasks) == 0

	if allClosed && s.Tasks.StaffReview.Passed {
		return 0, false, true, nil
	}

	var readyDetails []map[string]interface{}
	var readyDetailsErr error
	getReadyDetails := func() ([]map[string]interface{}, error) {
		if readyDetails == nil && readyDetailsErr == nil {
			readyDetails, readyDetailsErr = tk.ReadyDetails("team-task")
		}
		return readyDetails, readyDetailsErr
	}

	for step <= 8 {
		shouldSkip := false

		switch step {
		case 0:
			shouldSkip = s.Wave.Number != 1
		case 2:
			details, err := getReadyDetails()
			if err != nil {
				return 0, false, false, fmt.Errorf("ready details: %w", err)
			}
			shouldSkip = !hasTagInTasks(details, "domain-heavy") && !hasTagInTasks(details, "underspecified")
		case 3:
			details, err := getReadyDetails()
			if err != nil {
				return 0, false, false, fmt.Errorf("ready details: %w", err)
			}
			shouldSkip = !hasTagInTasks(details, "ui")
		case 5:
			details, err := getReadyDetails()
			if err != nil {
				return 0, false, false, fmt.Errorf("ready details: %w", err)
			}
			shouldSkip = !hasHeavyValidation(details, inProgressTasks)
		case 8:
			if !allClosed {
				return 0, false, false, fmt.Errorf("step 8 requires all tasks closed")
			}
			shouldSkip = false
		}

		if !shouldSkip {
			return step, skipped, false, nil
		}

		step++
		skipped = true
	}

	return 0, skipped, true, nil
}

func hasTagInTasks(tasks []map[string]interface{}, tag string) bool {
	for _, t := range tasks {
		tags, _ := t["tags"].([]interface{})
		for _, t := range tags {
			if s, ok := t.(string); ok && s == tag {
				return true
			}
		}
	}
	return false
}

func hasHeavyValidation(readyTasks, activeTasks []map[string]interface{}) bool {
	for _, t := range readyTasks {
		id, _ := t["id"].(string)
		if id == "" {
			continue
		}
		meta, err := tk.GetMetadata(id)
		if err != nil {
			continue
		}
		if te := meta["test_expectation"]; te == "regression" || te == "e2e" {
			return true
		}
	}
	for _, t := range activeTasks {
		id, _ := t["id"].(string)
		if id == "" {
			continue
		}
		meta, err := tk.GetMetadata(id)
		if err != nil {
			continue
		}
		if te := meta["test_expectation"]; te == "regression" || te == "e2e" {
			return true
		}
	}
	return false
}

func StartWave(s *state.State) error {
	if s.Wave.CurrentStep == 0 && s.Wave.StartedAt != "" {
		return nil
	}
	s.Wave.Number++
	s.Wave.CurrentStep = 0
	s.Wave.StartedAt = time.Now().UTC().Format(time.RFC3339)
	s.Tasks.ClosedThisWave = []string{}
	s.Tasks.StaffReview = state.StaffReview{
		Passed:      false,
		HasBlockers: nil,
		RunAt:       "",
	}
	return nil
}

func NextStep(s *state.State) error {
	if s.Phase != PhaseWaveExecution {
		return fmt.Errorf("not in wave execution phase")
	}
	s.Wave.CurrentStep++
	if s.Wave.CurrentStep > 8 {
		return fmt.Errorf("step overflow: wave complete, transition to epic closure")
	}
	return nil
}

func WaveSummary(s *state.State) (string, error) {
	var b strings.Builder

	fmt.Fprintf(&b, "## Wave %d Complete\n\n", s.Wave.Number)
	fmt.Fprintf(&b, "| Task | Status | Last Agent | Outcome |\n")
	fmt.Fprintf(&b, "|------|--------|------------|---------|\n")

	closedTasks, _ := tk.LS("closed", "team-task")
	for _, t := range closedTasks {
		id, _ := t["id"].(string)
		status, _ := t["status"].(string)
		title, _ := t["title"].(string)
		fmt.Fprintf(&b, "| %s | %s | - | %s |\n", id, status, title)
	}

	openTasks, _ := tk.LS("open", "team-task")
	for _, t := range openTasks {
		id, _ := t["id"].(string)
		status, _ := t["status"].(string)
		title, _ := t["title"].(string)
		fmt.Fprintf(&b, "| %s | %s | - | %s |\n", id, status, title)
	}

	inProgressTasks, _ := tk.LS("in_progress", "team-task")
	for _, t := range inProgressTasks {
		id, _ := t["id"].(string)
		status, _ := t["status"].(string)
		title, _ := t["title"].(string)
		fmt.Fprintf(&b, "| %s | %s | - | %s |\n", id, status, title)
	}

	ready, _ := tk.Ready("team-task")

	fmt.Fprintf(&b, "\n- Phase: %s\n", s.Phase)
	fmt.Fprintf(&b, "- Memory: %s\n", s.MemoryMode)
	fmt.Fprintf(&b, "- Tasks closed this wave: %d\n", len(s.Tasks.ClosedThisWave))
	fmt.Fprintf(&b, "- Tasks in progress: %d\n", len(inProgressTasks))
	fmt.Fprintf(&b, "- Tasks ready: %d\n", len(ready))

	nextStep := s.Wave.CurrentStep + 1
	if nextStep > 8 {
		fmt.Fprintf(&b, "- Next: Epic closure\n")
	} else {
		fmt.Fprintf(&b, "- Next: Step %d %s\n", nextStep, StepName(nextStep))
	}

	return b.String(), nil
}
