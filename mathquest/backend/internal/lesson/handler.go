package lesson

import (
	"log"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type completeLessonRequest struct {
	LessonCost int `json:"lesson_cost"`
}

func List(c *fiber.Ctx) error {
	lang := normalizeLessonLang(c.Query("lang", "en"))
	cat := curriculumForLang(lang)
	log.Printf("[API] GET /lessons -> returning %d categories (lang=%s)", len(cat), lang)
	return c.JSON(fiber.Map{"categories": cat})
}

func GetByID(c *fiber.Ctx) error {
	id := c.Params("id")
	lang := normalizeLessonLang(c.Query("lang", "en"))
	title, category, content, exercises := getLessonDetail(id, lang)
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

	tier := normalizeSubscriptionTier(c.Get("X-Subscription-Tier"))

	var req completeLessonRequest
	if len(c.Body()) > 0 {
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "invalid request body",
			})
		}
	}

	// Lessons are always free; ignore any client-provided lesson cost.
	req.LessonCost = 0

	coinsEarned := coinsEarnedForCompletion(req.LessonCost)

	return c.JSON(fiber.Map{
		"ok":                true,
		"coins_earned":      coinsEarned,
		"lesson_cost":       req.LessonCost,
		"subscription_tier": tier,
		"full_refund":       req.LessonCost > 0,
	})
}

func normalizeSubscriptionTier(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "premium", "pro", "max":
		return "premium"
	default:
		return "free"
	}
}

func coinsEarnedForCompletion(lessonCost int) int {
	_ = lessonCost
	return 0
}
