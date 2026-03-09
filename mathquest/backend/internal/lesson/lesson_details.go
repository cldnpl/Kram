package lesson

import (
	"strings"

	"github.com/gofiber/fiber/v2"
)

// getLessonDetail returns lesson content and exercises for the given id.
// Supported ids:
// - section ids: "1".."27"
// - item ids: "1-0", "1-1", ...
func getLessonDetail(id, lang string) (title, category string, content fiber.Map, exercises []fiber.Map) {
	normalizedLang := normalizeLessonLang(lang)
	if lesson, ok := lessonFromJSON(id, normalizedLang); ok {
		if normalizedLang != "en" {
			if english, ok := lessonFromJSON(id, "en"); ok {
				if tr := translationMap(normalizedLang); len(tr) > 0 {
					if v, ok := tr[english.Title]; ok && strings.TrimSpace(v) != "" {
						lesson.Title = v
					}
					if v, ok := tr[english.Category]; ok && strings.TrimSpace(v) != "" {
						lesson.Category = v
					}
				}

				translatedIntro := localizeLessonIntro(id, english.Intro, normalizedLang)
				if strings.TrimSpace(translatedIntro) != "" && translatedIntro != english.Intro {
					lesson.Intro = translatedIntro
				}

				if len(english.Exercises) > 0 {
					lesson.Exercises = localizeLessonExercises(id, english.Exercises, lesson.Exercises, normalizedLang)
				}
			}
		}

		title = lesson.Title
		category = lesson.Category
		content = fiber.Map{"intro": lesson.Intro}
		exercises = make([]fiber.Map, 0, len(lesson.Exercises))
		for _, ex := range lesson.Exercises {
			exercises = append(exercises, fiber.Map{
				"id":             ex.ID,
				"question":       ex.Question,
				"type":           ex.Type,
				"options":        ex.Options,
				"correct_answer": ex.CorrectAnswer,
				"xp_reward":      ex.XPReward,
			})
		}
		if len(exercises) == 0 {
			exercises = defaultExercises()
		}
		return
	}

	if c, ok := getContentByID(id, lang); ok {
		title, category = c.Title, c.Category
		content = fiber.Map{"intro": c.Intro}
	} else {
		title, category = "Lesson", "Math"
		content = fiber.Map{"intro": "Content not available."}
	}
	exercises = defaultExercises()
	return
}

func defaultExercises() []fiber.Map {
	return []fiber.Map{
		{"id": "e1", "question": "Practice exercise 1 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "A", "xp_reward": 10},
		{"id": "e2", "question": "Practice exercise 2 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "B", "xp_reward": 10},
	}
}
