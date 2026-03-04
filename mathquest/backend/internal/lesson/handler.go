package lesson

import (
	"log"
	"math"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type completeLessonRequest struct {
	LessonCost int `json:"lesson_cost"`
}

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

	tier := normalizeSubscriptionTier(c.Get("X-Subscription-Tier"))

	var req completeLessonRequest
	if len(c.Body()) > 0 {
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "invalid request body",
			})
		}
	}

	if req.LessonCost < 0 {
		req.LessonCost = 0
	}

	coinsEarned := coinsEarnedForCompletion(req.LessonCost, tier)

	return c.JSON(fiber.Map{
		"ok":                true,
		"coins_earned":      coinsEarned,
		"lesson_cost":       req.LessonCost,
		"subscription_tier": tier,
		"full_refund":       tier == "max" && req.LessonCost > 0,
	})
}

func normalizeSubscriptionTier(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "pro":
		return "pro"
	case "max":
		return "max"
	default:
		return "free"
	}
}

func lessonRewardRateForTier(tier string) float64 {
	switch tier {
	case "pro":
		return 0.60
	case "max":
		return 1.0
	default:
		return 0.25
	}
}

func coinsEarnedForCompletion(lessonCost int, tier string) int {
	normalizedCost := lessonCost
	if normalizedCost < 0 {
		normalizedCost = 0
	}
	if normalizedCost == 0 {
		return 0
	}

	if tier == "max" {
		// Max gets full refund of the completed lesson.
		return normalizedCost
	}

	rawReward := int(math.Floor(float64(normalizedCost) * lessonRewardRateForTier(tier)))
	if rawReward < 0 {
		rawReward = 0
	}
	if rawReward > normalizedCost {
		rawReward = normalizedCost
	}

	return rawReward
}
