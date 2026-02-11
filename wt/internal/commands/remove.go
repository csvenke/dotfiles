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

var removeCmd = &cobra.Command{
	Use:   "remove",
	Short: "Remove a worktree interactively",
	Long:  `Remove a worktree using an interactive fzf-style selection.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		worktrees, err := worktree.List()
		if err != nil {
			return err
		}

		if len(worktrees) == 0 {
			fmt.Println("No worktrees found")
			return nil
		}

		// Filter out bare/main worktree
		var selectable []git.WorktreeInfo
		for _, wt := range worktrees {
			if !wt.Bare {
				selectable = append(selectable, wt)
			}
		}

		if len(selectable) == 0 {
			fmt.Println("No removable worktrees found")
			return nil
		}

		// Create list items
		items := make([]list.Item, len(selectable))
		for i, wt := range selectable {
			items[i] = worktreeItem{info: wt}
		}

		// Run interactive selection
		m := newRemoveModel(items, selectable)
		p := tea.NewProgram(m)
		finalModel, err := p.Run()
		if err != nil {
			return err
		}

		result := finalModel.(removeModel)
		if result.selected == nil {
			return nil
		}

		// Confirm removal
		fmt.Printf("Removing %s\n", result.selected.Path)
		return worktree.Remove(result.selected.Path)
	},
}

// worktreeItem implements list.Item
type worktreeItem struct {
	info git.WorktreeInfo
}

func (w worktreeItem) FilterValue() string { return w.info.Path }
func (w worktreeItem) Title() string       { return w.info.Path }
func (w worktreeItem) Description() string {
	if w.info.Branch != "" {
		return w.info.Branch
	}
	return w.info.Commit[:7]
}

// removeModel is the Bubble Tea model for remove command
type removeModel struct {
	list     list.Model
	items    []git.WorktreeInfo
	selected *git.WorktreeInfo
	quitting bool
}

func newRemoveModel(items []list.Item, worktrees []git.WorktreeInfo) removeModel {
	const defaultWidth = 40
	const listHeight = 14

	l := list.New(items, list.NewDefaultDelegate(), defaultWidth, listHeight)
	l.Title = "Select worktree to remove"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = lipgloss.NewStyle().
		MarginLeft(2).
		Bold(true)

	return removeModel{
		list:  l,
		items: worktrees,
	}
}

func (m removeModel) Init() tea.Cmd {
	return nil
}

func (m removeModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
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

func (m removeModel) View() string {
	if m.quitting {
		return ""
	}
	return "\n" + m.list.View()
}
