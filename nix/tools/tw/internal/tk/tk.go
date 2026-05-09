package tk

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
	"regexp"
	"strings"
)

func run(args ...string) ([]byte, error) {
	cmd := exec.Command("tk", args...)
	var out bytes.Buffer
	var errOut bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &errOut
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("tk %s: %w\nstderr: %s", strings.Join(args, " "), err, errOut.String())
	}
	return out.Bytes(), nil
}

func Create(title string, extraArgs ...string) (string, error) {
	args := append([]string{"create", title}, extraArgs...)
	out, err := run(args...)
	if err != nil {
		return "", err
	}
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(lines) == 0 {
		return "", fmt.Errorf("tk create returned empty output")
	}
	return strings.TrimSpace(lines[len(lines)-1]), nil
}

func Show(id string) (string, error) {
	out, err := run("show", id)
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func EscapeJQ(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, `"`, `\"`)
	return s
}

func LS(status, tag string) ([]map[string]interface{}, error) {
	filter := `select(.type == "task" and (.tags // [] | index("` + EscapeJQ(tag) + `"))`
	if status != "" {
		filter += ` and .status == "` + EscapeJQ(status) + `"`
	}
	filter += `)`
	out, err := run("query", filter)
	if err != nil {
		return nil, err
	}
	return parseJSONLines(out)
}

func Start(id string) error {
	_, err := run("start", id)
	return err
}

func Close(id string) error {
	_, err := run("close", id)
	return err
}

func AddNote(id, text string) error {
	_, err := run("add-note", id, text)
	return err
}

type ReadyTask struct {
	ID       string
	Priority string
	Status   string
	Title    string
}

func Ready(tag string) ([]ReadyTask, error) {
	args := []string{"ready"}
	if tag != "" {
		args = append(args, "-T", tag)
	}
	out, err := run(args...)
	if err != nil {
		return nil, err
	}
	var tasks []ReadyTask
	re := regexp.MustCompile(`^(\S+)\s+\[P?(\d+)\]\[([^\]]+)\]\s+-\s+(.*)$`)
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line == "" {
			continue
		}
		m := re.FindStringSubmatch(line)
		if m == nil {
			tasks = append(tasks, ReadyTask{Title: line})
			continue
		}
		tasks = append(tasks, ReadyTask{
			ID:       m[1],
			Priority: m[2],
			Status:   m[3],
			Title:    m[4],
		})
	}
	return tasks, nil
}

func Query(filter string) ([]map[string]interface{}, error) {
	out, err := run("query", filter)
	if err != nil {
		return nil, err
	}
	return parseJSONLines(out)
}

func ReadyDetails(tag string) ([]map[string]interface{}, error) {
	readyTasks, err := Ready(tag)
	if err != nil {
		return nil, err
	}
	var results []map[string]interface{}
	for _, rt := range readyTasks {
		if rt.ID == "" {
			continue
		}
		details, err := Query(fmt.Sprintf(`select(.id == "%s")`, EscapeJQ(rt.ID)))
		if err != nil || len(details) == 0 {
			continue
		}
		results = append(results, details[0])
	}
	return results, nil
}

func GetMetadata(id string) (map[string]string, error) {
	out, err := Show(id)
	if err != nil {
		return nil, err
	}
	metadata := make(map[string]string)
	for _, line := range strings.Split(out, "\n") {
		if strings.HasPrefix(line, "METADATA:") {
			parseMetadataLine(line, metadata)
		}
	}
	return metadata, nil
}

func parseMetadataLine(line string, out map[string]string) {
	line = strings.TrimPrefix(line, "METADATA:")
	line = strings.TrimSpace(line)
	parts := strings.Split(line, ";")
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		kv := strings.SplitN(part, "=", 2)
		if len(kv) == 2 {
			out[strings.TrimSpace(kv[0])] = strings.TrimSpace(kv[1])
		}
	}
}

func parseJSONLines(data []byte) ([]map[string]interface{}, error) {
	var results []map[string]interface{}
	for _, line := range strings.Split(strings.TrimSpace(string(data)), "\n") {
		if line == "" {
			continue
		}
		var obj map[string]interface{}
		if err := json.Unmarshal([]byte(line), &obj); err != nil {
			return nil, fmt.Errorf("tk query json parse: %w", err)
		}
		results = append(results, obj)
	}
	return results, nil
}
