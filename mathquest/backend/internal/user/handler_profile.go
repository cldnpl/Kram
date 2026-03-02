package user

import (
	"github.com/gofiber/fiber/v2"
)

func Get(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"id":           1,
		"name":         "Mock User",
		"age":          12,
		"math_level":   "beginner",
		"coin_balance":  150,
		"streak_days":  3,
		"avatar_url":   "",
	})
}

func Update(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"ok": true, "message": "Profile updated (mock)"})
}

func Stats(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"streak_days":        5,
		"lessons_completed":  12,
		"coins_earned":       320,
		"exercises_correct":  48,
	})
}
