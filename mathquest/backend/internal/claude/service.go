package claude

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
)

const claudeAPIURL = "https://api.anthropic.com/v1/messages"
const claudeModel = "claude-sonnet-4-20250514"

type Service struct {
	apiKey string
	client *http.Client
}

func NewService(apiKey string) *Service {
	return &Service{
		apiKey: apiKey,
		client: &http.Client{},
	}
}

type ImageSource struct {
	Type      string `json:"type"`
	MediaType string `json:"media_type"`
	Data      string `json:"data"`
}

type ContentBlock struct {
	Type   string       `json:"type"`
	Text   string       `json:"text,omitempty"`
	Source *ImageSource `json:"source,omitempty"`
}

type Message struct {
	Role    string         `json:"role"`
	Content []ContentBlock `json:"content"`
}

type ClaudeRequest struct {
	Model     string    `json:"model"`
	MaxTokens int       `json:"max_tokens"`
	Messages  []Message `json:"messages"`
}

type ClaudeResponse struct {
	Content []struct {
		Type string `json:"type"`
		Text string `json:"text"`
	} `json:"content"`
	StopReason string `json:"stop_reason"`
	Error      *struct {
		Type    string `json:"type"`
		Message string `json:"message"`
	} `json:"error"`
}

type MathSolution struct {
	Problem         string   `json:"problem"`
	Solution        string   `json:"solution"`
	Steps           []string `json:"steps"`
	RawLatex        string   `json:"raw_latex"`
	DifficultyLevel string   `json:"difficulty_level"`
}

const solveMathPrompt = `You are a careful math tutor helping students solve problems step by step.

Analyze the math problem in this image and provide a complete solution.
Read the problem exactly as written in the image before solving.

Rules you MUST follow:
- Preserve the original language and script from the image (for example Uzbek, Russian, English). Do not translate unless explicitly asked.
- Do not invent missing numbers, symbols, or words.
- If the image is unclear or incomplete, say so explicitly in "solution" and "steps" instead of guessing.
- Keep "problem" as the exact transcription of what you can read from the image.

IMPORTANT: Respond ONLY with valid JSON in this exact format (no markdown, no code blocks):
{
  "problem": "exact text transcribed from image",
  "solution": "final answer or a clear message if unreadable",
  "steps": ["step 1 explanation", "step 2 explanation", ...],
  "raw_latex": "the problem and solution in LaTeX format",
  "difficulty_level": "elementary|middle_school|high_school|college"
}
`

func parseSolutionFromText(responseText string) (*MathSolution, error) {
	var solution MathSolution
	if err := json.Unmarshal([]byte(responseText), &solution); err == nil {
		return &solution, nil
	}

	trimmed := strings.TrimSpace(responseText)
	trimmed = strings.TrimPrefix(trimmed, "```json")
	trimmed = strings.TrimPrefix(trimmed, "```")
	trimmed = strings.TrimSuffix(trimmed, "```")
	trimmed = strings.TrimSpace(trimmed)

	if err := json.Unmarshal([]byte(trimmed), &solution); err == nil {
		return &solution, nil
	}

	start := strings.Index(trimmed, "{")
	end := strings.LastIndex(trimmed, "}")
	if start >= 0 && end > start {
		if err := json.Unmarshal([]byte(trimmed[start:end+1]), &solution); err == nil {
			return &solution, nil
		}
	}

	return nil, fmt.Errorf("response is not valid solution JSON")
}

func (s *Service) SolveMathProblem(imageBase64, mediaType string) (*MathSolution, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("Claude API key not configured")
	}

	reqBody := ClaudeRequest{
		Model:     claudeModel,
		MaxTokens: 2048,
		Messages: []Message{
			{
				Role: "user",
				Content: []ContentBlock{
					{
						Type: "image",
						Source: &ImageSource{
							Type:      "base64",
							MediaType: mediaType,
							Data:      imageBase64,
						},
					},
					{
						Type: "text",
						Text: solveMathPrompt,
					},
				},
			},
		},
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", claudeAPIURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", s.apiKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to call Claude API: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Claude API error (status %d): %s", resp.StatusCode, string(body))
	}

	var claudeResp ClaudeResponse
	if err := json.Unmarshal(body, &claudeResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if claudeResp.Error != nil {
		return nil, fmt.Errorf("Claude API error: %s", claudeResp.Error.Message)
	}

	if len(claudeResp.Content) == 0 {
		return nil, fmt.Errorf("no content in Claude response")
	}

	responseText := strings.TrimSpace(claudeResp.Content[0].Text)
	solution, err := parseSolutionFromText(responseText)
	if err != nil {
		// If parsing fails, try to extract info manually
		return &MathSolution{
			Problem:         "Unable to parse problem from image",
			Solution:        "Could not parse model response as structured solution. Please retake the photo.",
			Steps:           []string{"Could not parse structured response.", responseText},
			RawLatex:        "",
			DifficultyLevel: "unknown",
		}, nil
	}

	if solution.Steps == nil {
		solution.Steps = []string{}
	}
	if strings.TrimSpace(solution.Solution) == "" {
		solution.Solution = "Could not determine a final answer from the image."
	}
	if strings.TrimSpace(solution.Problem) == "" {
		solution.Problem = "Problem text could not be read clearly from image."
	}
	if strings.TrimSpace(solution.DifficultyLevel) == "" {
		solution.DifficultyLevel = "unknown"
	}

	return solution, nil
}
