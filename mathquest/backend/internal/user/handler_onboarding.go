package user

import (
	"github.com/gofiber/fiber/v2"
)

type OnboardingRequest struct {
	Name      string `json:"name"`
	Age       int    `json:"age"`
	MathLevel string `json:"math_level"`
}

func Save(c *fiber.Ctx) error {
	var req OnboardingRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	// TODO: save to DB via user service
	return c.JSON(fiber.Map{"ok": true})
}
