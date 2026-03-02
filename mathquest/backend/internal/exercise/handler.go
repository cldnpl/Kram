package exercise

import (
	"github.com/gofiber/fiber/v2"
)

func Submit(c *fiber.Ctx) error {
	id := c.Params("id")
	_ = id
	return c.JSON(fiber.Map{
		"correct":   true,
		"xp_earned": 10,
		"feedback":  "Correct!",
	})
}
