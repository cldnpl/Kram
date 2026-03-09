package lesson

import (
	"embed"
	"encoding/json"
	"fmt"
	"io/fs"
	"sort"
	"strings"
	"sync"
)

//go:embed data/*.json
var lessonJSONFS embed.FS

type lessonJSONExercise struct {
	ID            string   `json:"id"`
	Question      string   `json:"question"`
	Type          string   `json:"type"`
	Options       []string `json:"options"`
	CorrectAnswer string   `json:"correct_answer"`
	XPReward      int      `json:"xp_reward"`
}

type lessonJSONItem struct {
	ID        string               `json:"id"`
	Title     string               `json:"title"`
	Category  string               `json:"category"`
	Intro     string               `json:"intro"`
	Exercises []lessonJSONExercise `json:"exercises"`
}

type lessonJSONBundle struct {
	Language string           `json:"language"`
	Lessons  []lessonJSONItem `json:"lessons"`
}

var (
	lessonJSONOnce sync.Once
	lessonJSONByID map[string]map[string]lessonJSONItem
	lessonJSONErr  error
)

func loadLessonJSON() {
	lessonJSONByID = make(map[string]map[string]lessonJSONItem)

	entries, err := fs.ReadDir(lessonJSONFS, "data")
	if err != nil {
		lessonJSONErr = fmt.Errorf("read lesson json dir: %w", err)
		return
	}

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".json") {
			continue
		}

		b, err := fs.ReadFile(lessonJSONFS, "data/"+entry.Name())
		if err != nil {
			lessonJSONErr = fmt.Errorf("read lesson json file %s: %w", entry.Name(), err)
			return
		}

		var bundle lessonJSONBundle
		if err := json.Unmarshal(b, &bundle); err != nil {
			lessonJSONErr = fmt.Errorf("parse lesson json file %s: %w", entry.Name(), err)
			return
		}

		lang := normalizeLessonLang(bundle.Language)
		if lang == "" {
			lang = strings.TrimSuffix(entry.Name(), ".json")
			lang = normalizeLessonLang(lang)
		}

		if lessonJSONByID[lang] == nil {
			lessonJSONByID[lang] = make(map[string]lessonJSONItem, len(bundle.Lessons))
		}

		for _, lesson := range bundle.Lessons {
			id := strings.TrimSpace(lesson.ID)
			if id == "" {
				continue
			}
			lesson.ID = id
			if strings.TrimSpace(lesson.Title) == "" {
				lesson.Title = "Lesson"
			}
			if strings.TrimSpace(lesson.Category) == "" {
				lesson.Category = "Math"
			}
			if strings.TrimSpace(lesson.Intro) == "" {
				lesson.Intro = "Content not available."
			}

			for i := range lesson.Exercises {
				if lesson.Exercises[i].ID == "" {
					lesson.Exercises[i].ID = fmt.Sprintf("%s-e%d", lesson.ID, i+1)
				}
				if lesson.Exercises[i].Type == "" {
					lesson.Exercises[i].Type = "multiple_choice"
				}
				if lesson.Exercises[i].XPReward <= 0 {
					lesson.Exercises[i].XPReward = 10
				}
			}

			lessonJSONByID[lang][lesson.ID] = lesson
		}
	}
}

func lessonFromJSON(id, lang string) (lessonJSONItem, bool) {
	lessonJSONOnce.Do(loadLessonJSON)
	if lessonJSONErr != nil {
		return lessonJSONItem{}, false
	}

	targetLang := normalizeLessonLang(lang)
	searchLangs := []string{targetLang}
	if targetLang != "en" {
		searchLangs = append(searchLangs, "en")
	}

	idsToTry := []string{id}
	if sectionID, _, ok := parseItemID(id); ok {
		idsToTry = append(idsToTry, sectionID)
	}

	for _, l := range searchLangs {
		byID := lessonJSONByID[l]
		if len(byID) == 0 {
			continue
		}
		for _, lessonID := range idsToTry {
			if lesson, ok := byID[lessonID]; ok {
				return lesson, true
			}
		}
	}

	return lessonJSONItem{}, false
}

func lessonJSONSummary() map[string]int {
	lessonJSONOnce.Do(loadLessonJSON)
	out := make(map[string]int)
	for lang, byID := range lessonJSONByID {
		out[lang] = len(byID)
	}
	return out
}

func lessonJSONLanguages() []string {
	lessonJSONOnce.Do(loadLessonJSON)
	langs := make([]string, 0, len(lessonJSONByID))
	for lang := range lessonJSONByID {
		langs = append(langs, lang)
	}
	sort.Strings(langs)
	return langs
}
