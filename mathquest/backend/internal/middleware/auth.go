package middleware

import (
	"errors"
	"log"
	"strings"

	"mathquest/backend/pkg/firebase"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

const UserIDKey = "user_id"
const FirebaseUIDKey = "firebase_uid"

// FirebaseAuth verifies the Firebase token in the Authorization header
func FirebaseAuth() fiber.Handler {
	return func(c *fiber.Ctx) error {
		auth := c.Get("Authorization")
		if auth == "" {
			log.Printf("[AUTH] 401 %s %s - missing authorization", c.Method(), c.Path())
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "missing authorization"})
		}
		parts := strings.SplitN(auth, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			log.Printf("[AUTH] 401 %s %s - invalid authorization format", c.Method(), c.Path())
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid authorization format"})
		}
		token := parts[1]

		uid, err := firebase.VerifyIDToken(c.UserContext(), token)
		if err != nil {
			log.Printf("[AUTH] 401 %s %s - token verification failed: %v", c.Method(), c.Path(), err)
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid token"})
		}

		if uid == "" {
			// Firebase not initialized — fall back to raw token (dev mode)
			uid = token
		}

		c.Locals(FirebaseUIDKey, uid)
		c.Locals(UserIDKey, uint(0))
		return c.Next()
	}
}

// ResolveUserID looks up the user's DB ID from firebase_uid and stores it in locals.
func ResolveUserID(db *gorm.DB) fiber.Handler {
	type userRow struct {
		ID uint `gorm:"column:id"`
	}
	return func(c *fiber.Ctx) error {
		if db == nil {
			return c.Next()
		}
		firebaseUID, _ := c.Locals(FirebaseUIDKey).(string)
		if firebaseUID == "" {
			return c.Next()
		}
		var u userRow
		err := db.Table("users").Select("id").Where("firebase_uid = ?", firebaseUID).First(&u).Error
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("[AUTH] failed to resolve user ID: %v", err)
		}
		if u.ID > 0 {
			c.Locals(UserIDKey, u.ID)
		}
		return c.Next()
	}
}

// OptionalCameraAuth accepts either Bearer token (Firebase) or X-Username header (login con username).
func OptionalCameraAuth() fiber.Handler {
	return func(c *fiber.Ctx) error {
		auth := c.Get("Authorization")
		if auth != "" {
			parts := strings.SplitN(auth, " ", 2)
			if len(parts) == 2 && parts[0] == "Bearer" {
				token := parts[1]
				uid, err := firebase.VerifyIDToken(c.UserContext(), token)
				if err != nil {
					log.Printf("[AUTH] camera token verification failed: %v", err)
					return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid token"})
				}
				if uid == "" {
					uid = token
				}
				c.Locals(FirebaseUIDKey, uid)
				c.Locals(UserIDKey, uint(0))
				return c.Next()
			}
		}
		username := strings.TrimSpace(strings.ToLower(c.Get("X-Username")))
		if username != "" {
			c.Locals(FirebaseUIDKey, "username:"+username)
			c.Locals(UserIDKey, uint(0))
			return c.Next()
		}
		log.Printf("[AUTH] 401 %s %s - missing authorization or X-Username", c.Method(), c.Path())
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "missing authorization or X-Username"})
	}
}
