package auth

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"mathquest/backend/internal/middleware"
	"gorm.io/gorm"
)

// UsernameRecord tabella usernames (solo per check esistenza)
type UsernameRecord struct {
	Username string `gorm:"column:username;primaryKey"`
}

func (UsernameRecord) TableName() string { return "usernames" }

// RegisterUsername registra un username se non esiste; ritorna 409 se già presente.
func RegisterUsername(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"error": "database_not_available",
			})
		}
		var body struct {
			Username string `json:"username"`
		}
		if err := c.BodyParser(&body); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		username := strings.TrimSpace(strings.ToLower(body.Username))
		if username == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "username_required"})
		}
		var existing UsernameRecord
		err := db.Where("username = ?", username).First(&existing).Error
		if err == nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"error": "username_already_exists",
			})
		}
		if err != gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db_error"})
		}
		if err := db.Create(&UsernameRecord{Username: username}).Error; err != nil {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"error": "username_already_exists",
			})
		}
		return c.JSON(fiber.Map{"ok": true})
	}
}

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
