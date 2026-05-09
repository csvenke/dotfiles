package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/csvenke/dotfiles/tools/tw/internal/mempalace"
	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
	"github.com/spf13/cobra"
)

var (
	memoryTaskID      string
	memoryContent     string
	memoryRoom        string
	memoryKGSubject   string
	memoryKGPredicate string
	memoryKGObject    string
	memoryAgent       string
	memoryEntry       string
	memoryOutcome     string
	memoryPolicy      string
	memoryContextText string
)

var memoryCmd = &cobra.Command{
	Use:   "memory",
	Short: "Memory integration commands",
}

var memoryInitCmd = &cobra.Command{
	Use:   "init",
	Short: "Bootstrap mempalace memory",
	RunE:  runMemoryInit,
}

var memoryStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check mempalace health",
	RunE:  runMemoryStatus,
}

var memoryMineCmd = &cobra.Command{
	Use:   "mine",
	Short: "Re-mine current project directory",
	RunE:  runMemoryMine,
}

var memoryPrimeCmd = &cobra.Command{
	Use:   "prime",
	Short: "Build memory_context block for a task",
	RunE:  runMemoryPrime,
}

var memoryWritebackCmd = &cobra.Command{
	Use:   "writeback",
	Short: "Write memory drawer for a task",
	RunE:  runMemoryWriteback,
}

var memoryRetrospectiveCmd = &cobra.Command{
	Use:   "retrospective",
	Short: "Epic-level retrospective",
	RunE:  runMemoryRetrospective,
}

var memoryDiaryCmd = &cobra.Command{
	Use:   "diary",
	Short: "Worker diary entry",
	RunE:  runMemoryDiary,
}

func init() {
	memoryCmd.AddCommand(memoryInitCmd, memoryStatusCmd, memoryMineCmd, memoryPrimeCmd, memoryWritebackCmd, memoryRetrospectiveCmd, memoryDiaryCmd)

	memoryPrimeCmd.Flags().StringVar(&memoryTaskID, "task", "", "Task ID (required)")
	_ = memoryPrimeCmd.MarkFlagRequired("task")
	memoryPrimeCmd.Flags().StringVar(&memoryContextText, "context", "", "Additional context text")

	memoryWritebackCmd.Flags().StringVar(&memoryTaskID, "task", "", "Task ID (required)")
	_ = memoryWritebackCmd.MarkFlagRequired("task")
	memoryWritebackCmd.Flags().StringVar(&memoryContent, "content", "", "Content text (required)")
	_ = memoryWritebackCmd.MarkFlagRequired("content")
	memoryWritebackCmd.Flags().StringVar(&memoryRoom, "room", "", "Target room (overrides auto-detect)")
	memoryWritebackCmd.Flags().StringVar(&memoryKGSubject, "kg-subject", "", "KG subject")
	memoryWritebackCmd.Flags().StringVar(&memoryKGPredicate, "kg-predicate", "", "KG predicate")
	memoryWritebackCmd.Flags().StringVar(&memoryKGObject, "kg-object", "", "KG object")

	memoryRetrospectiveCmd.Flags().StringVar(&memoryOutcome, "outcome", "", "Outcome text (required)")
	_ = memoryRetrospectiveCmd.MarkFlagRequired("outcome")
	memoryRetrospectiveCmd.Flags().StringVar(&memoryPolicy, "policy", "", "Policy text")

	memoryDiaryCmd.Flags().StringVar(&memoryAgent, "agent", "", "Agent role (required)")
	_ = memoryDiaryCmd.MarkFlagRequired("agent")
	memoryDiaryCmd.Flags().StringVar(&memoryEntry, "entry", "", "Diary entry text (required)")
	_ = memoryDiaryCmd.MarkFlagRequired("entry")
}

func runMemoryInit(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	wing, err := resolveWing(s, projectDir)
	if err != nil {
		return err
	}

	gitignorePath := filepath.Join(projectDir, ".gitignore")
	var gitignoreBackup []byte
	if _, err := os.Stat(gitignorePath); err == nil {
		gitignoreBackup, _ = os.ReadFile(gitignorePath)
	}

	var initErr error
	defer func() {
		if initErr != nil && len(gitignoreBackup) > 0 {
			_ = os.WriteFile(gitignorePath, gitignoreBackup, 0644)
		}
	}()

	initErr = mempalace.Init(projectDir, true, true)
	if initErr != nil {
		return fmt.Errorf("mempalace init failed: %w", initErr)
	}
	if len(gitignoreBackup) > 0 {
		_ = os.WriteFile(gitignorePath, gitignoreBackup, 0644)
	}

	if err := mempalace.Mine(projectDir, wing); err != nil {
		return fmt.Errorf("mempalace mine failed: %w", err)
	}
	if err := mempalace.Compress(wing); err != nil {
		return fmt.Errorf("mempalace compress failed: %w", err)
	}

	yamlPath := filepath.Join(projectDir, "mempalace.yaml")
	if data, err := os.ReadFile(yamlPath); err == nil {
		if ms, err := mempalace.ParseYAML(data); err == nil {
			s.Mempalace = *ms
			if ms.Wing != "" {
				s.Wing = ms.Wing
				wing = ms.Wing
			}
		}
	}

	s.MemoryMode = "active"
	if s.Wing == "" {
		s.Wing = wing
	}
	if s.Mempalace.Wing == "" {
		s.Mempalace.Wing = wing
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"memory_mode": s.MemoryMode,
			"wing":        wing,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Memory initialized for wing %s\n", wing)
	return nil
}

func runMemoryStatus(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	wing := s.Wing
	if wing == "" {
		wing, _ = mempalace.DetectWing(projectDir)
	}

	yamlPath := filepath.Join(projectDir, "mempalace.yaml")
	var rooms int
	if data, err := os.ReadFile(yamlPath); err == nil {
		if ms, err := mempalace.ParseYAML(data); err == nil {
			if wing == "" {
				wing = ms.Wing
			}
			rooms = len(ms.Rooms)
		}
	} else {
		fmt.Fprintf(os.Stderr, "warning: mempalace.yaml not found in %s\n", projectDir)
	}

	statusResult, err := mempalace.Status(wing)
	available := err == nil
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: mempalace status failed: %v\n", err)
		statusResult = map[string]interface{}{}
	}

	drawers := 0
	if d, ok := statusResult["drawers"].(int); ok {
		drawers = d
	}
	if rooms == 0 {
		if r, ok := statusResult["rooms"].(int); ok {
			rooms = r
		}
	}

	lastMine := "unknown"
	if info, err := os.Stat(yamlPath); err == nil {
		lastMine = info.ModTime().UTC().Format(time.RFC3339)
	}

	compressed := available // proxy: if status works, assume compressed

	if jsonOutput {
		out := map[string]interface{}{
			"available": available,
			"wing":      wing,
			"rooms":     rooms,
			"drawers":   drawers,
			"last_mine": lastMine,
			"compressed": compressed,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Memory: %s\n", map[bool]string{true: "available", false: "unavailable"}[available])
	fmt.Printf("Wing: %s\n", wing)
	fmt.Printf("Rooms: %d\n", rooms)
	fmt.Printf("Drawers: %d\n", drawers)
	fmt.Printf("Last mine: %s\n", lastMine)
	fmt.Printf("Compressed: %v\n", compressed)
	return nil
}

func runMemoryMine(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	wing, err := resolveWing(s, projectDir)
	if err != nil {
		return err
	}

	if err := mempalace.Mine(projectDir, wing); err != nil {
		return fmt.Errorf("mempalace mine failed: %w", err)
	}
	if err := mempalace.Compress(wing); err != nil {
		return fmt.Errorf("mempalace compress failed: %w", err)
	}

	if jsonOutput {
		out := map[string]interface{}{"wing": wing, "mined": true}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Mined and compressed wing %s\n", wing)
	return nil
}

func runMemoryPrime(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if s.MemoryMode == "degraded" {
		fmt.Fprintln(os.Stderr, "warning: memory mode is degraded, returning empty block")
		if jsonOutput {
			fmt.Println(`{"memory_context": ""}`)
		} else {
			fmt.Println("<memory_context></memory_context>")
		}
		return nil
	}

	wing, err := resolveWing(s, projectDir)
	if err != nil {
		return err
	}

	taskID := memoryTaskID
	taskTitle, err := getTaskTitle(taskID)
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: could not get task title: %v\n", err)
	}

	room := selectRoomFromTask(taskID, s)

	query := taskID
	if taskTitle != "" {
		query = taskID + " " + taskTitle
	}
	if memoryContextText != "" {
		query += " " + memoryContextText
	}

	searchResults, err := mempalace.Search(query, wing, room, 5)
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: mempalace search failed: %v\n", err)
		searchResults = nil
	}

	var kgResults []map[string]interface{}
	if kg, err := mempalace.KGQuery(taskID); err == nil {
		kgResults = append(kgResults, kg...)
	} else {
		fmt.Fprintf(os.Stderr, "warning: mempalace kg_query failed: %v\n", err)
	}
	if s.EpicID != "" {
		if kg, err := mempalace.KGQuery(s.EpicID); err == nil {
			kgResults = append(kgResults, kg...)
		} else {
			fmt.Fprintf(os.Stderr, "warning: mempalace kg_query failed: %v\n", err)
		}
	}

	var sb strings.Builder
	sb.WriteString("<memory_context>\n")
	sb.WriteString("  <search>\n")
	if len(searchResults) == 0 {
		sb.WriteString("    (no results)\n")
	} else {
		for _, r := range searchResults {
			text, _ := r["text"].(string)
			if text != "" {
				sb.WriteString(fmt.Sprintf("    - %s\n", text))
			}
		}
	}
	sb.WriteString("  </search>\n")
	sb.WriteString("  <kg>\n")
	if len(kgResults) == 0 {
		sb.WriteString("    (no results)\n")
	} else {
		for _, r := range kgResults {
			text, _ := r["text"].(string)
			if text == "" {
				text = fmt.Sprintf("%v", r)
			}
			sb.WriteString(fmt.Sprintf("    - %s\n", text))
		}
	}
	sb.WriteString("  </kg>\n")
	sb.WriteString("</memory_context>")

	block := sb.String()

	if jsonOutput {
		out := map[string]interface{}{"memory_context": block}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Println(block)
	return nil
}

func runMemoryWriteback(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	wing, err := resolveWing(s, projectDir)
	if err != nil {
		return err
	}

	room := memoryRoom
	if room == "" {
		room = selectRoomFromTask(memoryTaskID, s)
	}

	dup, err := mempalace.CheckDuplicate(memoryContent)
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: mempalace check_duplicate failed: %v\n", err)
	} else if dup {
		fmt.Fprintln(os.Stderr, "info: duplicate memory detected, skipping write")
		if jsonOutput {
			fmt.Println(`{"skipped": true, "reason": "duplicate"}`)
		}
		return nil
	}

	if err := mempalace.AddDrawer(wing, room, memoryContent); err != nil {
		fmt.Fprintf(os.Stderr, "warning: mempalace add_drawer failed: %v\n", err)
	}

	if memoryKGSubject != "" && memoryKGPredicate != "" && memoryKGObject != "" {
		if err := mempalace.KGAdd(memoryKGSubject, memoryKGPredicate, memoryKGObject); err != nil {
			fmt.Fprintf(os.Stderr, "warning: mempalace kg_add failed: %v\n", err)
		}
	}

	if jsonOutput {
		out := map[string]interface{}{
			"wing":    wing,
			"room":    room,
			"written": true,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Memory written to %s/%s\n", wing, room)
	return nil
}

func runMemoryRetrospective(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)
	s, err := state.Read(statePath)
	if err != nil {
		return err
	}

	if err := mempalace.AddDrawer("opencode", "team-retros", memoryOutcome); err != nil {
		fmt.Fprintf(os.Stderr, "warning: mempalace add_drawer failed: %v\n", err)
	}

	if memoryPolicy != "" {
		if err := mempalace.KGAdd("retrospective", "policy", memoryPolicy); err != nil {
			fmt.Fprintf(os.Stderr, "warning: mempalace kg_add failed: %v\n", err)
		}
	}

	wing := s.Wing
	if wing == "" {
		wing, _ = mempalace.DetectWing(projectDir)
	}
	if wing != "" {
		if err := mempalace.CreateTunnel("opencode", "team-retros", wing, "general", "retrospective"); err != nil {
			fmt.Fprintf(os.Stderr, "warning: mempalace create_tunnel failed: %v\n", err)
		}
	}

	if jsonOutput {
		out := map[string]interface{}{"written": true, "wing": "opencode", "room": "team-retros"}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Println("Retrospective written to opencode/team-retros")
	return nil
}

func runMemoryDiary(cmd *cobra.Command, args []string) error {
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	if err := mempalace.DiaryWrite(memoryAgent, memoryEntry); err != nil {
		fmt.Fprintf(os.Stderr, "warning: mempalace diary_write failed: %v\n", err)
	}

	if jsonOutput {
		out := map[string]interface{}{
			"agent": memoryAgent,
			"written": true,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Diary entry written for %s\n", memoryAgent)
	return nil
}

func resolveWing(s *state.State, projectDir string) (string, error) {
	wing := s.Wing
	if wing == "" {
		wing = s.Mempalace.Wing
	}
	if wing == "" {
		var err error
		wing, err = mempalace.DetectWing(projectDir)
		if err != nil {
			return "", err
		}
	}
	return wing, nil
}

func getTaskTitle(taskID string) (string, error) {
	details, err := tk.Query(fmt.Sprintf(`select(.id == "%s")`, tk.EscapeJQ(taskID)))
	if err != nil || len(details) == 0 {
		return "", fmt.Errorf("task not found")
	}
	title, _ := details[0]["title"].(string)
	return title, nil
}

func selectRoomFromTask(taskID string, s *state.State) string {
	meta, err := tk.GetMetadata(taskID)
	if err != nil {
		return "general"
	}
	areasStr, ok := meta["areas_touched"]
	if !ok || areasStr == "" {
		return "general"
	}

	areas := strings.Split(areasStr, ",")
	for i := range areas {
		areas[i] = strings.TrimSpace(strings.ToLower(areas[i]))
	}

	bestRoom := "general"
	bestScore := 0
	for room, keywords := range s.Mempalace.Rooms {
		score := 0
		for _, kw := range keywords {
			kw = strings.ToLower(kw)
			for _, area := range areas {
				if strings.Contains(area, kw) || strings.Contains(kw, area) {
					score++
				}
			}
		}
		if score > bestScore {
			bestScore = score
			bestRoom = room
		}
	}
	return bestRoom
}