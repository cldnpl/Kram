package coins

import (
	"log"

	"github.com/gofiber/fiber/v2"
)

func Balance(c *fiber.Ctx) error {
	log.Printf("[API] GET /coins/balance -> returning balance 150")
	return c.JSON(fiber.Map{"balance": 150})
}

func DailyReward(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"coins_added": 10, "new_balance": 160})
}
