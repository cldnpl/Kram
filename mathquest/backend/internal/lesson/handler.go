package lesson

import (
	"log"

	"github.com/gofiber/fiber/v2"
)

func List(c *fiber.Ctx) error {
	cat := curriculum()
	log.Printf("[API] GET /lessons -> returning %d categories with subtopics", len(cat))
	return c.JSON(fiber.Map{"categories": cat})
}

func GetByID(c *fiber.Ctx) error {
	id := c.Params("id")
	title, category, content, exercises := getLessonDetail(id)
	return c.JSON(fiber.Map{
		"id":           id,
		"title":        title,
		"category":     category,
		"content_json": content,
		"exercises":    exercises,
	})
}

func Start(c *fiber.Ctx) error {
	id := c.Params("id")
	_ = id
	return c.JSON(fiber.Map{"ok": true, "message": "Lesson unlocked (mock)"})
}

func Complete(c *fiber.Ctx) error {
	id := c.Params("id")
	_ = id
	return c.JSON(fiber.Map{"ok": true, "coins_earned": 25})
}
