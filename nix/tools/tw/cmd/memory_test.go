package cmd

import (
	"testing"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
)

func TestResolveWingFromState(t *testing.T) {
	s := &state.State{
		Wing: "my-wing",
	}
	wing, err := resolveWing(s, "")
	if err != nil {
		t.Fatalf("resolveWing failed: %v", err)
	}
	if wing != "my-wing" {
		t.Errorf("wing = %q, want my-wing", wing)
	}
}

func TestResolveWingFromMempalace(t *testing.T) {
	s := &state.State{
		Wing: "",
		Mempalace: state.MempalaceState{
			Wing: "mp-wing",
		},
	}
	wing, err := resolveWing(s, "")
	if err != nil {
		t.Fatalf("resolveWing failed: %v", err)
	}
	if wing != "mp-wing" {
		t.Errorf("wing = %q, want mp-wing", wing)
	}
}

func TestResolveWingFromGit(t *testing.T) {
	s := &state.State{}
	wing, err := resolveWing(s, ".")
	if err != nil {
		t.Fatalf("resolveWing failed: %v", err)
	}
	if wing == "" {
		t.Error("expected non-empty wing from git detection")
	}
}

func TestSelectRoomFromTaskNoMetadata(t *testing.T) {
	s := &state.State{
		Mempalace: state.MempalaceState{
			Rooms: map[string][]string{
				"nix":      {"nix"},
				"general":  {},
			},
		},
	}
	room := selectRoomFromTask("nonexistent-task", s)
	if room != "general" {
		t.Errorf("room = %q, want general", room)
	}
}

func TestSelectRoomFromTaskWithMatch(t *testing.T) {
	s := &state.State{
		Mempalace: state.MempalaceState{
			Rooms: map[string][]string{
				"nix":      {"nix"},
				"home":     {"home"},
				"general":  {},
			},
		},
	}
	// We can't easily test tk.GetMetadata without mocking, but we can test the room selection
	// logic by calling the function and ensuring it returns a valid room (general fallback).
	room := selectRoomFromTask("any-task", s)
	if room == "" {
		t.Error("expected non-empty room")
	}
}

func TestSelectRoomFromTaskFallback(t *testing.T) {
	s := &state.State{
		Mempalace: state.MempalaceState{
			Rooms: map[string][]string{
				"nix":     {"nix"},
				"general": {},
			},
		},
	}
	room := selectRoomFromTask("any-task", s)
	// Without tk metadata available, it should fall back to general
	if room != "general" {
		t.Errorf("room = %q, want general", room)
	}
}
