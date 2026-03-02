package store

import (
	"github.com/gofiber/fiber/v2"
)

func ListItems(c *fiber.Ctx) error {
	mockItems := []fiber.Map{
		{"id": "1", "name": "Hint pack", "description": "3 hints for lessons", "coin_cost": 20, "item_type": "hint"},
		{"id": "2", "name": "Skip exercise", "description": "Skip one exercise", "coin_cost": 15, "item_type": "powerup"},
		{"id": "3", "name": "Premium avatar", "description": "Exclusive avatar", "coin_cost": 100, "item_type": "avatar"},
	}
	return c.JSON(fiber.Map{"items": mockItems})
}

func Buy(c *fiber.Ctx) error {
	itemId := c.Params("itemId")
	_ = itemId
	return c.JSON(fiber.Map{"ok": true, "message": "Purchase completed (mock)", "new_balance": 130})
}
