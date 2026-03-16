package lesson

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"testing"
)

func TestGenerateLessonJSONFiles(t *testing.T) {
	if os.Getenv("GENERATE_LESSON_JSON") != "1" {
		t.Skip("set GENERATE_LESSON_JSON=1 to generate lesson json files")
	}

	languages := []string{"en", "it", "fr", "es", "uz"}
	ids := sortedLessonIDs()
	if len(ids) == 0 {
		t.Fatal("no lessons found in lessonContentByID")
	}

	for _, lang := range languages {
		t.Logf("generating %s lessons json (%d entries)", lang, len(ids))
		lessons := make([]lessonJSONItem, 0, len(ids))

		for _, id := range ids {
			base, ok := lessonContentByID[id]
			if !ok {
				continue
			}

			title := base.Title
			category := base.Category
			intro := base.Intro

			if lang != "en" {
				tr := translationMap(lang)
				if v, ok := tr[title]; ok {
					title = v
				}
				if v, ok := tr[category]; ok {
					category = v
				}
				intro = localizeLessonIntro(id, base.Intro, lang)
			}

			intro = normalizeLessonIntro(intro)
			exercises := buildExercisesForLesson(id, title, category, intro, lang)
			lessons = append(lessons, lessonJSONItem{
				ID:        id,
				Title:     title,
				Category:  category,
				Intro:     intro,
				Exercises: exercises,
			})
		}

		bundle := lessonJSONBundle{
			Language: lang,
			Lessons:  lessons,
		}

		b, err := json.MarshalIndent(bundle, "", "  ")
		if err != nil {
			t.Fatalf("marshal %s json: %v", lang, err)
		}

		path := filepath.Join("data", lang+".json")
		if err := os.WriteFile(path, b, 0o644); err != nil {
			t.Fatalf("write %s: %v", path, err)
		}
	}
}

func sortedLessonIDs() []string {
	ids := make([]string, 0, len(lessonContentByID))
	for id := range lessonContentByID {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool {
		return compareLessonID(ids[i], ids[j]) < 0
	})
	return ids
}

func compareLessonID(a, b string) int {
	as, ai, aItem := parseSortableLessonID(a)
	bs, bi, bItem := parseSortableLessonID(b)

	if as != bs {
		if as < bs {
			return -1
		}
		return 1
	}

	if aItem != bItem {
		if !aItem {
			return -1
		}
		return 1
	}

	if ai != bi {
		if ai < bi {
			return -1
		}
		return 1
	}

	if a < b {
		return -1
	}
	if a > b {
		return 1
	}
	return 0
}

func parseSortableLessonID(id string) (section, item int, isItem bool) {
	section = 9999
	item = 9999
	if s, i, ok := parseItemID(id); ok {
		isItem = true
		section, _ = strconv.Atoi(s)
		item = i
		return
	}
	section, _ = strconv.Atoi(id)
	return
}

func buildExercisesForLesson(id, title, category, intro, lang string) []lessonJSONExercise {
	baseTitle := title
	baseCategory := category
	if base, ok := lessonContentByID[id]; ok {
		baseTitle = base.Title
		baseCategory = base.Category
	}

	var exercises []lessonJSONExercise
	seen := map[string]struct{}{}
	appendExercise := func(question string, options []string, correct string) {
		question = strings.TrimSpace(question)
		correct = strings.TrimSpace(correct)
		if question == "" || correct == "" {
			return
		}
		filteredOptions := make([]string, 0, len(options)+1)
		for _, option := range append([]string{correct}, options...) {
			option = strings.TrimSpace(option)
			if option == "" {
				continue
			}
			duplicate := false
			for _, existing := range filteredOptions {
				if existing == option {
					duplicate = true
					break
				}
			}
			if !duplicate {
				filteredOptions = append(filteredOptions, option)
			}
		}
		if len(filteredOptions) < 2 {
			return
		}
		key := question + "\n" + correct
		if _, ok := seen[key]; ok {
			return
		}
		seen[key] = struct{}{}
		exercises = append(exercises, lessonJSONExercise{
			ID:            fmt.Sprintf("%s-e%d", id, len(exercises)+1),
			Question:      question,
			Type:          "multiple_choice",
			Options:       filteredOptions,
			CorrectAnswer: correct,
			XPReward:      10,
		})
	}

	for _, template := range buildTopicPracticeTemplates(id, baseTitle, baseCategory, lang) {
		appendExercise(template.question, template.options, template.correct)
	}
	for _, template := range buildSectionPracticeTemplates(id, lang) {
		appendExercise(template.question, template.options, template.correct)
	}

	return exercises
}
