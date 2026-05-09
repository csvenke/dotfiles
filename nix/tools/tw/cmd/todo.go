package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/workflow"
	"github.com/spf13/cobra"
)

var todoCmd = &cobra.Command{
	Use:   "todo",
	Short: "Todo management commands",
}

var todoSyncCmd = &cobra.Command{
	Use:   "sync",
	Short: "Sync standard todos for current phase/wave",
	RunE:  runTodoSync,
}

var todoListCmd = &cobra.Command{
	Use:   "list",
	Short: "List todos",
	RunE:  runTodoList,
}

var todoSetCmd = &cobra.Command{
	Use:   "set",
	Short: "Update todo status",
	Args:  cobra.ExactArgs(2),
	RunE:  runTodoSet,
}

func init() {
	todoCmd.AddCommand(todoSyncCmd, todoListCmd, todoSetCmd)
}

func standardTodos(phase string, waveNum int, step int) []state.Todo {
	switch phase {
	case workflow.PhasePlanning:
		return []state.Todo{
			{ID: "plan-draft", Text: "Draft implementation plan", Status: "open"},
			{ID: "plan-approve", Text: "Approve plan", Status: "open"},
		}
	case workflow.PhaseIssueCreation:
		return []state.Todo{
			{ID: "create-tasks", Text: "Create tasks for epic", Status: "open"},
			{ID: "add-notes", Text: "Add SPEC/ACCEPTANCE/METADATA notes", Status: "open"},
			{ID: "advance-phase", Text: "Advance to WAVE_EXECUTION", Status: "open"},
		}
	case workflow.PhaseWaveExecution:
		steps := []struct {
			id   string
			text string
		}{
			{"repo-bootstrap", "Repo bootstrap"},
			{"find-ready-work", "Find ready work"},
			{"domain-brief", "Domain brief"},
			{"ux-design", "UX design"},
			{"implementation", "Implementation"},
			{"validation", "Validation"},
			{"qa", "QA"},
			{"wave-summary", "Wave summary"},
			{"staff-review", "Staff review"},
		}
		var todos []state.Todo
		for i := step; i < len(steps); i++ {
			status := "open"
			if i == step {
				status = "in_progress"
			}
			todos = append(todos, state.Todo{
				ID:     fmt.Sprintf("wave-%d-%s", waveNum, steps[i].id),
				Text:   fmt.Sprintf("Wave %d: %s", waveNum, steps[i].text),
				Status: status,
			})
		}
		return todos
	case workflow.PhaseEpicClosure:
		return []state.Todo{
			{ID: "memory-retrospective", Text: "Memory retrospective", Status: "open"},
			{ID: "close-epic", Text: "Close epic", Status: "open"},
		}
	default:
		return nil
	}
}

func runTodoSync(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	newTodos := standardTodos(s.Phase, s.Wave.Number, s.Wave.CurrentStep)

	existingMap := make(map[string]string)
	for _, t := range s.Todos {
		existingMap[t.ID] = t.Status
	}

	var merged []state.Todo
	for _, t := range newTodos {
		if status, ok := existingMap[t.ID]; ok {
			if status == "completed" || status == "cancelled" {
				t.Status = status
			}
		}
		merged = append(merged, t)
	}

	standardMap := make(map[string]bool)
	for _, t := range newTodos {
		standardMap[t.ID] = true
	}
	for _, t := range s.Todos {
		if !standardMap[t.ID] {
			merged = append(merged, t)
		}
	}

	s.Todos = merged

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{"todos": s.Todos}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Synced %d todos for phase %s\n", len(s.Todos), s.Phase)
	return nil
}

func runTodoList(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{"todos": s.Todos}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	if len(s.Todos) == 0 {
		fmt.Println("No todos")
		return nil
	}

	for _, t := range s.Todos {
		fmt.Printf("[%s] %s: %s\n", t.Status, t.ID, t.Text)
	}
	return nil
}

func runTodoSet(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	id := args[0]
	status := args[1]

	if status != "in_progress" && status != "completed" && status != "cancelled" && status != "open" {
		return fmt.Errorf("invalid status: %s (must be open, in_progress, completed, or cancelled)", status)
	}

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	found := false
	for i := range s.Todos {
		if s.Todos[i].ID == id {
			s.Todos[i].Status = status
			found = true
			break
		}
	}
	if !found {
		return fmt.Errorf("todo not found: %s", id)
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"id":     id,
			"status": status,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Updated todo %s to %s\n", id, status)
	return nil
}
