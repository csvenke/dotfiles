package mempalace

import (
	"reflect"
	"testing"
)

func TestDetectWing(t *testing.T) {
	wing, err := DetectWing(".")
	if err != nil {
		t.Fatalf("DetectWing failed: %v", err)
	}
	if wing == "" {
		t.Error("expected non-empty wing")
	}
}

func TestParseYAML(t *testing.T) {
	data := []byte(`wing: dotfiles
rooms:
- name: documentation
  description: Files from docs/
  keywords:
  - documentation
  - docs
- name: general
  description: General
  keywords: []
`)
	ms, err := ParseYAML(data)
	if err != nil {
		t.Fatalf("ParseYAML failed: %v", err)
	}
	if ms.Wing != "dotfiles" {
		t.Errorf("wing = %q, want dotfiles", ms.Wing)
	}
	want := map[string][]string{
		"documentation": {"documentation", "docs"},
		"general":       nil,
	}
	if !reflect.DeepEqual(ms.Rooms, want) {
		t.Errorf("rooms = %v, want %v", ms.Rooms, want)
	}
}

func TestParseStatus(t *testing.T) {
	input := `
WING: dotfiles
  ROOM: home                   184 drawers
  ROOM: nix                     10 drawers
WING: other
  ROOM: general                  3 drawers
`
	result, err := parseStatus(input, "dotfiles")
	if err != nil {
		t.Fatalf("parseStatus failed: %v", err)
	}
	if result["wing"] != "dotfiles" {
		t.Errorf("wing = %q, want dotfiles", result["wing"])
	}
	if result["rooms"] != 2 {
		t.Errorf("rooms = %d, want 2", result["rooms"])
	}
	if result["drawers"] != 194 {
		t.Errorf("drawers = %d, want 194", result["drawers"])
	}

	result2, err := parseStatus(input, "other")
	if err != nil {
		t.Fatalf("parseStatus failed: %v", err)
	}
	if result2["drawers"] != 3 {
		t.Errorf("drawers = %d, want 3", result2["drawers"])
	}
}
