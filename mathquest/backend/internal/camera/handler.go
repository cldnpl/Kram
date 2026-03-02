package camera

import (
	"github.com/gofiber/fiber/v2"
)

func Solve(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"solution":             "12",
		"steps":                []string{"The expression is 7 + 5", "7 + 5 = 12"},
		"uses_remaining_today": 2,
		"raw_latex":            "7+5=12",
	})
}
