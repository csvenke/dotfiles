package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/csvenke/dotfiles/tools/tw/internal/mempalace"
	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
	"github.com/spf13/cobra"
)

var (
	taskTags       string
	taskDesc       string
	taskAcceptance string
	taskNoteType   string
	taskStatus     string
	taskOutcome    string
)

var taskCmd = &cobra.Command{
	Use:   "task",
	Short: "Task management commands",
}

var taskCreateCmd = &cobra.Command{
	Use:   "create",
	Short: "Create a workflow task",
	Args:  cobra.ExactArgs(1),
	RunE:  runTaskCreate,
}

var taskNoteCmd = &cobra.Command{
	Use:   "note",
	Short: "Add a typed note to a task",
	Args:  cobra.ExactArgs(2),
	RunE:  runTaskNote,
}

var taskListCmd = &cobra.Command{
	Use:   "list",
	Short: "List workflow tasks",
	RunE:  runTaskList,
}

var taskReadyCmd = &cobra.Command{
	Use:   "ready",
	Short: "List ready tasks grouped by lane",
	RunE:  runTaskReady,
}

var taskStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Start a task",
	Args:  cobra.ExactArgs(1),
	RunE:  runTaskStart,
}

var taskCloseCmd = &cobra.Command{
	Use:   "close",
	Short: "Close a task",
	Args:  cobra.ExactArgs(1),
	RunE:  runTaskClose,
}

func init() {
	taskCmd.AddCommand(taskCreateCmd, taskNoteCmd, taskListCmd, taskReadyCmd, taskStartCmd, taskCloseCmd)
	taskCreateCmd.Flags().StringVar(&taskTags, "tags", "", "Lane tag (required)")
	taskCreateCmd.Flags().StringVarP(&taskDesc, "description", "d", "", "Task description")
	taskCreateCmd.Flags().StringVar(&taskAcceptance, "acceptance", "", "Acceptance criteria")
	_ = taskCreateCmd.MarkFlagRequired("tags")
	taskNoteCmd.Flags().StringVar(&taskNoteType, "type", "", "Note type (required)")
	_ = taskNoteCmd.MarkFlagRequired("type")
	taskListCmd.Flags().StringVar(&taskStatus, "status", "", "Filter by status (open, in_progress, closed)")
	taskCloseCmd.Flags().StringVar(&taskOutcome, "outcome", "", "Outcome text for memory writeback")
}

func runTaskCreate(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if s.EpicID == "" {
		return fmt.Errorf("no epic initialized")
	}

	title := args[0]
	lane := taskTags
	tags := "team-task," + lane

	extraArgs := []string{"-t", "task", "--parent", s.EpicID, "--tags", tags}
	if taskDesc != "" {
		if len(taskDesc) > 120 {
			fmt.Fprintf(os.Stderr, "warning: description exceeds 120 chars (%d)\n", len(taskDesc))
		}
		extraArgs = append(extraArgs, "-d", taskDesc)
	}
	if taskAcceptance != "" {
		if len(taskAcceptance) > 120 {
			fmt.Fprintf(os.Stderr, "warning: acceptance exceeds 120 chars (%d)\n", len(taskAcceptance))
		}
		extraArgs = append(extraArgs, "--acceptance", taskAcceptance)
	}

	id, err := tk.Create(title, extraArgs...)
	if err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"id":      id,
			"title":   title,
			"lane":    lane,
			"epic_id": s.EpicID,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Created task %s\n", id)
	return nil
}

func runTaskNote(cmd *cobra.Command, args []string) error {
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	id := args[0]
	text := args[1]

	prefixMap := map[string]string{
		"spec":       "SPEC",
		"acceptance": "ACCEPTANCE",
		"metadata":   "METADATA",
		"handoff":    "HANDOFF",
		"rework":     "REWORK",
		"blocked":    "BLOCKED",
		"invariants": "INVARIANTS",
	}

	prefix, ok := prefixMap[taskNoteType]
	if !ok {
		return fmt.Errorf("invalid note type: %s", taskNoteType)
	}

	prefixed := prefix + ": " + text

	if err := tk.AddNote(id, prefixed); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"id":       id,
			"type":     taskNoteType,
			"prefixed": prefixed,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Note added to %s\n", id)
	return nil
}

func runTaskList(cmd *cobra.Command, args []string) error {
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	status := taskStatus
	tasks, err := tk.LS(status, "team-task")
	if err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{"tasks": tasks}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	if len(tasks) == 0 {
		fmt.Println("No tasks found")
		return nil
	}

	for _, t := range tasks {
		id, _ := t["id"].(string)
		title, _ := t["title"].(string)
		st, _ := t["status"].(string)
		tags, _ := t["tags"].([]interface{})
		var tagStrs []string
		for _, tag := range tags {
			if s, ok := tag.(string); ok {
				tagStrs = append(tagStrs, s)
			}
		}
		fmt.Printf("%s [%s] - %s (%s)\n", id, st, title, strings.Join(tagStrs, ", "))
	}
	return nil
}

func runTaskReady(cmd *cobra.Command, args []string) error {
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	details, err := tk.ReadyDetails("team-task")
	if err != nil {
		return err
	}

	lanes := make(map[string][]map[string]interface{})
	for _, d := range details {
		tags, _ := d["tags"].([]interface{})
		var lane string
		for _, tag := range tags {
			if s, ok := tag.(string); ok && s != "team-task" {
				lane = s
				break
			}
		}
		if lane == "" {
			lane = "uncategorized"
		}
		lanes[lane] = append(lanes[lane], d)
	}

	if jsonOutput {
		out := map[string]interface{}{"lanes": lanes}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	if len(lanes) == 0 {
		fmt.Println("No ready tasks")
		return nil
	}

	var laneNames []string
	for lane := range lanes {
		laneNames = append(laneNames, lane)
	}
	sort.Strings(laneNames)

	for _, lane := range laneNames {
		fmt.Printf("%s:\n", lane)
		for _, t := range lanes[lane] {
			id, _ := t["id"].(string)
			title, _ := t["title"].(string)
			priority, _ := t["priority"].(string)
			st, _ := t["status"].(string)
			fmt.Printf("  %s [P%s][%s] - %s\n", id, priority, st, title)
		}
	}
	return nil
}

func runTaskStart(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	id := args[0]

	if err := tk.Start(id); err != nil {
		return err
	}

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	found := false
	for _, a := range s.Tasks.Active {
		if a == id {
			found = true
			break
		}
	}
	if !found {
		s.Tasks.Active = append(s.Tasks.Active, id)
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"id":     id,
			"active": s.Tasks.Active,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Started task %s\n", id)
	return nil
}

func runTaskClose(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	id := args[0]

	if err := tk.Close(id); err != nil {
		return err
	}

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if taskOutcome != "" && s.MemoryMode == "active" {
		dup, err := mempalace.CheckDuplicate(taskOutcome)
		if err != nil {
			fmt.Fprintf(os.Stderr, "warning: mempalace check_duplicate failed: %v\n", err)
		} else if dup {
			fmt.Fprintf(os.Stderr, "info: duplicate memory detected, skipping write\n")
		} else {
			wing := s.Wing
			if wing == "" {
				wing = "general"
			}
			room := "general"
			if err := mempalace.AddDrawer(wing, room, taskOutcome); err != nil {
				fmt.Fprintf(os.Stderr, "warning: mempalace add_drawer failed: %v\n", err)
			}
		}
	}

	var newActive []string
	for _, a := range s.Tasks.Active {
		if a != id {
			newActive = append(newActive, a)
		}
	}
	if newActive == nil {
		newActive = []string{}
	}
	s.Tasks.Active = newActive

	found := false
	for _, c := range s.Tasks.ClosedThisWave {
		if c == id {
			found = true
			break
		}
	}
	if !found {
		s.Tasks.ClosedThisWave = append(s.Tasks.ClosedThisWave, id)
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"id":               id,
			"active":           s.Tasks.Active,
			"closed_this_wave": s.Tasks.ClosedThisWave,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Closed task %s\n", id)
	return nil
}
