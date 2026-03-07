package router

import (
	"io/fs"
	"strings"

	"mathquest/backend/config"
	"mathquest/backend/internal/auth"
	"mathquest/backend/internal/camera"
	"mathquest/backend/internal/coins"
	"mathquest/backend/internal/exercise"
	"mathquest/backend/internal/invite"
	"mathquest/backend/internal/lesson"
	"mathquest/backend/internal/middleware"
	"mathquest/backend/internal/rewards"
	"mathquest/backend/internal/store"
	"mathquest/backend/internal/streak"
	"mathquest/backend/internal/user"
	"mathquest/backend/static"

	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

func Setup(app *fiber.App, cfg *config.Config, db *gorm.DB, redisClient *redis.Client) {
	// Diagrammi SVG pubblici (senza auth, fuori da /api così non passano dal middleware)
	app.Get("/diagrams/:id", serveDiagram)

	api := app.Group("/api")

	// Auth (public)
	authGroup := api.Group("/auth")
	authGroup.Post("/google", auth.Google)
	authGroup.Post("/apple", auth.Apple)
	authGroup.Post("/register-username", auth.RegisterUsername(db))
	authGroup.Get("/check-username", auth.CheckUsername(db))
	authGroup.Get("/me", middleware.FirebaseAuth(), auth.Me)

	// Onboarding
	api.Post("/onboarding", middleware.FirebaseAuth(), user.Save)

	// Streak handler
	streakHandler := streak.NewHandler(db, redisClient)

	// Protected routes
	protected := api.Group("", middleware.FirebaseAuth(), middleware.ResolveUserID(db))

	// Lessons
	protected.Get("/lessons", lesson.List)
	protected.Get("/lessons/:id", lesson.GetByID)
	protected.Post("/lessons/:id/start", lesson.Start)
	protected.Post("/lessons/:id/complete", func(c *fiber.Ctx) error {
		if err := lesson.Complete(c); err != nil {
			return err
		}
		if userID, ok := c.Locals(middleware.UserIDKey).(uint); ok && userID > 0 {
			go streakHandler.RecordActivity(userID)
		}
		return nil
	})

	// Exercises
	protected.Post("/exercises/:id/submit", func(c *fiber.Ctx) error {
		if err := exercise.Submit(c); err != nil {
			return err
		}
		if userID, ok := c.Locals(middleware.UserIDKey).(uint); ok && userID > 0 {
			go streakHandler.RecordActivity(userID)
		}
		return nil
	})

	// Camera - con OptionalCameraAuth: Bearer (Apple/Google) oppure X-Username (login username)
	cameraHandler := camera.NewHandler(db, redisClient, cfg)
	cameraAuth := api.Group("", middleware.OptionalCameraAuth(), middleware.ResolveUserID(db))
	cameraAuth.Post("/camera/solve", func(c *fiber.Ctx) error {
		if err := cameraHandler.Solve(c); err != nil {
			return err
		}
		if userID, ok := c.Locals(middleware.UserIDKey).(uint); ok && userID > 0 {
			go streakHandler.RecordActivity(userID)
		}
		return nil
	})
	cameraAuth.Get("/camera/history", cameraHandler.History)
	cameraAuth.Get("/camera/history/:id", cameraHandler.HistoryDetail)
	cameraAuth.Get("/camera/status", cameraHandler.Status)

	// Streak
	protected.Get("/streak", streakHandler.GetStreak)
	protected.Get("/streak/calendar", streakHandler.GetCalendar)

	// Coins
	protected.Get("/coins/balance", coins.Balance)
	protected.Post("/coins/daily-reward", coins.DailyReward)

	// Store
	protected.Get("/store/items", store.ListItems)
	protected.Post("/store/buy/:itemId", store.Buy)

	// Rewards / Tasks
	protected.Get("/rewards/tasks", rewards.ListTasks)
	protected.Post("/rewards/complete/:taskId", rewards.CompleteTask)

	// Invite
	protected.Get("/invite/code", invite.GetCode)
	protected.Post("/invite/redeem", invite.Redeem)

	// Profile
	protected.Get("/profile", user.NewGet(db))
	protected.Put("/profile", user.NewUpdate(db))
	protected.Get("/profile/stats", user.Stats)
}

// serveDiagram serves embedded SVG diagrams. id must be alphanumeric + hyphen (e.g. unit-circle).
func serveDiagram(c *fiber.Ctx) error {
	id := strings.TrimSpace(c.Params("id"))
	if id == "" {
		return c.Status(fiber.StatusBadRequest).SendString("missing id")
	}
	for _, r := range id {
		if r != '-' && r != '_' && (r < 'a' || r > 'z') && (r < '0' || r > '9') {
			return c.Status(fiber.StatusBadRequest).SendString("invalid id")
		}
	}
	name := "diagrams/" + id + ".svg"
	data, err := fs.ReadFile(static.Diagrams, name)
	if err != nil {
		return c.Status(fiber.StatusNotFound).SendString("not found")
	}
	c.Set("Content-Type", "image/svg+xml; charset=utf-8")
	c.Set("Cache-Control", "public, max-age=86400")
	return c.Send(data)
}
