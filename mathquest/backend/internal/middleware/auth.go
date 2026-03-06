package middleware

import (
	"log"
	"strings"

	"github.com/gofiber/fiber/v2"
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
		// TODO: verify token with Firebase Admin SDK and extract UID
		// Placeholder for now; integrate pkg/firebase
		c.Locals(FirebaseUIDKey, token)
		c.Locals(UserIDKey, uint(0)) // will be replaced with ID from DB after lookup
		return c.Next()
	}
}

// OptionalCameraAuth accepts either Bearer token (Firebase) or X-Username header (login con username).
// Usato per le route camera così funzionano con Apple, Google o username/password.
func OptionalCameraAuth() fiber.Handler {
	return func(c *fiber.Ctx) error {
		auth := c.Get("Authorization")
		if auth != "" {
			parts := strings.SplitN(auth, " ", 2)
			if len(parts) == 2 && parts[0] == "Bearer" {
				c.Locals(FirebaseUIDKey, parts[1])
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
