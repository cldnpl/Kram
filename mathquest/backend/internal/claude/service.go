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

type GraphData struct {
	IsFunction  bool              `json:"is_function"`
	Expression  string            `json:"expression"`
	Variable    string            `json:"variable"`
	Domain      string            `json:"domain"`
	Range       string            `json:"range"`
	Intercepts  map[string][]string `json:"intercepts"`
	Asymptotes  map[string][]string `json:"asymptotes"`
	CriticalPoints []CriticalPoint `json:"critical_points"`
	Behavior    map[string]string `json:"behavior"`
}

type CriticalPoint struct {
	X    string `json:"x"`
	Y    string `json:"y"`
	Type string `json:"type"` // "maximum", "minimum", "inflection", "discontinuity"
}

type MathSolution struct {
	Problem             string     `json:"problem"`
	Solution            string     `json:"solution"`
	Steps               []string   `json:"steps"`
	StepsDetail         []string   `json:"steps_detail,omitempty"`
	RawLatex            string     `json:"raw_latex"`
	DifficultyLevel     string     `json:"difficulty_level"`
	DetectedLanguage    string     `json:"detected_language"`
	ShouldSaveToHistory *bool      `json:"should_save_to_history,omitempty"`
	GraphData           *GraphData `json:"graph_data,omitempty"`
}

const solveMathPromptTemplate = `You are a rigorous math tutor. You solve ANY type of math problem (Algebra, Analysis, Geometry, Trigonometry, Calculus, Physics, Linear Algebra, etc.) with absolute precision.

Analyze the math problem in this image and provide a complete solution.
Read the problem exactly as written in the image before solving.

═══════════════════════════════════════════════════════════════════════
PROTOCOLLO DI SISTEMA PERMANENTE E UNIVERSALE — NESSUNA ECCEZIONE
═══════════════════════════════════════════════════════════════════════

Queste regole si applicano a QUALSIASI input, senza eccezioni.
Questa è la UNICA modalità di risposta permanente.

══════════════════════════════════════════════════════════════
§1. LINGUA DI SISTEMA (MANDATORIA)
══════════════════════════════════════════════════════════════
- La lingua dell'utente è: %s.
- Ogni singola parola generata (titoli, step, spiegazioni, commenti, "solution") DEVE essere ESCLUSIVAMENTE in %s.
- È PROIBITO l'uso dell'inglese o di termini tecnici non tradotti (es. "defined" → vietato).
- "problem": mantieni la trascrizione esatta dall'immagine (lingua originale).
- "solution" e tutto il resto: DEVE essere interamente in %s.

══════════════════════════════════════════════════════════════
§2. PROTOCOLLO OCR-TRIGGER — ATTIVAZIONE GRAFICA AUTOMATICA
══════════════════════════════════════════════════════════════
Quando l'OCR rileva una FUNZIONE (y=..., f(x)=..., o qualsiasi curva), si attiva
AUTOMATICAMENTE questa sequenza obbligatoria:

A) TRIGGER GRAFICO IMMEDIATO:
   - "graph_data" DEVE essere incluso. È un ERRORE CRITICO DI SISTEMA non includerlo.
   - Il grafico è la PRIMA cosa visibile dopo la scansione.
   - Resa visiva: sfondo BIANCO, assi NERI, curva VIOLA.
   - "expression": JavaScript-evaluable (es. "1/x", "Math.sin(x)", "x*x - 4").
   - "domain"/"range": notazione matematica (es. "(-∞, 0) ∪ (0, +∞)").
   - "intercepts": {"x": [...], "y": [...]}.
   - "asymptotes": {"vertical": [...], "horizontal": [...], "oblique": []}.
   - "critical_points": [{"x": "v", "y": "v", "type": "minimum|maximum|inflection|discontinuity"}].
   - "behavior": descrizione comportamento agli estremi.

B) FILTRO STEP — MINIMALISMO (SOLO PER FUNZIONI):
   - Negli step VISIBILI ("steps" array), calcola SOLO IL DOMINIO.
   - NON mostrare derivate, integrali, intersezioni, studio del segno o altro nei riquadri step.
   - L'array "steps" deve avere UN SOLO ELEMENTO: la formula del dominio.
   - Formato: "$\\small\\displaystyle <formula dominio pura>$"
   - ZERO parole: NO "Dominio:", NO "D:", NO "defined". Solo il calcolo matematico.
   - Per funzioni con più condizioni (radicandi, denominatori), usa il sistema:
     "$\\small\\displaystyle \\begin{cases} x^2-1 \\geq 0 \\\\ x-2 \\neq 0 \\end{cases} \\implies D=(-\\infty,-1]\\cup[1,2)\\cup(2,+\\infty)$"
   - Esempio SBAGLIATO: "Dominio: $\\displaystyle x \\neq 0$" ← CONTIENE PAROLE, VIETATO.

C) EXPAND — ANALISI COMPLETA (SOLO PER FUNZIONI):
   - L'array "steps_detail" (1 elemento, corrispondente allo step del dominio) contiene
     l'INTERA analisi completa della funzione, interamente in %s:
   - DEVE includere (separati da intestazioni **bold**):
     • **Dominio**: calcolo dettagliato con ogni condizione
     • **Intersezioni con gli assi**: calcoli x=0 e y=0
     • **Segno della funzione**: studio del segno completo
     • **Limiti e asintoti**: tutti i limiti agli estremi del dominio, classificazione asintoti
     • **Derivata prima**: calcolo, studio del segno, crescenza/decrescenza
     • **Punti critici**: massimi, minimi, flessi
     • **Derivata seconda** (se rilevante): concavità
   - Tutte le formule in $\\displaystyle ...$ LaTeX.
   - Ogni proprietà e teorema citato esplicitamente.
   - TUTTI i calcoli intermedi mostrati, nessun passaggio saltato.

══════════════════════════════════════════════════════════════
§3. PROBLEMI NON-FUNZIONE (equazioni, aritmetica, geometria, ecc.)
══════════════════════════════════════════════════════════════
- "graph_data": null.
- "steps": multipli step, ciascuno contenente SOLO formula LaTeX pura.
  Formato: "$\\small\\displaystyle <formula>$". ZERO PAROLE.
- "steps_detail": stessa lunghezza di "steps", ogni voce è la spiegazione
  completa e dettagliata di quel passaggio in %s, con ogni proprietà citata.

══════════════════════════════════════════════════════════════
§4. REGOLE LATEX
══════════════════════════════════════════════════════════════
- TUTTE le formule usano \\displaystyle. "steps" usa anche \\small.
- Formule compatte e pulite, come in un libro di testo universitario.
- ZERO errori di rendering: nessun carattere orfano, nessuna lettera isolata.
- Nessuna soluzione approssimata o allucinata.

══════════════════════════════════════════════════════════════
§5. REGOLE GENERALI
══════════════════════════════════════════════════════════════
- Non inventare numeri, simboli o parole mancanti.
- Se l'immagine è poco chiara: "should_save_to_history" = false.
- "problem": trascrizione esatta dall'immagine.
- "detected_language": lingua dell'IMMAGINE (en|it|fr|es|uz|unknown).
- "difficulty_level": imposta accuratamente.

IMPORTANT: Respond ONLY with valid JSON (no markdown, no code blocks):
{
  "problem": "trascrizione esatta dall'immagine",
  "solution": "risposta finale in %s",
  "steps": ["$\\small\\displaystyle <formula pura>$"],
  "steps_detail": ["Analisi completa in %s..."],
  "raw_latex": "soluzione completa in \\displaystyle LaTeX",
  "difficulty_level": "elementary|middle_school|high_school|college",
  "detected_language": "en|it|fr|es|uz|unknown",
  "should_save_to_history": true,
  "graph_data": null
}
`

const translateMathPromptTemplate = `You are translating a solved math explanation for a student.

Translate the provided JSON into %s.

Rules you MUST follow:
- Translate the human-readable prose in "problem", "solution", every string in "steps", and every string in "steps_detail".
- ALL text (labels, explanations, comments) must be ENTIRELY in %s. No mixed languages.
- Keep numbers, equations, symbols, LaTeX formulas, and mathematical meaning unchanged.
- Keep "raw_latex" unchanged.
- Keep "difficulty_level" unchanged.
- Keep "detected_language" unchanged.
- Keep "should_save_to_history" unchanged.
- Return the same number of steps and steps_detail.
- In "steps_detail", translate all bold paragraph headers and explanations while preserving LaTeX formulas.

IMPORTANT: Respond ONLY with valid JSON in this exact format (no markdown, no code blocks):
{
  "problem": "translated problem text",
  "solution": "translated final answer",
  "steps": ["translated step 1", "translated step 2", ...],
  "steps_detail": ["translated detail 1", "translated detail 2", ...],
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

func (s *Service) SolveMathProblem(imageBase64, mediaType, preferredLanguage string) (*MathSolution, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("Claude API key not configured")
	}

	langName := languageNameForPrompt(normalizeSupportedLanguage(preferredLanguage))
	if langName == "" {
		langName = "English"
	}
	prompt := fmt.Sprintf(solveMathPromptTemplate, langName, langName, langName, langName, langName, langName, langName)

	reqBody := ClaudeRequest{
		Model:     claudeModel,
		MaxTokens: 4096,
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
						Text: prompt,
					},
				},
			},
		},
	}

	responseText, err := s.runJSONRequest(reqBody)
	if err != nil {
		return nil, err
	}
	solution, err := parseSolutionFromText(responseText)
	if err != nil {
		// If parsing fails, try to extract info manually
		return &MathSolution{
			Problem:             "Unable to parse problem from image",
			Solution:            "Could not parse model response as structured solution. Please retake the photo.",
			Steps:               []string{"Could not parse structured response.", responseText},
			RawLatex:            "",
			DifficultyLevel:     "unknown",
			DetectedLanguage:    "unknown",
			ShouldSaveToHistory: boolPtr(false),
		}, nil
	}

	if solution.Steps == nil {
		solution.Steps = []string{}
	}
	if solution.StepsDetail == nil {
		solution.StepsDetail = []string{}
	}
	// Ensure steps_detail has same length as steps
	for len(solution.StepsDetail) < len(solution.Steps) {
		solution.StepsDetail = append(solution.StepsDetail, "")
	}
	if len(solution.StepsDetail) > len(solution.Steps) {
		solution.StepsDetail = solution.StepsDetail[:len(solution.Steps)]
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
	solution.DetectedLanguage = normalizeSupportedLanguage(solution.DetectedLanguage)
	if solution.ShouldSaveToHistory == nil {
		solution.ShouldSaveToHistory = boolPtr(defaultShouldSaveToHistory(solution))
	}

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
		MaxTokens: 4096,
		Messages: []Message{
			{
				Role: "user",
				Content: []ContentBlock{
					{
						Type: "text",
						Text: fmt.Sprintf(
							translateMathPromptTemplate,
							languageNameForPrompt(normalizedTarget),
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

	if translated.Steps == nil {
		translated.Steps = []string{}
	}
	if translated.StepsDetail == nil {
		translated.StepsDetail = []string{}
	}
	for len(translated.StepsDetail) < len(translated.Steps) {
		translated.StepsDetail = append(translated.StepsDetail, "")
	}
	if len(translated.StepsDetail) > len(translated.Steps) {
		translated.StepsDetail = translated.StepsDetail[:len(translated.Steps)]
	}
	if strings.TrimSpace(translated.DifficultyLevel) == "" {
		translated.DifficultyLevel = solution.DifficultyLevel
	}
	if strings.TrimSpace(translated.RawLatex) == "" {
		translated.RawLatex = solution.RawLatex
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

	req, err := http.NewRequest("POST", claudeAPIURL, bytes.NewBuffer(jsonData))
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
		return "", fmt.Errorf("Claude API error (status %d): %s", resp.StatusCode, string(body))
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
	}
	for _, phrase := range blockedPhrases {
		if strings.Contains(combined, phrase) {
			return false
		}
	}

	return true
}
