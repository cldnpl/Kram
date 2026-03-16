package claude

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"
)

const claudeAPIURL = "https://api.anthropic.com/v1/messages"
const claudeModel = "claude-sonnet-4-20250514"
const claudeRequestTimeout = 28 * time.Second
const maxImageBase64Chars = 10 * 1024 * 1024
const minImageBase64Chars = 64
const maxResponseProblemChars = 2000
const maxResponseSolutionChars = 2500
const maxResponseRawLatexChars = 4000
const maxResponseStepChars = 2200
const maxResponseSteps = 14

type Service struct {
	apiKey string
	client *http.Client
}

func NewService(apiKey string) *Service {
	return &Service{
		apiKey: apiKey,
		client: &http.Client{Timeout: claudeRequestTimeout},
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
	Problem             string   `json:"problem"`
	Solution            string   `json:"solution"`
	Steps               []string `json:"steps"`
	StepsDetail         []string `json:"steps_detail,omitempty"`
	RawLatex            string   `json:"raw_latex"`
	DifficultyLevel     string   `json:"difficulty_level"`
	DetectedLanguage    string   `json:"detected_language"`
	ShouldSaveToHistory *bool    `json:"should_save_to_history,omitempty"`
	GraphData           *GraphData `json:"graph_data,omitempty"`
}

type GraphData struct {
	IsFunction     bool                `json:"is_function"`
	Expression     string              `json:"expression"`
	Variable       string              `json:"variable"`
	Domain         string              `json:"domain"`
	Range          string              `json:"range"`
	Intercepts     map[string][]string `json:"intercepts"`
	Asymptotes     map[string][]string `json:"asymptotes"`
	CriticalPoints []CriticalPoint     `json:"critical_points,omitempty"`
	Behavior       map[string]string   `json:"behavior"`
}

type CriticalPoint struct {
	X    string `json:"x"`
	Y    string `json:"y"`
	Type string `json:"type"`
}

const solveMathPrompt = `You are a careful math tutor helping students solve problems step by step.

Analyze the math problem in this image and provide a complete solution.
Read the problem exactly as written in the image before solving.

Rules you MUST follow:
- Use ONLY Italian language in all prose fields ("solution" and explanations). English tokens are forbidden in prose.
- Preserve the original language and script from the image only in "problem" transcription. Write "solution" and step explanations in Italian.
- Do not invent missing numbers, symbols, or words.
- If the image is unclear or incomplete, say so explicitly in "solution" and "steps" instead of guessing.
- If OCR output looks corrupted, random, or inconsistent, stop and return a clean retake message instead of forcing a long solution.
- Keep reasoning efficient: do not repeat already completed transformations and avoid redundant recalculations.
- If the full derivation is very long, provide a concise but complete sequence of essential steps to avoid timeout.
- If you cannot compute a required determinant with certainty (especially 4x4), set "solution" to exactly "Errore di Capacità" and do not invent numeric results.
- If the input defines a function (for example f(x)=...), start "solution" with a compact graph-style summary in Italian: Cartesian axes behavior, intercepts, and curve trend.
- Keep "problem" as the exact transcription of what you can read from the image.
- Set "detected_language" to one of: en, it, fr, es, uz, unknown.
- Set "should_save_to_history" to false if the image is unclear, incomplete, unreadable, or the result is just an error/retake message. Otherwise set it to true.
- Each item in "steps" MUST use this exact format: "LATEX_STEP || DETAILED_EXPLANATION".
- In each step:
  - The part before "||" MUST contain only mathematical content in LaTeX (no prose words, no plain-language commentary).
  - The LaTeX part MUST be wrapped in double dollars and start with \displaystyle, for example: $$\displaystyle \frac{1}{2}x=3$$
  - Every mathematical expression must be pure LaTeX display style only; no orphan symbols, no broken fragments, no loose commas/numbers.
  - Use professional LaTeX only. Never use linear notation like a/b or integral(f(x)); use \frac{a}{b}, \int, \sin^n(x), greek symbols, etc.
  - In step LaTeX, never use "/" for fractions; always use \frac{...}{...}.
  - For definite integrals, limits must be vertical with \int_{...}^{...} (for example \int_{0}^{\frac{\pi}{2}}), never side-written limits.
  - If matrices/determinants are used, render with proper environments such as \begin{cases}...\end{cases} and \begin{vmatrix}...\end{vmatrix}.
  - Keep the full equation or transformation centered-ready and complete; do not output incoherent fragments.
  - If the expression is long, structure LaTeX using multiline formatting (for example \begin{aligned} line_1 \\ line_2 \end{aligned}) and keep alignment coherent (especially around "=").
  - Do not introduce stray OCR letters like "i" or "I" unless mathematically intended and explicitly defined.
- The part after "||" MUST be a complete, detailed explanation in Italian.
- The explanation language must be fully Italian; do not mix English words.
  - Inside the explanation, write only literal logical reasoning in prose.
  - Do not place equations or LaTeX formulas inside the explanation text.
  - Do not output symbolic math fragments in explanation (they belong only to LATEX_STEP).
  - Do not use bullet lists for mathematical content.
  - Do not output orphan punctuation/isolated tokens outside valid prose or LaTeX.
  - Explanations must clearly state what transformation/property/rule is used and why it is valid.
  - Mention identities explicitly when used, and include intermediate algebraic reasoning without skipping essential steps.
  - Explanation quality: at least 2 complete sentences per step, not short phrases.
  - Structure explanations into short paragraphs (2-3 lines each) separated by a blank line ("\n\n") inside the same step string.
  - For each step explanation, explicitly include these three labels in this exact order: **Titolo Step**, **Logica**, **Proprietà**.
  - Each paragraph must include at least one bold technical operation label using Markdown (for example **Sostituzione**, **Semplificazione**, **Proprietà**, **Risultato parziale**).
  - Never use ellipses ("...") in explanations; write complete statements.
  - Avoid short fragments like "therefore", "RHS", "apply property" without details.
  - If the user/problem requests Cramer, show all determinants explicitly (D, Dx, Dy, Dz, Dw as needed) with full determinant computation steps, no omissions.
  - Before final solution, include a verification by substitution into original equations; if verification fails, recompute.

IMPORTANT: Respond ONLY with valid JSON in this exact format (no markdown, no code blocks):
{
  "problem": "exact text transcribed from image",
  "solution": "final answer or a clear message if unreadable",
  "steps": ["$$\\displaystyle <latex step 1>$$ || <detailed explanation 1>", "$$\\displaystyle <latex step 2>$$ || <detailed explanation 2>"],
  "raw_latex": "the problem and solution in LaTeX format",
  "difficulty_level": "elementary|middle_school|high_school|college",
  "detected_language": "en|it|fr|es|uz|unknown",
  "should_save_to_history": true
}
`

const translateMathPromptTemplate = `You are translating a solved math explanation for a student.

Translate the provided JSON into %s.

Rules you MUST follow:
- Translate the human-readable prose in "problem", "solution", and every string in "steps".
- Keep numbers, equations, symbols, and mathematical meaning unchanged.
- Keep "raw_latex" unchanged.
- Keep "difficulty_level" unchanged.
- Keep "detected_language" unchanged.
- Keep "should_save_to_history" unchanged.
- Return the same number of steps.
- For each step string in "steps", preserve the exact format "LATEX_STEP || EXPLANATION".
- Do NOT translate or alter the LaTeX part before "||".
- Translate ONLY the explanation text after "||" into the target language.
- In translated explanations, use only the target language (except math symbols/LaTeX); do not leave mixed-language fragments.
- Keep paragraph breaks ("\n\n") and Markdown bold markers valid after translation.
- Keep the LaTeX step format as $$\displaystyle <formula>$$ exactly valid after translation.
- In translated explanations, keep only literal logic prose (no formulas/equations/LaTeX snippets).
- Keep output lightweight and avoid adding any extra keys or metadata.

IMPORTANT: Respond ONLY with valid JSON in this exact format (no markdown, no code blocks):
{
  "problem": "translated problem text",
  "solution": "translated final answer",
  "steps": ["$$\\displaystyle <same latex step 1>$$ || <translated detailed explanation 1>", "$$\\displaystyle <same latex step 2>$$ || <translated detailed explanation 2>"],
  "raw_latex": "original raw latex",
  "difficulty_level": "elementary|middle_school|high_school|college",
  "detected_language": "en|it|fr|es|uz|unknown",
  "should_save_to_history": true
}

Here is the JSON to translate:
%s
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

	sanitizedImage, sanitizeErr := sanitizeImageBase64(imageBase64)
	if sanitizeErr != nil {
		return unreadableRetakeSolution(), nil
	}

	reqBody := ClaudeRequest{
		Model:     claudeModel,
		MaxTokens: 1536,
		Messages: []Message{
			{
				Role: "user",
				Content: []ContentBlock{
					{
						Type: "image",
						Source: &ImageSource{
							Type:      "base64",
							MediaType: mediaType,
							Data:      sanitizedImage,
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

	responseText, err := s.runJSONRequest(reqBody)
	if err != nil {
		return unreadableRetakeSolution(), nil
	}
	solution, err := parseSolutionFromText(responseText)
	if err != nil {
		return unreadableRetakeSolution(), nil
	}

	normalizeSolutionPayload(solution)

	return solution, nil
}

const solveMathFromTextPrompt = `You are a careful math tutor helping students solve problems step by step.

Analyze the following math problem and provide a complete solution.

Rules you MUST follow:
- Use ONLY Italian language in all prose fields ("solution" and explanations). English tokens are forbidden in prose.
- Do not invent missing numbers, symbols, or words.
- Keep reasoning efficient: do not repeat already completed transformations and avoid redundant recalculations.
- If the full derivation is very long, provide a concise but complete sequence of essential steps to avoid timeout.
- If you cannot compute a required determinant with certainty (especially 4x4), set "solution" to exactly "Errore di Capacità" and do not invent numeric results.
- If the input defines a function (for example f(x)=...), start "solution" with a compact graph-style summary in Italian: Cartesian axes behavior, intercepts, and curve trend.
- Keep "problem" as the exact transcription of the input text.
- Set "detected_language" to one of: en, it, fr, es, uz, unknown.
- Set "should_save_to_history" to true.
- Each item in "steps" MUST use this exact format: "LATEX_STEP || DETAILED_EXPLANATION".
- In each step:
  - The part before "||" MUST contain only mathematical content in LaTeX (no prose words, no plain-language commentary).
  - The LaTeX part MUST be wrapped in double dollars and start with \displaystyle, for example: $$\displaystyle \frac{1}{2}x=3$$
  - Every mathematical expression must be pure LaTeX display style only; no orphan symbols, no broken fragments, no loose commas/numbers.
  - Use professional LaTeX only. Never use linear notation like a/b or integral(f(x)); use \frac{a}{b}, \int, \sin^n(x), greek symbols, etc.
  - In step LaTeX, never use "/" for fractions; always use \frac{...}{...}.
  - If matrices/determinants are used, render with proper environments such as \begin{cases}...\end{cases} and \begin{vmatrix}...\end{vmatrix}.
  - Keep the full equation or transformation centered-ready and complete.
  - If the expression is long, structure LaTeX using multiline formatting (for example \begin{aligned} line_1 \\ line_2 \end{aligned}).
- The part after "||" MUST be a complete, detailed explanation in Italian.
- The explanation language must be fully Italian; do not mix English words.
  - Inside the explanation, write only literal logical reasoning in prose.
  - Do not place equations or LaTeX formulas inside the explanation text.
  - Explanations must clearly state what transformation/property/rule is used and why it is valid.
  - Explanation quality: at least 2 complete sentences per step, not short phrases.
  - Structure explanations into short paragraphs (2-3 lines each) separated by a blank line ("\n\n") inside the same step string.
  - For each step explanation, explicitly include these three labels in this exact order: **Titolo Step**, **Logica**, **Proprietà**.

IMPORTANT: Respond ONLY with valid JSON in this exact format (no markdown, no code blocks):
{
  "problem": "exact text of the problem",
  "solution": "final answer",
  "steps": ["$$\\displaystyle <latex step 1>$$ || <detailed explanation 1>", "$$\\displaystyle <latex step 2>$$ || <detailed explanation 2>"],
  "raw_latex": "the problem and solution in LaTeX format",
  "difficulty_level": "elementary|middle_school|high_school|college",
  "detected_language": "en|it|fr|es|uz|unknown",
  "should_save_to_history": true
}

Here is the math problem to solve:
`

func (s *Service) SolveMathProblemFromText(problemText string) (*MathSolution, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("Claude API key not configured")
	}

	reqBody := ClaudeRequest{
		Model:     claudeModel,
		MaxTokens: 1536,
		Messages: []Message{
			{
				Role: "user",
				Content: []ContentBlock{
					{
						Type: "text",
						Text: solveMathFromTextPrompt + problemText,
					},
				},
			},
		},
	}

	responseText, err := s.runJSONRequest(reqBody)
	if err != nil {
		return nil, fmt.Errorf("Claude API call failed: %w", err)
	}

	solution, err := parseSolutionFromText(responseText)
	if err != nil {
		return nil, fmt.Errorf("failed to parse solution: %w", err)
	}

	normalizeSolutionPayload(solution)

	return solution, nil
}

func (s *Service) TranslateMathSolution(solution *MathSolution, targetLanguage string) (*MathSolution, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("Claude API key not configured")
	}

	normalizedTarget := normalizeSupportedLanguage(targetLanguage)
	if normalizedTarget == "unknown" {
		return nil, fmt.Errorf("unsupported target language: %s", targetLanguage)
	}

	payload, err := json.Marshal(solution)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal translation payload: %w", err)
	}

	reqBody := ClaudeRequest{
		Model:     claudeModel,
		MaxTokens: 2048,
		Messages: []Message{
			{
				Role: "user",
				Content: []ContentBlock{
					{
						Type: "text",
						Text: fmt.Sprintf(
							translateMathPromptTemplate,
							languageNameForPrompt(normalizedTarget),
							string(payload),
						),
					},
				},
			},
		},
	}

	responseText, err := s.runJSONRequest(reqBody)
	if err != nil {
		return nil, err
	}

	translated, err := parseSolutionFromText(responseText)
	if err != nil {
		return nil, fmt.Errorf("failed to parse translated solution: %w", err)
	}

	normalizeSolutionPayload(translated)
	if strings.TrimSpace(translated.DifficultyLevel) == "" || translated.DifficultyLevel == "unknown" {
		translated.DifficultyLevel = strings.TrimSpace(solution.DifficultyLevel)
	}
	if strings.TrimSpace(translated.RawLatex) == "" {
		translated.RawLatex = strings.TrimSpace(solution.RawLatex)
	}
	translated.DetectedLanguage = normalizeSupportedLanguage(solution.DetectedLanguage)
	if solution.ShouldSaveToHistory != nil {
		translated.ShouldSaveToHistory = boolPtr(*solution.ShouldSaveToHistory)
	} else if translated.ShouldSaveToHistory == nil {
		translated.ShouldSaveToHistory = boolPtr(defaultShouldSaveToHistory(translated))
	}

	return translated, nil
}

func (s *Service) runJSONRequest(reqBody ClaudeRequest) (string, error) {
	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), claudeRequestTimeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "POST", claudeAPIURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", s.apiKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	resp, err := s.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to call Claude API: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Claude API error (status %d): %s", resp.StatusCode, compactErrorSnippet(string(body), 360))
	}

	var claudeResp ClaudeResponse
	if err := json.Unmarshal(body, &claudeResp); err != nil {
		return "", fmt.Errorf("failed to parse response: %w", err)
	}

	if claudeResp.Error != nil {
		return "", fmt.Errorf("Claude API error: %s", claudeResp.Error.Message)
	}

	if len(claudeResp.Content) == 0 {
		return "", fmt.Errorf("no content in Claude response")
	}

	return strings.TrimSpace(claudeResp.Content[0].Text), nil
}

func sanitizeImageBase64(raw string) (string, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return "", fmt.Errorf("empty image payload")
	}

	if strings.HasPrefix(value, "data:") {
		if comma := strings.Index(value, ","); comma >= 0 && comma+1 < len(value) {
			value = value[comma+1:]
		}
	}

	value = strings.ReplaceAll(value, "\n", "")
	value = strings.ReplaceAll(value, "\r", "")
	value = strings.TrimSpace(value)

	if len(value) < minImageBase64Chars {
		return "", fmt.Errorf("image payload too short")
	}
	if len(value) > maxImageBase64Chars {
		return "", fmt.Errorf("image payload too large")
	}

	normalized := strings.NewReplacer("-", "+", "_", "/").Replace(value)
	if rem := len(normalized) % 4; rem != 0 {
		normalized += strings.Repeat("=", 4-rem)
	}

	if _, err := base64.StdEncoding.DecodeString(normalized); err != nil {
		return "", fmt.Errorf("invalid base64 image payload: %w", err)
	}

	return normalized, nil
}

func normalizeSolutionPayload(solution *MathSolution) {
	if solution == nil {
		return
	}

	solution.Problem = clampString(strings.TrimSpace(solution.Problem), maxResponseProblemChars)
	solution.Solution = clampString(strings.TrimSpace(solution.Solution), maxResponseSolutionChars)
	solution.RawLatex = clampString(strings.TrimSpace(solution.RawLatex), maxResponseRawLatexChars)
	solution.DifficultyLevel = strings.TrimSpace(solution.DifficultyLevel)

	if solution.Steps == nil {
		solution.Steps = []string{}
	}
	trimmedSteps := make([]string, 0, len(solution.Steps))
	for _, step := range solution.Steps {
		s := clampString(strings.TrimSpace(step), maxResponseStepChars)
		s = normalizeStepEntry(s)
		if s == "" {
			continue
		}
		trimmedSteps = append(trimmedSteps, s)
		if len(trimmedSteps) >= maxResponseSteps {
			break
		}
	}
	solution.Steps = trimmedSteps

	if solution.Solution == "" {
		solution.Solution = "I could not read the math expression clearly. Please retake the photo."
	}
	if solution.Problem == "" {
		solution.Problem = "Problem text could not be read clearly from image."
	}
	if solution.DifficultyLevel == "" {
		solution.DifficultyLevel = "unknown"
	}

	solution.DetectedLanguage = normalizeSupportedLanguage(solution.DetectedLanguage)
	if solution.ShouldSaveToHistory == nil {
		solution.ShouldSaveToHistory = boolPtr(defaultShouldSaveToHistory(solution))
	}
	if !defaultShouldSaveToHistory(solution) {
		solution.ShouldSaveToHistory = boolPtr(false)
	}
}

func normalizeStepEntry(raw string) string {
	step := strings.TrimSpace(raw)
	if step == "" {
		return ""
	}

	parts := strings.SplitN(step, "||", 2)
	formula := normalizeStepFormula(parts[0])
	if len(parts) == 1 {
		return formula
	}

	explanation := normalizeStepExplanation(parts[1])
	if explanation == "" {
		return formula
	}
	return formula + " || " + explanation
}

func normalizeStepFormula(raw string) string {
	formula := stripMathDelimiters(raw)
	formula = strings.TrimSpace(formula)
	formula = strings.ReplaceAll(formula, "π", "\\pi")
	formula = strings.ReplaceAll(formula, "−", "-")
	formula = strings.ReplaceAll(formula, "×", "\\times")
	formula = strings.ReplaceAll(formula, "÷", "\\div")
	formula = strings.ReplaceAll(formula, "...", "")
	formula = strings.ReplaceAll(formula, "$", "")

	// Remove common prose tokens that should never appear inside step boxes.
	reBadWords := regexp.MustCompile(`(?i)\b(therefore|thus|substituting|substitute|equivalent|transformation|apply|property|sostituzione|semplificazione|propriet[àa]|risultato|passaggio)\b`)
	formula = reBadWords.ReplaceAllString(formula, " ")
	reCamelOrOps := regexp.MustCompile(`(?i)\b(usegaussianelimination|backsubstitute|back-substitute|applyrowoperations|rowoperations|gaussianelimination)\b`)
	formula = reCamelOrOps.ReplaceAllString(formula, " ")
	formula = stripNonMathWords(formula)

	// Convert linear fractions/powers to proper LaTeX.
	reFrac := regexp.MustCompile(`(?i)(\\pi|[A-Za-z0-9]+)\s*/\s*(\\pi|[A-Za-z0-9]+)`)
	for i := 0; i < 3; i++ {
		updated := reFrac.ReplaceAllString(formula, `\\frac{$1}{$2}`)
		if updated == formula {
			break
		}
		formula = updated
	}

	rePowNum := regexp.MustCompile(`\b([A-Za-z])\s*\^\s*([0-9]+)\b`)
	formula = rePowNum.ReplaceAllString(formula, `$1^{$2}`)

	rePowVar := regexp.MustCompile(`\b([A-Za-z])\s*\^\s*([A-Za-z]+)\b`)
	formula = rePowVar.ReplaceAllString(formula, `$1^{$2}`)

	reMultiSpace := regexp.MustCompile(`\s+`)
	formula = strings.TrimSpace(reMultiSpace.ReplaceAllString(formula, " "))

	if formula == "" {
		formula = `0=0`
	}

	if !strings.Contains(formula, `\displaystyle`) {
		formula = `\displaystyle \large ` + formula
	} else if !strings.Contains(formula, `\large`) {
		formula = strings.Replace(formula, `\displaystyle`, `\displaystyle \large`, 1)
	}

	return `$$` + strings.TrimSpace(formula) + `$$`
}

func normalizeStepExplanation(raw string) string {
	explanation := strings.TrimSpace(raw)
	if explanation == "" {
		return ""
	}

	explanation = strings.ReplaceAll(explanation, "...", ".")

	// Replace frequent English fragments with Italian.
	replacer := strings.NewReplacer(
		"Therefore", "Quindi",
		"therefore", "quindi",
		"Then", "Quindi",
		"then", "quindi",
		"Substituting", "Sostituendo",
		"substituting", "sostituendo",
		"Using", "Usando",
		"using", "usando",
		"Apply", "Applichiamo",
		"apply", "applichiamo",
		"We can", "Possiamo",
		"we can", "possiamo",
		"Simplification", "Semplificazione",
		"simplification", "semplificazione",
		"Property", "Proprietà",
		"property", "proprietà",
		"Result", "Risultato",
		"result", "risultato",
		"Equivalent transformation", "Trasformazione equivalente",
		"equivalent transformation", "trasformazione equivalente",
		"Gaussian elimination", "eliminazione di Gauss",
		"gaussian elimination", "eliminazione di Gauss",
		"back-substitute", "sostituzione all'indietro",
		"back substitute", "sostituzione all'indietro",
		"Apply row operations", "Applichiamo operazioni elementari di riga",
		"apply row operations", "applichiamo operazioni elementari di riga",
		"Ratio", "Logica",
		"ratio", "logica",
		"Action", "Azione",
		"action", "azione",
	)
	explanation = replacer.Replace(explanation)

	// Keep explanation as literal prose only: strip formulas and symbolic math snippets.
	reDisplayMathDollar := regexp.MustCompile(`(?s)\$\$.*?\$\$`)
	explanation = reDisplayMathDollar.ReplaceAllString(explanation, "espressione matematica")
	reInlineMathDollar := regexp.MustCompile(`(?s)\$[^$]+\$`)
	explanation = reInlineMathDollar.ReplaceAllString(explanation, "espressione matematica")
	reDisplayMathBrackets := regexp.MustCompile(`(?s)\\\[.*?\\\]`)
	explanation = reDisplayMathBrackets.ReplaceAllString(explanation, "espressione matematica")
	reInlineMathBrackets := regexp.MustCompile(`(?s)\\\(.*?\\\)`)
	explanation = reInlineMathBrackets.ReplaceAllString(explanation, "espressione matematica")

	reLatexCommands := regexp.MustCompile(`\\[A-Za-z]+(\{[^{}]*\})*`)
	explanation = reLatexCommands.ReplaceAllString(explanation, "espressione matematica")
	explanation = strings.NewReplacer("{", " ", "}", " ").Replace(explanation)
	reSymbolicNoise := regexp.MustCompile(`[=+\-*/^_{}[\]<>|]+`)
	explanation = reSymbolicNoise.ReplaceAllString(explanation, " ")
	reCamelOrOps := regexp.MustCompile(`(?i)\b(usegaussianelimination|backsubstitute|back-substitute|applyrowoperations|rowoperations|gaussianelimination)\b`)
	explanation = reCamelOrOps.ReplaceAllString(explanation, " ")

	// Remove accidental list prefixes to keep compact prose structure.
	reListPrefix := regexp.MustCompile(`(?m)^\s*[-*]\s+`)
	explanation = reListPrefix.ReplaceAllString(explanation, "")

	// Ensure explicit logical structure: Titolo Step / Logica / Proprietà.
	lower := strings.ToLower(explanation)
	if !strings.Contains(lower, "**titolo step") || !strings.Contains(lower, "**logica") || !strings.Contains(lower, "**propriet") {
		explanation = strings.TrimSpace(explanation)
		explanation = "**Titolo Step:** passaggio di trasformazione equivalente\n\n" +
			"**Logica:** " + explanation + "\n\n" +
			"**Proprietà:** applichiamo regole algebriche equivalenti (sostituzione, semplificazione o proprietà dei determinanti, quando richiesto)."
	}

	// Ensure each paragraph has bold operation label and no residual English filler.
	paragraphs := strings.Split(explanation, "\n\n")
	reEnglishResidual := regexp.MustCompile(`(?i)\b(the|and|or|we|can|using|use|apply|property|result|substituting|therefore|method|calculate|compute|gaussian|elimination|back|substitute|row|operations?)\b`)
	reDigitsOnly := regexp.MustCompile(`^\s*\d+\s*$`)
	rePunctOnly := regexp.MustCompile(`^[\s\p{P}]+$`)
	for i := range paragraphs {
		p := strings.TrimSpace(paragraphs[i])
		if p == "" {
			continue
		}
		p = reEnglishResidual.ReplaceAllString(p, "")
		p = strings.TrimSpace(p)
		if !strings.Contains(p, "**") {
			paragraphs[i] = "**Semplificazione.** " + p
		} else {
			paragraphs[i] = p
		}
		if reDigitsOnly.MatchString(paragraphs[i]) || rePunctOnly.MatchString(paragraphs[i]) {
			paragraphs[i] = ""
		}
	}
	explanation = strings.TrimSpace(strings.Join(paragraphs, "\n\n"))
	reSpaces := regexp.MustCompile(`[ \t]{2,}`)
	explanation = reSpaces.ReplaceAllString(explanation, " ")
	explanation = strings.TrimSpace(explanation)

	return explanation
}

func stripNonMathWords(input string) string {
	tokens := strings.Fields(input)
	if len(tokens) == 0 {
		return ""
	}
	reDigit := regexp.MustCompile(`\d`)
	reMathSymbol := regexp.MustCompile(`[=+\-*/^(){}\[\]|<>]`)
	reHyphenProse := regexp.MustCompile(`(?i)[a-z]{3,}-[a-z]{3,}`)
	reSingleLetter := regexp.MustCompile(`(?i)[a-z]`)

	isAllowedWord := func(word string) bool {
		allowed := map[string]struct{}{
			"x": {}, "y": {}, "z": {}, "t": {}, "u": {}, "v": {}, "w": {},
			"a": {}, "b": {}, "c": {}, "d": {}, "e": {}, "f": {}, "g": {}, "h": {},
			"m": {}, "n": {}, "p": {}, "q": {}, "r": {}, "s": {}, "k": {},
			"sin": {}, "cos": {}, "tan": {}, "cot": {}, "sec": {}, "csc": {},
			"log": {}, "ln": {}, "exp": {}, "det": {}, "pi": {},
			"alpha": {}, "beta": {}, "gamma": {}, "delta": {}, "theta": {}, "lambda": {}, "sigma": {}, "omega": {},
		}
		_, ok := allowed[word]
		return ok
	}

	var kept []string
	for _, token := range tokens {
		trimmed := strings.Trim(token, ".,;:!?")
		if trimmed == "" {
			continue
		}
		lower := strings.ToLower(trimmed)

		if strings.Contains(trimmed, `\`) {
			kept = append(kept, token)
			continue
		}
		if reDigit.MatchString(trimmed) {
			kept = append(kept, token)
			continue
		}
		if reMathSymbol.MatchString(trimmed) {
			// Drop long hyphenated prose tokens like "back-substitute".
			if strings.Contains(trimmed, "-") && reHyphenProse.MatchString(trimmed) {
				continue
			}
			kept = append(kept, token)
			continue
		}
		if len(trimmed) == 1 && reSingleLetter.MatchString(trimmed) {
			kept = append(kept, token)
			continue
		}
		if isAllowedWord(lower) {
			kept = append(kept, token)
			continue
		}
	}

	return strings.Join(kept, " ")
}

func stripMathDelimiters(raw string) string {
	value := strings.TrimSpace(raw)
	if value == "" {
		return ""
	}

	if strings.HasPrefix(value, "$$") && strings.HasSuffix(value, "$$") && len(value) >= 4 {
		value = strings.TrimSpace(strings.TrimSuffix(strings.TrimPrefix(value, "$$"), "$$"))
	}
	if strings.HasPrefix(value, `\[`) && strings.HasSuffix(value, `\]`) && len(value) >= 4 {
		value = strings.TrimSpace(strings.TrimSuffix(strings.TrimPrefix(value, `\[`), `\]`))
	}
	if strings.HasPrefix(value, `\(`) && strings.HasSuffix(value, `\)`) && len(value) >= 4 {
		value = strings.TrimSpace(strings.TrimSuffix(strings.TrimPrefix(value, `\(`), `\)`))
	}
	if strings.HasPrefix(value, "$") && strings.HasSuffix(value, "$") && len(value) >= 2 {
		value = strings.TrimSpace(strings.TrimSuffix(strings.TrimPrefix(value, "$"), "$"))
	}
	return value
}

func unreadableRetakeSolution() *MathSolution {
	return &MathSolution{
		Problem:             "Il testo del problema non è stato letto chiaramente dall'immagine.",
		Solution:            "Non riesco a leggere chiaramente l'espressione matematica. Scatta di nuovo la foto.",
		Steps:               []string{},
		RawLatex:            "",
		DifficultyLevel:     "unknown",
		DetectedLanguage:    "unknown",
		ShouldSaveToHistory: boolPtr(false),
	}
}

func clampString(value string, maxLen int) string {
	if maxLen <= 0 {
		return ""
	}
	if len(value) <= maxLen {
		return value
	}
	return strings.TrimSpace(value[:maxLen])
}

func compactErrorSnippet(value string, maxLen int) string {
	if maxLen <= 0 {
		return ""
	}
	snippet := strings.Join(strings.Fields(value), " ")
	if len(snippet) <= maxLen {
		return snippet
	}
	return snippet[:maxLen]
}

func normalizeSupportedLanguage(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "en", "english":
		return "en"
	case "it", "italian", "italiano":
		return "it"
	case "fr", "french", "francais", "français":
		return "fr"
	case "es", "spanish", "espanol", "español":
		return "es"
	case "uz", "uzbek", "o'zbek", "ozbek":
		return "uz"
	default:
		return "unknown"
	}
}

func languageNameForPrompt(code string) string {
	switch code {
	case "it":
		return "Italian"
	case "fr":
		return "French"
	case "es":
		return "Spanish"
	case "uz":
		return "Uzbek"
	default:
		return "English"
	}
}

func boolPtr(value bool) *bool {
	return &value
}

func defaultShouldSaveToHistory(solution *MathSolution) bool {
	combined := strings.ToLower(strings.TrimSpace(
		solution.Problem + " " + solution.Solution + " " + strings.Join(solution.Steps, " "),
	))
	if combined == "" {
		return false
	}

	blockedPhrases := []string{
		"unable to parse problem from image",
		"could not parse model response",
		"could not parse structured response",
		"please retake the photo",
		"problem text could not be read clearly from image",
		"could not determine a final answer from the image",
		"image is unclear",
		"image is incomplete",
		"problem is unclear",
		"problem is incomplete",
		"unreadable",
		"errore di capacità",
		"scatta di nuovo la foto",
		"non riesco a leggere chiaramente",
		"non è stato letto chiaramente",
	}
	for _, phrase := range blockedPhrases {
		if strings.Contains(combined, phrase) {
			return false
		}
	}

	return true
}
