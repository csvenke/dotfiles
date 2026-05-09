package mempalace

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/csvenke/dotfiles/tools/tw/internal/state"
)

func binaryExists() bool {
	_, err := exec.LookPath("mempalace")
	return err == nil
}

func run(args ...string) ([]byte, error) {
	if !binaryExists() {
		return nil, fmt.Errorf("mempalace binary not found")
	}
	cmd := exec.Command("mempalace", args...)
	var out bytes.Buffer
	var errOut bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &errOut
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("mempalace %s: %w\nstderr: %s", strings.Join(args, " "), err, errOut.String())
	}
	return out.Bytes(), nil
}

func Init(dir string, yes, noLLM bool) error {
	args := []string{"init"}
	if yes {
		args = append(args, "--yes")
	}
	if noLLM {
		args = append(args, "--no-llm")
	}
	args = append(args, dir)
	_, err := run(args...)
	return err
}

func Mine(dir string, wing string) error {
	args := []string{"mine", dir}
	if wing != "" {
		args = append(args, "--wing", wing)
	}
	_, err := run(args...)
	return err
}

func Compress(wing string) error {
	args := []string{"compress"}
	if wing != "" {
		args = append(args, "--wing", wing)
	}
	_, err := run(args...)
	return err
}

func Search(query, wing, room string, limit int) ([]map[string]interface{}, error) {
	args := []string{"search", query}
	if wing != "" {
		args = append(args, "--wing", wing)
	}
	if room != "" {
		args = append(args, "--room", room)
	}
	out, err := run(args...)
	if err != nil {
		return nil, err
	}
	var results []map[string]interface{}
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		results = append(results, map[string]interface{}{"text": line})
		if limit > 0 && len(results) >= limit {
			break
		}
	}
	return results, nil
}

func CheckDuplicate(content string) (bool, error) {
	return false, fmt.Errorf("check_duplicate not supported by mempalace CLI")
}

func AddDrawer(wing, room, content string) error {
	return fmt.Errorf("add_drawer not supported by mempalace CLI")
}

func KGQuery(entity string) ([]map[string]interface{}, error) {
	return nil, fmt.Errorf("kg_query not supported by mempalace CLI")
}

func KGAdd(subject, predicate, object string) error {
	return fmt.Errorf("kg_add not supported by mempalace CLI")
}

func Status(wing string) (map[string]interface{}, error) {
	out, err := run("status")
	if err != nil {
		return nil, err
	}
	return parseStatus(string(out), wing)
}

func DiaryWrite(agentName, entry string) error {
	return fmt.Errorf("diary_write not supported by mempalace CLI")
}

func CreateTunnel(sourceWing, sourceRoom, targetWing, targetRoom, label string) error {
	return fmt.Errorf("create_tunnel not supported by mempalace CLI")
}

func parseStatus(output, targetWing string) (map[string]interface{}, error) {
	result := map[string]interface{}{
		"available": true,
		"wing":      targetWing,
		"rooms":     0,
		"drawers":   0,
	}
	var currentWing string
	var totalDrawers int
	var roomCount int
	for _, line := range strings.Split(output, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "WING:") {
			currentWing = strings.TrimSpace(strings.TrimPrefix(trimmed, "WING:"))
			continue
		}
		if strings.HasPrefix(trimmed, "ROOM:") && currentWing == targetWing {
			roomCount++
			parts := strings.Fields(trimmed)
			if len(parts) >= 3 {
				countStr := parts[len(parts)-2]
				if n, err := parseInt(countStr); err == nil {
					totalDrawers += n
				}
			}
		}
	}
	result["rooms"] = roomCount
	result["drawers"] = totalDrawers
	return result, nil
}

func parseInt(s string) (int, error) {
	var n int
	_, err := fmt.Sscanf(s, "%d", &n)
	return n, err
}

func DetectWing(projectDir string) (string, error) {
	if projectDir == "" {
		var err error
		projectDir, err = os.Getwd()
		if err != nil {
			return "", err
		}
	}
	cmd := exec.Command("git", "-C", projectDir, "rev-parse", "--show-toplevel")
	out, err := cmd.Output()
	if err == nil {
		return filepath.Base(strings.TrimSpace(string(out))), nil
	}
	return filepath.Base(projectDir), nil
}

func ParseYAML(data []byte) (*state.MempalaceState, error) {
	var wing string
	rooms := make(map[string][]string)
	var currentRoom string
	var inKeywords bool
	for _, line := range strings.Split(string(data), "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "wing:") {
			wing = strings.TrimSpace(strings.TrimPrefix(trimmed, "wing:"))
			continue
		}
		if trimmed == "rooms:" {
			continue
		}
		if strings.HasPrefix(trimmed, "- name:") {
			currentRoom = strings.TrimSpace(strings.TrimPrefix(trimmed, "- name:"))
			rooms[currentRoom] = nil
			inKeywords = false
			continue
		}
		if strings.HasPrefix(trimmed, "keywords:") {
			inKeywords = true
			continue
		}
		if inKeywords && strings.HasPrefix(trimmed, "- ") {
			kw := strings.TrimSpace(strings.TrimPrefix(trimmed, "- "))
			rooms[currentRoom] = append(rooms[currentRoom], kw)
			continue
		}
		if trimmed == "" || strings.HasPrefix(trimmed, "description:") {
			inKeywords = false
			continue
		}
	}
	return &state.MempalaceState{Wing: wing, Rooms: rooms}, nil
}
