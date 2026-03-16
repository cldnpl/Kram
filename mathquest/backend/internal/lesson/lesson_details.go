package lesson

import (
	"math/rand"
	"time"

	"github.com/gofiber/fiber/v2"
)

// getLessonDetail returns lesson content and exercises for the given id.
// Supported ids:
// - section ids: "1".."27"
// - item ids: "1-0", "1-1", ...
func getLessonDetail(id, lang string) (title, category string, content fiber.Map, exercises []fiber.Map) {
	if lesson, ok := lessonFromJSON(id, lang); ok {
		title = lesson.Title
		category = lesson.Category
		content = fiber.Map{"intro": normalizeLessonIntro(lesson.Intro)}
		selectedExercises := selectPracticeSessionExercises(lesson.Exercises)
		exercises = make([]fiber.Map, 0, len(selectedExercises))
		for _, ex := range selectedExercises {
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
		content = fiber.Map{"intro": normalizeLessonIntro(c.Intro)}
	} else {
		title, category = "Lesson", "Math"
		content = fiber.Map{"intro": "Content not available."}
	}
	exercises = defaultExercises()
	return
}

func selectPracticeSessionExercises(pool []lessonJSONExercise) []lessonJSONExercise {
	if len(pool) == 0 {
		return nil
	}

	copied := make([]lessonJSONExercise, len(pool))
	copy(copied, pool)

	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	rng.Shuffle(len(copied), func(i, j int) {
		copied[i], copied[j] = copied[j], copied[i]
	})

	targetCount := len(copied)
	if targetCount > 20 {
		targetCount = 15 + rng.Intn(6)
	}
	if targetCount > len(copied) {
		targetCount = len(copied)
	}
	selected := copied[:targetCount]
	for i := range selected {
		options := append([]string(nil), selected[i].Options...)
		rng.Shuffle(len(options), func(a, b int) {
			options[a], options[b] = options[b], options[a]
		})
		selected[i].Options = options
	}
	return selected
}

func defaultExercises() []fiber.Map {
	return []fiber.Map{
		{"id": "e1", "question": "Practice exercise 1 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "A", "xp_reward": 10},
		{"id": "e2", "question": "Practice exercise 2 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "B", "xp_reward": 10},
	}
}
