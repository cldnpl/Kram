package user

import (
	"errors"
	"strings"

	"mathquest/backend/internal/middleware"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type usernameRecord struct {
	Username string `gorm:"column:username;primaryKey"`
}

func (usernameRecord) TableName() string { return "usernames" }

type userProfileRecord struct {
	ID          uint   `gorm:"column:id"`
	FirebaseUID string `gorm:"column:firebase_uid"`
	Name        string `gorm:"column:name"`
	Username    string `gorm:"column:username"`
	Age         int    `gorm:"column:age"`
	MathLevel   string `gorm:"column:math_level"`
	CoinBalance int    `gorm:"column:coin_balance"`
	StreakDays  int    `gorm:"column:streak_days"`
	AvatarURL   string `gorm:"column:avatar_url"`
}

func (userProfileRecord) TableName() string { return "users" }

func resolveOrCreateUserByUID(db *gorm.DB, firebaseUID string) (userProfileRecord, error) {
	var user userProfileRecord
	if err := db.Where("firebase_uid = ?", firebaseUID).First(&user).Error; err == nil {
		return user, nil
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return user, err
	}

	user = userProfileRecord{
		FirebaseUID: firebaseUID,
		Name:        "MathQuest User",
		MathLevel:   "Beginner",
	}
	if err := db.Create(&user).Error; err != nil {
		if lookupErr := db.Where("firebase_uid = ?", firebaseUID).First(&user).Error; lookupErr == nil {
			return user, nil
		}
		return user, err
	}
	return user, nil
}

// NewGet returns a profile GET handler that includes the username.
func NewGet(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if db == nil {
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

		firebaseUID, _ := c.Locals(middleware.FirebaseUIDKey).(string)
		firebaseUID = strings.TrimSpace(firebaseUID)
		if firebaseUID == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "missing_user_identity"})
		}

		user, err := resolveOrCreateUserByUID(db, firebaseUID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db_error"})
		}

		return c.JSON(fiber.Map{
			"id":           user.ID,
			"name":         user.Name,
			"username":     user.Username,
			"age":          user.Age,
			"math_level":   user.MathLevel,
			"coin_balance": user.CoinBalance,
			"streak_days":  user.StreakDays,
			"avatar_url":   user.AvatarURL,
		})
	}
}

type UpdateProfileRequest struct {
	Name      string  `json:"name"`
	Username  string  `json:"username"`
	MathLevel string  `json:"math_level"`
	AvatarURL *string `json:"avatar_url"`
}

// NewUpdate returns a profile PUT handler that validates username uniqueness.
func NewUpdate(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if db == nil {
			var req UpdateProfileRequest
			if err := c.BodyParser(&req); err != nil {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
			}
			return c.JSON(fiber.Map{"ok": true, "message": "Profile updated (mock)"})
		}

		firebaseUID, _ := c.Locals(middleware.FirebaseUIDKey).(string)
		firebaseUID = strings.TrimSpace(firebaseUID)
		if firebaseUID == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "missing_user_identity"})
		}

		var req UpdateProfileRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}

		user, err := resolveOrCreateUserByUID(db, firebaseUID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db_error"})
		}

		updates := map[string]any{}

		if name := strings.TrimSpace(req.Name); name != "" {
			updates["name"] = name
		}

		if level := strings.TrimSpace(req.MathLevel); level != "" {
			updates["math_level"] = level
		}

		if req.AvatarURL != nil {
			updates["avatar_url"] = strings.TrimSpace(*req.AvatarURL)
		}

		if req.Username != "" {
			username := strings.TrimSpace(strings.ToLower(req.Username))
			if username != "" {
				var existing userProfileRecord
				err := db.Select("id").Where("username = ? AND id <> ?", username, user.ID).First(&existing).Error
				if err == nil {
					return c.Status(fiber.StatusConflict).JSON(fiber.Map{
						"error": "username_already_exists",
					})
				}
				if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
					return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db_error"})
				}

				updates["username"] = username
				_ = db.Create(&usernameRecord{Username: username}).Error
			}
		}

		if len(updates) > 0 {
			if err := db.Table("users").Where("id = ?", user.ID).Updates(updates).Error; err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db_error"})
			}
		}

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
