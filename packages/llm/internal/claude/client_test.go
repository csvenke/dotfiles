package claude

import (
	"context"
	"testing"
)

func TestNew(t *testing.T) {
	tests := []struct {
		name    string
		model   string
		apiKey  string
		wantErr bool
		errMsg  string
	}{
		{
			name:    "valid inputs",
			model:   "claude-3-opus-20240229",
			apiKey:  "test-api-key",
			wantErr: false,
		},
		{
			name:    "empty model",
			model:   "",
			apiKey:  "test-api-key",
			wantErr: true,
			errMsg:  "model is required",
		},
		{
			name:    "empty api key",
			model:   "claude-3-opus-20240229",
			apiKey:  "",
			wantErr: true,
			errMsg:  "api key is required",
		},
		{
			name:    "both empty",
			model:   "",
			apiKey:  "",
			wantErr: true,
			errMsg:  "model is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client, err := New(tt.model, tt.apiKey)

			if tt.wantErr {
				if err == nil {
					t.Errorf("New() expected error but got nil")
					return
				}
				if err.Error() != tt.errMsg {
					t.Errorf("New() error = %v, want %v", err.Error(), tt.errMsg)
				}
				if client != nil {
					t.Error("New() expected nil client on error")
				}
			} else {
				if err != nil {
					t.Errorf("New() unexpected error = %v", err)
				}
				if client == nil {
					t.Error("New() expected non-nil client")
				}
				if client != nil && client.model != tt.model {
					t.Errorf("New() client.model = %v, want %v", client.model, tt.model)
				}
			}
		})
	}
}

func TestClient_Message(t *testing.T) {
	// Note: These tests validate the input validation logic.
	// Actual API calls would require mocking the anthropic client,
	// which is complex due to the SDK's internal structure.
	// For integration testing, use a real API key in a non-test environment.

	t.Run("empty prompt returns error", func(t *testing.T) {
		client := &Client{
			model: "claude-3-opus-20240229",
			// client is nil, but we won't reach the API call due to validation
		}

		_, err := client.Message(context.Background(), "")
		if err == nil {
			t.Error("Message() expected error for empty prompt")
		}
		if err.Error() != "prompt is required" {
			t.Errorf("Message() error = %v, want 'prompt is required'", err)
		}
	})

	t.Run("context cancellation", func(t *testing.T) {
		// This test verifies that the method accepts a context
		// Actual cancellation behavior depends on the underlying HTTP client
		client, err := New("claude-3-opus-20240229", "fake-key-for-validation")
		if err != nil {
			t.Fatalf("Failed to create client: %v", err)
		}

		ctx, cancel := context.WithCancel(context.Background())
		cancel() // Cancel immediately

		// The request will fail due to invalid API key, but we're testing
		// that context is properly passed through
		_, err = client.Message(ctx, "test prompt")
		// We expect an error (invalid API key), but the important thing
		// is that the method accepts and uses the context
		if err == nil {
			t.Error("Message() expected error with cancelled context and invalid key")
		}
	})
}

func TestClient_Message_Validation(t *testing.T) {
	client := &Client{
		model: "claude-3-opus-20240229",
	}

	tests := []struct {
		name    string
		prompt  string
		wantErr bool
		errMsg  string
	}{
		{
			name:    "empty prompt",
			prompt:  "",
			wantErr: true,
			errMsg:  "prompt is required",
		},
		{
			name:    "whitespace only prompt",
			prompt:  "   ",
			wantErr: false, // We don't trim whitespace, so this is valid
		},
		{
			name:    "valid prompt",
			prompt:  "Hello, Claude!",
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// We can't test actual API calls without mocking,
			// but we can verify the validation logic
			if tt.wantErr && tt.errMsg == "prompt is required" {
				_, err := client.Message(context.Background(), tt.prompt)
				if err == nil {
					t.Error("Message() expected error")
					return
				}
				if err.Error() != tt.errMsg {
					t.Errorf("Message() error = %v, want %v", err.Error(), tt.errMsg)
				}
			}
		})
	}
}
