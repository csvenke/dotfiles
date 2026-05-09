package workflow

import (
	"os/exec"
	"testing"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
)

func TestStepName(t *testing.T) {
	if StepName(0) != "Repo bootstrap" {
		t.Errorf("unexpected step name for 0")
	}
	if StepName(4) != "Implementation" {
		t.Errorf("unexpected step name for 4")
	}
	if StepName(99) != "Unknown" {
		t.Errorf("unexpected step name for 99")
	}
}

func TestNextPhase(t *testing.T) {
	tests := []struct {
		current, want string
	}{
		{PhasePlanning, PhaseIssueCreation},
		{PhaseIssueCreation, PhaseWaveExecution},
		{PhaseWaveExecution, PhaseEpicClosure},
		{PhaseEpicClosure, PhaseComplete},
	}
	for _, tt := range tests {
		got := NextPhase(tt.current)
		if got != tt.want {
			t.Errorf("NextPhase(%q) = %q, want %q", tt.current, got, tt.want)
		}
	}
}

func TestValidateTransitionSamePhase(t *testing.T) {
	s := &state.State{}
	if err := ValidateTransition(PhasePlanning, PhasePlanning, s); err != nil {
		t.Errorf("same phase should be valid: %v", err)
	}
}

func TestValidateTransitionPlanningToIssueCreation(t *testing.T) {
	s := &state.State{Plan: state.Plan{Approved: true}}
	if err := ValidateTransition(PhasePlanning, PhaseIssueCreation, s); err != nil {
		t.Errorf("approved plan should pass: %v", err)
	}

	s.Plan.Approved = false
	if err := ValidateTransition(PhasePlanning, PhaseIssueCreation, s); err == nil {
		t.Error("unapproved plan should fail")
	}
}

func TestValidateTransitionIssueCreationToWaveExecution(t *testing.T) {
	if _, err := exec.LookPath("tk"); err != nil {
		t.Skip("tk not in PATH")
	}
	// This test is environment-dependent because it queries the real ticket database.
	// We only verify that the function returns without panicking.
	s := &state.State{}
	_ = ValidateTransition(PhaseIssueCreation, PhaseWaveExecution, s)
}

func TestStartWave(t *testing.T) {
	s := &state.State{
		Wave: state.Wave{
			Number:      1,
			CurrentStep: 4,
			StartedAt:   "2026-05-01T10:00:00Z",
		},
		Tasks: state.Tasks{
			ClosedThisWave: []string{"task-1"},
			StaffReview: state.StaffReview{
				Passed: true,
			},
		},
	}

	if err := StartWave(s); err != nil {
		t.Fatalf("StartWave failed: %v", err)
	}

	if s.Wave.Number != 2 {
		t.Errorf("expected wave number 2, got %d", s.Wave.Number)
	}
	if s.Wave.CurrentStep != 0 {
		t.Errorf("expected current step 0, got %d", s.Wave.CurrentStep)
	}
	if s.Wave.StartedAt == "" {
		t.Error("expected started_at to be set")
	}
	if len(s.Tasks.ClosedThisWave) != 0 {
		t.Errorf("expected closed_this_wave cleared, got %v", s.Tasks.ClosedThisWave)
	}
	if s.Tasks.StaffReview.Passed {
		t.Error("expected staff review to be reset")
	}
}

func TestStartWaveIdempotent(t *testing.T) {
	s := &state.State{
		Wave: state.Wave{
			Number:      3,
			CurrentStep: 0,
			StartedAt:   "2026-05-01T10:00:00Z",
		},
	}

	if err := StartWave(s); err != nil {
		t.Fatalf("StartWave failed: %v", err)
	}

	if s.Wave.Number != 3 {
		t.Errorf("expected wave number to remain 3, got %d", s.Wave.Number)
	}
}

func TestNextStep(t *testing.T) {
	s := &state.State{
		Phase: PhaseWaveExecution,
		Wave:  state.Wave{CurrentStep: 3},
	}

	if err := NextStep(s); err != nil {
		t.Fatalf("NextStep failed: %v", err)
	}
	if s.Wave.CurrentStep != 4 {
		t.Errorf("expected step 4, got %d", s.Wave.CurrentStep)
	}
}

func TestNextStepOverflow(t *testing.T) {
	s := &state.State{
		Phase: PhaseWaveExecution,
		Wave:  state.Wave{CurrentStep: 8},
	}

	if err := NextStep(s); err == nil {
		t.Error("expected error for step overflow")
	}
}

func TestNextStepNotInWaveExecution(t *testing.T) {
	s := &state.State{
		Phase: PhasePlanning,
		Wave:  state.Wave{CurrentStep: 3},
	}

	if err := NextStep(s); err == nil {
		t.Error("expected error when not in wave execution phase")
	}
}

func TestHasTagInTasks(t *testing.T) {
	tasks := []map[string]interface{}{
		{"id": "t1", "tags": []interface{}{"team-task", "ui"}},
		{"id": "t2", "tags": []interface{}{"team-task", "backend"}},
	}

	if !hasTagInTasks(tasks, "ui") {
		t.Error("expected to find ui tag")
	}
	if hasTagInTasks(tasks, "domain-heavy") {
		t.Error("expected not to find domain-heavy tag")
	}
}

func TestHasTagInTasksNoTags(t *testing.T) {
	tasks := []map[string]interface{}{
		{"id": "t1"},
	}
	if hasTagInTasks(tasks, "ui") {
		t.Error("expected not to find ui tag when no tags present")
	}
}

func TestWaveSummaryFormat(t *testing.T) {
	if _, err := exec.LookPath("tk"); err != nil {
		t.Skip("tk not in PATH")
	}
	s := &state.State{
		Wave: state.Wave{
			Number:      2,
			CurrentStep: 7,
		},
		Phase:       PhaseWaveExecution,
		MemoryMode:  "active",
		Tasks:       state.Tasks{ClosedThisWave: []string{"task-1"}},
	}
	summary, err := WaveSummary(s)
	if err != nil {
		t.Fatalf("WaveSummary failed: %v", err)
	}
	if summary == "" {
		t.Error("expected non-empty summary")
	}
	if !contains(summary, "## Wave 2 Complete") {
		t.Error("expected wave header in summary")
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsAt(s, substr))
}

func containsAt(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
