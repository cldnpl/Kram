package auth

import (
	"github.com/gofiber/fiber/v2"
	"mathquest/backend/internal/middleware"
)

func Google(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"user_id": 1,
		"token":  "mock-token-google",
		"name":   "Mock User",
		"email":  "mock@example.com",
	})
}

func Apple(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"user_id": 1,
		"token":  "mock-token-apple",
		"name":   "Mock User",
	})
}

func Me(c *fiber.Ctx) error {
	uid := c.Locals(middleware.FirebaseUIDKey)
	if uid == nil {
		uid = "mock-firebase-uid"
	}
	return c.JSON(fiber.Map{
		"id":          1,
		"firebase_uid": uid,
		"name":        "Mock User",
		"age":         12,
		"math_level":  "beginner",
		"coin_balance": 150,
		"streak_days": 3,
	})
}
