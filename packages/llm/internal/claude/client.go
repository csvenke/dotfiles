package claude

import (
	"context"
	"errors"
	"fmt"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
	"github.com/anthropics/anthropic-sdk-go/packages/param"
)

// Client provides a simplified interface to the Anthropic Claude API.
type Client struct {
	model  string
	client *anthropic.Client
}

// New creates a new Claude client with the given model and API key.
// Returns an error if model or apiKey is empty.
func New(model, apiKey string) (*Client, error) {
	if model == "" {
		return nil, errors.New("model is required")
	}
	if apiKey == "" {
		return nil, errors.New("api key is required")
	}

	client := anthropic.NewClient(option.WithAPIKey(apiKey))

	return &Client{
		model:  model,
		client: &client,
	}, nil
}

// Message sends a prompt to Claude and returns the text response.
// Uses max_tokens=1024 and temperature=0.7 by default.
// Returns an error if the prompt is empty or the API call fails.
func (c *Client) Message(ctx context.Context, prompt string) (string, error) {
	if prompt == "" {
		return "", errors.New("prompt is required")
	}

	message, err := c.client.Messages.New(ctx, anthropic.MessageNewParams{
		Model:       anthropic.Model(c.model),
		MaxTokens:   1024,
		Temperature: param.Opt[float64]{Value: 0.7},
		Messages: []anthropic.MessageParam{
			anthropic.NewUserMessage(anthropic.NewTextBlock(prompt)),
		},
	})
	if err != nil {
		return "", fmt.Errorf("failed to send message: %w", err)
	}

	// Extract text content from the response
	if len(message.Content) == 0 {
		return "", errors.New("empty response from Claude")
	}

	// Get the text from the first content block
	if message.Content[0].Text == "" {
		return "", errors.New("unexpected response type from Claude")
	}

	return message.Content[0].Text, nil
}
