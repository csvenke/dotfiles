package commands

import (
	"fmt"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/csvenke/wt/internal/git"
	"github.com/csvenke/wt/internal/worktree"
	"github.com/spf13/cobra"
)

var switchCmd = &cobra.Command{
	Use:   "switch",
	Short: "Switch to a worktree interactively",
	Long:  `Switch to a worktree using an interactive fzf-style selection.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		worktrees, err := worktree.List()
		if err != nil {
			return err
		}

		if len(worktrees) == 0 {
			fmt.Println("No worktrees found")
			return nil
		}

		// Filter out bare worktrees
		var selectable []git.WorktreeInfo
		for _, wt := range worktrees {
			if !wt.Bare {
				selectable = append(selectable, wt)
			}
		}

		if len(selectable) == 0 {
			fmt.Println("No switchable worktrees found")
			return nil
		}

		// Create list items
		items := make([]list.Item, len(selectable))
		for i, wt := range selectable {
			items[i] = switchItem{info: wt}
		}

		// Run interactive selection
		m := newSwitchModel(items, selectable)
		p := tea.NewProgram(m)
		finalModel, err := p.Run()
		if err != nil {
			return err
		}

		result := finalModel.(switchModel)
		if result.selected == nil {
			return nil
		}

		// Output the path for shell integration
		return worktree.Switch(result.selected.Path)
	},
}

// switchItem implements list.Item
type switchItem struct {
	info git.WorktreeInfo
}

func (w switchItem) FilterValue() string { return w.info.Path }
func (w switchItem) Title() string       { return w.info.Path }
func (w switchItem) Description() string {
	if w.info.Branch != "" {
		return w.info.Branch
	}
	return w.info.Commit[:7]
}

// switchModel is the Bubble Tea model for switch command
type switchModel struct {
	list     list.Model
	items    []git.WorktreeInfo
	selected *git.WorktreeInfo
	quitting bool
}

func newSwitchModel(items []list.Item, worktrees []git.WorktreeInfo) switchModel {
	const defaultWidth = 40
	const listHeight = 14

	l := list.New(items, list.NewDefaultDelegate(), defaultWidth, listHeight)
	l.Title = "Select worktree to switch to"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = lipgloss.NewStyle().
		MarginLeft(2).
		Bold(true)

	return switchModel{
		list:  l,
		items: worktrees,
	}
}

func (m switchModel) Init() tea.Cmd {
	return nil
}

func (m switchModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetWidth(msg.Width)
		return m, nil

	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			m.quitting = true
			return m, tea.Quit

		case tea.KeyEnter:
			idx := m.list.Index()
			if idx >= 0 && idx < len(m.items) {
				m.selected = &m.items[idx]
			}
			m.quitting = true
			return m, tea.Quit
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m switchModel) View() string {
	if m.quitting {
		return ""
	}
	return "\n" + m.list.View()
}
