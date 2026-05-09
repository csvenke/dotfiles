package state

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"syscall"
)

var ErrNotInitialized = errors.New("no workflow initialized. Run `tw init`")

const StateFileName = "state.json"

type State struct {
	Version    int            `json:"version"`
	ProjectDir string         `json:"project_dir"`
	EpicID     string         `json:"epic_id"`
	Phase      string         `json:"phase"`
	Plan       Plan           `json:"plan"`
	Wave       Wave           `json:"wave"`
	MemoryMode string         `json:"memory_mode"`
	Wing       string         `json:"wing"`
	Mempalace  MempalaceState `json:"mempalace"`
	Bootstrap  Bootstrap      `json:"bootstrap"`
	Tasks      Tasks          `json:"tasks"`
	Todos      []Todo         `json:"todos"`
}

type Plan struct {
	Approved   bool   `json:"approved"`
	TextPath   string `json:"text_path"`
	ApprovedAt string `json:"approved_at"`
}

type Wave struct {
	Number      int    `json:"number"`
	CurrentStep int    `json:"current_step"`
	StartedAt   string `json:"started_at"`
}

type MempalaceState struct {
	Wing  string              `json:"wing"`
	Rooms map[string][]string `json:"rooms"`
}

type Bootstrap struct {
	BaseBranch             string `json:"base_branch"`
	LintCommand            string `json:"lint_command"`
	TypecheckCommand       string `json:"typecheck_command"`
	UnitTestCommand        string `json:"unit_test_command"`
	IntegrationTestCommand string `json:"integration_test_command"`
	E2ECommand             string `json:"e2e_command"`
	BuildCommand           string `json:"build_command"`
	PlaywrightAvailable    bool   `json:"playwright_available"`
}

type Tasks struct {
	Active         []string    `json:"active"`
	ClosedThisWave []string    `json:"closed_this_wave"`
	StaffReview    StaffReview `json:"staff_review"`
}

type StaffReview struct {
	Passed      bool   `json:"passed"`
	HasBlockers *bool  `json:"has_blockers"`
	RunAt       string `json:"run_at"`
}

type Todo struct {
	ID     string `json:"id"`
	Text   string `json:"text"`
	Status string `json:"status"`
}

func DefaultStateDir() string {
	if home := os.Getenv("HOME"); home != "" {
		return filepath.Join(home, ".local", "share", "team-workflow")
	}
	return ""
}

func FilePath(stateDir string) string {
	return filepath.Join(stateDir, StateFileName)
}

func Read(path string) (*State, error) {
	lockPath := path + ".lock"
	lockFile, err := os.OpenFile(lockPath, os.O_RDWR|os.O_CREATE, 0644)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrNotInitialized
		}
		return nil, err
	}
	defer lockFile.Close()
	if err := syscall.Flock(int(lockFile.Fd()), syscall.LOCK_SH); err != nil {
		return nil, err
	}
	defer syscall.Flock(int(lockFile.Fd()), syscall.LOCK_UN)

	f, err := os.Open(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrNotInitialized
		}
		return nil, err
	}
	defer f.Close()

	data, err := io.ReadAll(f)
	if err != nil {
		return nil, err
	}
	var s State
	if err := json.Unmarshal(data, &s); err != nil {
		return nil, fmt.Errorf("invalid state file: %w", err)
	}
	return &s, nil
}

func Write(path string, s *State) error {
	lockPath := path + ".lock"
	lockFile, err := os.OpenFile(lockPath, os.O_RDWR|os.O_CREATE, 0644)
	if err != nil {
		return err
	}
	defer lockFile.Close()
	if err := syscall.Flock(int(lockFile.Fd()), syscall.LOCK_EX); err != nil {
		return err
	}
	defer syscall.Flock(int(lockFile.Fd()), syscall.LOCK_UN)

	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	data, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(dir, "state.json.tmp")
	if err != nil {
		return err
	}
	tmpPath := tmp.Name()
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		os.Remove(tmpPath)
		return err
	}
	if err := tmp.Close(); err != nil {
		os.Remove(tmpPath)
		return err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		os.Remove(tmpPath)
		return err
	}
	return nil
}
