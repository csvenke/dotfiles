package state

import (
	"os"
	"path/filepath"
	"testing"
)

func TestReadWrite(t *testing.T) {
	tmpDir := t.TempDir()
	path := filepath.Join(tmpDir, "state.json")

	s := &State{
		Version:    1,
		ProjectDir: "/tmp/project",
		EpicID:     "epic-123",
		Phase:      "PLANNING",
		MemoryMode: "degraded",
		Mempalace: MempalaceState{
			Wing:  "test",
			Rooms: map[string][]string{"general": {}},
		},
	}

	if err := Write(path, s); err != nil {
		t.Fatalf("write failed: %v", err)
	}

	read, err := Read(path)
	if err != nil {
		t.Fatalf("read failed: %v", err)
	}
	if read.EpicID != s.EpicID {
		t.Errorf("epicID mismatch: got %q, want %q", read.EpicID, s.EpicID)
	}
	if read.Phase != s.Phase {
		t.Errorf("phase mismatch: got %q, want %q", read.Phase, s.Phase)
	}
}

func TestReadNotExist(t *testing.T) {
	tmpDir := t.TempDir()
	path := filepath.Join(tmpDir, "state.json")
	_, err := Read(path)
	if err != ErrNotInitialized {
		t.Errorf("expected ErrNotInitialized, got %v", err)
	}
}

func TestAtomicWrite(t *testing.T) {
	tmpDir := t.TempDir()
	path := filepath.Join(tmpDir, "state.json")

	s := &State{EpicID: "abc"}
	if err := Write(path, s); err != nil {
		t.Fatalf("write failed: %v", err)
	}

	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("stat failed: %v", err)
	}
	if info.Size() == 0 {
		t.Error("state file is empty")
	}
}

func TestReadWriteTodos(t *testing.T) {
	tmpDir := t.TempDir()
	path := filepath.Join(tmpDir, "state.json")

	s := &State{
		EpicID: "epic-123",
		Todos: []Todo{
			{ID: "t1", Text: "Todo one", Status: "open"},
			{ID: "t2", Text: "Todo two", Status: "completed"},
		},
	}

	if err := Write(path, s); err != nil {
		t.Fatalf("write failed: %v", err)
	}

	read, err := Read(path)
	if err != nil {
		t.Fatalf("read failed: %v", err)
	}
	if len(read.Todos) != 2 {
		t.Fatalf("expected 2 todos, got %d", len(read.Todos))
	}
	if read.Todos[0].ID != "t1" {
		t.Errorf("todo id mismatch: got %q, want %q", read.Todos[0].ID, "t1")
	}
	if read.Todos[1].Status != "completed" {
		t.Errorf("todo status mismatch: got %q, want %q", read.Todos[1].Status, "completed")
	}
}
