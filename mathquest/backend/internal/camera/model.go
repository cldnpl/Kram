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
	ID                  uint     `json:"id"`
	Problem             string   `json:"problem"`
	Solution            string   `json:"solution"`
	Steps               []string `json:"steps"`
	RawLatex            string   `json:"raw_latex"`
	DifficultyLevel     string   `json:"difficulty_level"`
	UsesRemainingToday  int      `json:"uses_remaining_today"`
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
