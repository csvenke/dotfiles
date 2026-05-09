package cmd

import (
	"testing"

	"github.com/csvenke/dotfiles/tools/tw/internal/workflow"
)

func TestStandardTodosPlanning(t *testing.T) {
	todos := standardTodos(workflow.PhasePlanning, 0, 0)
	if len(todos) != 2 {
		t.Fatalf("expected 2 todos, got %d", len(todos))
	}
	if todos[0].ID != "plan-draft" {
		t.Errorf("expected first todo ID plan-draft, got %s", todos[0].ID)
	}
	if todos[0].Status != "open" {
		t.Errorf("expected first todo status open, got %s", todos[0].Status)
	}
}

func TestStandardTodosIssueCreation(t *testing.T) {
	todos := standardTodos(workflow.PhaseIssueCreation, 0, 0)
	if len(todos) != 3 {
		t.Fatalf("expected 3 todos, got %d", len(todos))
	}
}

func TestStandardTodosWaveExecution(t *testing.T) {
	todos := standardTodos(workflow.PhaseWaveExecution, 2, 4)
	if len(todos) != 5 {
		t.Fatalf("expected 5 todos, got %d", len(todos))
	}
	if todos[0].ID != "wave-2-implementation" {
		t.Errorf("expected first todo ID wave-2-implementation, got %s", todos[0].ID)
	}
	if todos[0].Status != "in_progress" {
		t.Errorf("expected first todo status in_progress, got %s", todos[0].Status)
	}
	if todos[1].ID != "wave-2-validation" {
		t.Errorf("expected second todo ID wave-2-validation, got %s", todos[1].ID)
	}
	if todos[1].Status != "open" {
		t.Errorf("expected second todo status open, got %s", todos[1].Status)
	}
}

func TestStandardTodosEpicClosure(t *testing.T) {
	todos := standardTodos(workflow.PhaseEpicClosure, 0, 0)
	if len(todos) != 2 {
		t.Fatalf("expected 2 todos, got %d", len(todos))
	}
}

func TestStandardTodosUnknownPhase(t *testing.T) {
	todos := standardTodos("UNKNOWN", 0, 0)
	if len(todos) != 0 {
		t.Fatalf("expected 0 todos for unknown phase, got %d", len(todos))
	}
}
