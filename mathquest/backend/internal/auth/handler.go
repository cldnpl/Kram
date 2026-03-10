package auth

import (
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
	"mathquest/backend/internal/middleware"
)

// UsernameRecord tabella usernames (solo per check esistenza)
type UsernameRecord struct {
	Username string `gorm:"column:username;primaryKey"`
}

func (UsernameRecord) TableName() string { return "usernames" }

// CheckUsername returns whether a username is available.
func CheckUsername(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		fmt.Printf("[CheckUsername] called with query: %s\n", c.OriginalURL())
		if db == nil {
			fmt.Println("[CheckUsername] db is nil — falling back to available=true")
			return c.JSON(fiber.Map{"available": true})
		}
		username := strings.TrimSpace(strings.ToLower(c.Query("username")))
		fmt.Printf("[CheckUsername] parsed username=%q\n", username)
		if username == "" {
			fmt.Println("[CheckUsername] empty username — returning 400")
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "username_required"})
		}
		var existing UsernameRecord
		err := db.Where("username = ?", username).First(&existing).Error
		fmt.Printf("[CheckUsername] db lookup err=%v\n", err)
		if err == gorm.ErrRecordNotFound {
			fmt.Printf("[CheckUsername] username=%q is available\n", username)
			return c.JSON(fiber.Map{"available": true})
		}
		if err != nil {
			fmt.Printf("[CheckUsername] db error: %v\n", err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db_error"})
		}
		fmt.Printf("[CheckUsername] username=%q is taken\n", username)
		return c.JSON(fiber.Map{"available": false})
	}
}

// RegisterUsername registra un username se non esiste; ritorna 409 se già presente.
func RegisterUsername(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if db == nil {
			fmt.Println("[RegisterUsername] db is nil — falling back to ok")
			return c.JSON(fiber.Map{"ok": true})
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
		"token":   "mock-token-google",
		"name":    "",
		"email":   "mock@example.com",
	})
}

func Apple(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"user_id": 1,
		"token":   "mock-token-apple",
		"name":    "",
	})
}

func Me(c *fiber.Ctx) error {
	uid := c.Locals(middleware.FirebaseUIDKey)
	if uid == nil {
		uid = "mock-firebase-uid"
	}
	return c.JSON(fiber.Map{
		"id":           1,
		"firebase_uid": uid,
		"name":         "",
		"age":          12,
		"math_level":   "beginner",
		"coin_balance": 150,
		"streak_days":  3,
	})
}
