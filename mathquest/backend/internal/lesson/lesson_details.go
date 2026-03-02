package lesson

import (
	"github.com/gofiber/fiber/v2"
)

// getLessonDetail returns lesson content and exercises for the given id.
// Supported ids:
// - section ids: "1".."27"
// - item ids: "1-0", "1-1", ...
func getLessonDetail(id string) (title, category string, content fiber.Map, exercises []fiber.Map) {
	if c, ok := getContentByID(id); ok {
		title, category = c.Title, c.Category
		content = fiber.Map{"intro": c.Intro}
	} else {
		title, category = "Lesson", "Math"
		content = fiber.Map{"intro": "Content not available."}
	}
	exercises = []fiber.Map{
		{"id": "e1", "question": "Practice exercise 1 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "A", "xp_reward": 10},
		{"id": "e2", "question": "Practice exercise 2 (coming soon).", "type": "multiple_choice", "options": []string{"A", "B", "C", "D"}, "correct_answer": "B", "xp_reward": 10},
	}
	return
}
