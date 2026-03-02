package rewards

import (
	"github.com/gofiber/fiber/v2"
)

func ListTasks(c *fiber.Ctx) error {
	mockTasks := []fiber.Map{
		{"id": "1", "key": "complete_first_lesson", "title": "Complete your first lesson", "description": "Finish one lesson", "coin_reward": 20, "is_repeatable": false, "completed": false},
		{"id": "2", "key": "share_social", "title": "Share on social", "description": "Share MathQuest", "coin_reward": 15, "is_repeatable": false, "completed": false},
		{"id": "3", "key": "fill_profile", "title": "Complete your profile", "description": "Add name and level", "coin_reward": 10, "is_repeatable": false, "completed": true},
	}
	return c.JSON(fiber.Map{"tasks": mockTasks})
}

func CompleteTask(c *fiber.Ctx) error {
	taskId := c.Params("taskId")
	_ = taskId
	return c.JSON(fiber.Map{"ok": true, "coins_earned": 20, "new_balance": 170})
}
