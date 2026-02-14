package commit

import (
	"bytes"
	_ "embed"
	"text/template"
)

//go:embed prompt.txt
var promptTemplate string

// GitContext holds git information for the prompt template
type GitContext struct {
	Branch        string
	RecentCommits string
	DiffStat      string
	StagedDiff    string
}

// BuildPrompt creates a prompt with all git context injected
func BuildPrompt(ctx GitContext) (string, error) {
	tmpl, err := template.New("commit").Parse(promptTemplate)
	if err != nil {
		return "", err
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, ctx); err != nil {
		return "", err
	}

	return buf.String(), nil
}
