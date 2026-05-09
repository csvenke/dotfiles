package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/csvenke/dotfiles/tools/tw/internal/mempalace"
	"github.com/csvenke/dotfiles/tools/tw/internal/state"
	"github.com/csvenke/dotfiles/tools/tw/internal/tk"
	"github.com/csvenke/dotfiles/tools/tw/internal/workflow"
	"github.com/spf13/cobra"
)

var (
	initEpicTitle  string
	initDesc       string
	initWithMemory bool
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize workflow state and create epic",
	RunE:  runInit,
}

func init() {
	initCmd.Flags().StringVar(&initEpicTitle, "epic", "", "Epic title")
	initCmd.Flags().StringVarP(&initDesc, "description", "d", "", "Epic description")
	initCmd.Flags().BoolVar(&initWithMemory, "with-memory", false, "Bootstrap mempalace memory")
}

func runInit(cmd *cobra.Command, args []string) error {
	stateDir, _ := cmd.Root().PersistentFlags().GetString("state-dir")
	projectDir, _ := cmd.Root().PersistentFlags().GetString("project-dir")
	jsonOutput, _ := cmd.Root().PersistentFlags().GetBool("json")

	statePath := state.FilePath(stateDir)

	existing, err := state.Read(statePath)
	if err == nil && existing.EpicID != "" {
		if jsonOutput {
			out := map[string]interface{}{
				"epic_id":     existing.EpicID,
				"created":     false,
				"phase":       existing.Phase,
				"memory_mode": existing.MemoryMode,
				"wing":        existing.Wing,
			}
			data, _ := json.MarshalIndent(out, "", "  ")
			fmt.Println(string(data))
			return nil
		}
		fmt.Printf("Workflow already initialized with epic %s\n", existing.EpicID)
		return nil
	}
	if err != nil && !errors.Is(err, state.ErrNotInitialized) {
		return err
	}

	if initEpicTitle == "" {
		return fmt.Errorf("--epic title is required")
	}

	epicID, err := tk.Create(initEpicTitle, "-t", "epic", "--tags", "team-epic", "-d", initDesc)
	if err != nil {
		return err
	}

	s := &state.State{
		Version:    1,
		ProjectDir: projectDir,
		EpicID:     epicID,
		Phase:      workflow.PhasePlanning,
		MemoryMode: "degraded",
		Mempalace: state.MempalaceState{
			Rooms: make(map[string][]string),
		},
		Bootstrap: state.Bootstrap{
			BaseBranch: "main",
		},
		Tasks: state.Tasks{
			Active:         []string{},
			ClosedThisWave: []string{},
			StaffReview: state.StaffReview{
				HasBlockers: nil,
			},
		},
	}

	wing, err := mempalace.DetectWing(projectDir)
	if err == nil {
		s.Wing = wing
		s.Mempalace.Wing = wing
	}

	if initWithMemory {
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

		if initErr = mempalace.Init(projectDir, true, true); initErr != nil {
			fmt.Fprintf(os.Stderr, "warning: mempalace init failed: %v\n", initErr)
			s.MemoryMode = "degraded"
		} else {
			if len(gitignoreBackup) > 0 {
				_ = os.WriteFile(gitignorePath, gitignoreBackup, 0644)
			}
			if err := mempalace.Mine(projectDir, wing); err != nil {
				fmt.Fprintf(os.Stderr, "warning: mempalace mine failed: %v\n", err)
				s.MemoryMode = "degraded"
			} else {
				if err := mempalace.Compress(wing); err != nil {
					fmt.Fprintf(os.Stderr, "warning: mempalace compress failed: %v\n", err)
					s.MemoryMode = "degraded"
				} else {
					s.MemoryMode = "active"
				}
			}
		}

		yamlPath := filepath.Join(projectDir, "mempalace.yaml")
		if data, err := os.ReadFile(yamlPath); err == nil {
			if ms, err := mempalace.ParseYAML(data); err == nil {
				s.Mempalace = *ms
				if ms.Wing != "" {
					s.Wing = ms.Wing
				}
			}
		}
	}

	if err := state.Write(statePath, s); err != nil {
		return err
	}

	if jsonOutput {
		out := map[string]interface{}{
			"epic_id":     s.EpicID,
			"created":     true,
			"phase":       s.Phase,
			"memory_mode": s.MemoryMode,
			"wing":        s.Wing,
		}
		data, _ := json.MarshalIndent(out, "", "  ")
		fmt.Println(string(data))
		return nil
	}

	fmt.Printf("Initialized workflow with epic %s\n", s.EpicID)
	return nil
}
