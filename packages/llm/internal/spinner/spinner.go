package spinner

import (
	"fmt"
	"time"
)

// Spinner represents a simple CLI spinner.
type Spinner struct {
	stopChan chan struct{}
}

// New creates a new Spinner.
func New() *Spinner {
	return &Spinner{
		stopChan: make(chan struct{}),
	}
}

// Start begins displaying the spinner with a given message.
// It runs in a separate goroutine.
func (s *Spinner) Start(message string) {
	go func() {
		// Spinner characters
		chars := []string{"|", "/", "-", "\\"}
		i := 0
		// Print initial message
		fmt.Print(message)
		for {
			select {
			case <-s.stopChan:
				// Clear the line and exit
				fmt.Print("\r\033[K")
				return
			default:
				// Animate the spinner
				fmt.Printf("\r %s ", chars[i])
				i = (i + 1) % len(chars)
				time.Sleep(100 * time.Millisecond)
			}
		}
	}()
}

// Stop halts the spinner.
func (s *Spinner) Stop() {
	close(s.stopChan)
}
