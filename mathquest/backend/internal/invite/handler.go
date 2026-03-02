package invite

import (
	"github.com/gofiber/fiber/v2"
)

func GetCode(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"code": "MOCK-XY7Z"})
}

func Redeem(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"ok": true, "coins_earned": 15, "message": "Code redeemed (mock)"})
}
