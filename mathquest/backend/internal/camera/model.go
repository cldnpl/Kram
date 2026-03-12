package camera

import (
	"encoding/json"
	"time"
)

type CameraSolution struct {
	ID              uint            `gorm:"primaryKey" json:"id"`
	UserID          uint            `json:"user_id"`
	OriginalProblem string          `json:"original_problem"`
	Solution        string          `json:"solution"`
	StepsJSON       json.RawMessage `gorm:"type:jsonb" json:"steps_json"`
	RawLatex        string          `json:"raw_latex"`
	DifficultyLevel string          `json:"difficulty_level"`
	ShareToken      string          `gorm:"size:64;uniqueIndex" json:"-"`
	SharedAt        *time.Time      `json:"-"`
	CreatedAt       time.Time       `json:"created_at"`
}

func (CameraSolution) TableName() string {
	return "camera_solutions"
}

type SolveRequest struct {
	ImageBase64 string `json:"image_base64"`
	MediaType   string `json:"media_type"`
}

type SolveResponse struct {
	ID                  uint                   `json:"id"`
	Problem             string                 `json:"problem"`
	Solution            string                 `json:"solution"`
	Steps               []string               `json:"steps"`
	RawLatex            string                 `json:"raw_latex"`
	Graph               *FunctionGraphResponse `json:"graph,omitempty"`
	DifficultyLevel     string                 `json:"difficulty_level"`
	DetectedLanguage    string                 `json:"detected_language"`
	ShouldSaveToHistory bool                   `json:"should_save_to_history"`
	UsesRemainingToday  int                    `json:"uses_remaining_today"`
}

type TranslateRequest struct {
	Problem             string                 `json:"problem"`
	Solution            string                 `json:"solution"`
	Steps               []string               `json:"steps"`
	RawLatex            string                 `json:"raw_latex"`
	Graph               *FunctionGraphResponse `json:"graph,omitempty"`
	DifficultyLevel     string                 `json:"difficulty_level"`
	DetectedLanguage    string                 `json:"detected_language"`
	ShouldSaveToHistory bool                   `json:"should_save_to_history"`
	TargetLanguage      string                 `json:"target_language"`
}

type TranslateResponse struct {
	Problem             string                 `json:"problem"`
	Solution            string                 `json:"solution"`
	Steps               []string               `json:"steps"`
	RawLatex            string                 `json:"raw_latex"`
	Graph               *FunctionGraphResponse `json:"graph,omitempty"`
	DifficultyLevel     string                 `json:"difficulty_level"`
	DetectedLanguage    string                 `json:"detected_language"`
	ShouldSaveToHistory bool                   `json:"should_save_to_history"`
}

type FunctionGraphResponse struct {
	Expression string  `json:"expression"`
	XMin       float64 `json:"x_min"`
	XMax       float64 `json:"x_max"`
	YMin       float64 `json:"y_min"`
	YMax       float64 `json:"y_max"`
}

type HistoryItem struct {
	ID              uint      `json:"id"`
	Problem         string    `json:"problem"`
	Solution        string    `json:"solution"`
	DifficultyLevel string    `json:"difficulty_level"`
	CreatedAt       time.Time `json:"created_at"`
}

type HistoryDetailResponse struct {
	ID              uint      `json:"id"`
	Problem         string    `json:"problem"`
	Solution        string    `json:"solution"`
	Steps           []string  `json:"steps"`
	RawLatex        string    `json:"raw_latex"`
	DifficultyLevel string    `json:"difficulty_level"`
	CreatedAt       time.Time `json:"created_at"`
}

type StatusResponse struct {
	DailyLimit int `json:"daily_limit"`
	UsedToday  int `json:"used_today"`
	Remaining  int `json:"remaining"`
}

type ShareHistoryResponse struct {
	Token string `json:"token"`
	ID    uint   `json:"id,omitempty"`
}

type ShareCreateRequest struct {
	Problem         string   `json:"problem"`
	Solution        string   `json:"solution"`
	Steps           []string `json:"steps"`
	RawLatex        string   `json:"raw_latex"`
	DifficultyLevel string   `json:"difficulty_level"`
}

type SharedSolutionResponse struct {
	Token           string    `json:"token"`
	Problem         string    `json:"problem"`
	Solution        string    `json:"solution"`
	Steps           []string  `json:"steps"`
	RawLatex        string    `json:"raw_latex"`
	DifficultyLevel string    `json:"difficulty_level"`
	CreatedAt       time.Time `json:"created_at"`
}
