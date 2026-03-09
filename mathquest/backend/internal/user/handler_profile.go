package user

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type usernameRecord struct {
	Username string `gorm:"column:username;primaryKey"`
}

func (usernameRecord) TableName() string { return "usernames" }

// NewGet returns a profile GET handler that includes the username.
func NewGet(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"id":           1,
			"name":         "Mock User",
			"username":     "",
			"age":          12,
			"math_level":   "beginner",
			"coin_balance": 150,
			"streak_days":  3,
			"avatar_url":   "",
		})
	}
}

type UpdateProfileRequest struct {
	Name      string `json:"name"`
	Username  string `json:"username"`
	MathLevel string `json:"math_level"`
}

// NewUpdate returns a profile PUT handler that validates username uniqueness.
func NewUpdate(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		var req UpdateProfileRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}

		// If username is provided, check uniqueness against usernames table
		if db != nil && req.Username != "" {
			username := strings.TrimSpace(strings.ToLower(req.Username))
			var existing usernameRecord
			err := db.Where("username = ?", username).First(&existing).Error
			if err == nil {
				// Username exists — conflict
				return c.Status(fiber.StatusConflict).JSON(fiber.Map{
					"error": "username_already_exists",
				})
			}
			if err != gorm.ErrRecordNotFound {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db_error"})
			}
		}

		// TODO: persist to DB
		return c.JSON(fiber.Map{"ok": true, "message": "Profile updated"})
	}
}

// Legacy handlers for backward compat with router
func Get(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"id":           1,
		"name":         "Mock User",
		"username":     "",
		"age":          12,
		"math_level":   "beginner",
		"coin_balance": 150,
		"streak_days":  3,
		"avatar_url":   "",
	})
}

func Update(c *fiber.Ctx) error {
	var req UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"ok": true, "message": "Profile updated (mock)"})
}

func Stats(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"streak_days":       0,
		"lessons_completed": 0,
		"coins_earned":      0,
		"exercises_correct": 0,
	})
}
