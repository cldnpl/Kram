package router

import (
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
	"mathquest/backend/internal/user"

	"github.com/gofiber/fiber/v2"
)

func Setup(app *fiber.App, cfg *config.Config) {
	api := app.Group("/api")

	// Auth (public)
	authGroup := api.Group("/auth")
	authGroup.Post("/google", auth.Google)
	authGroup.Post("/apple", auth.Apple)
	authGroup.Get("/me", middleware.FirebaseAuth(), auth.Me)

	// Onboarding
	api.Post("/onboarding", middleware.FirebaseAuth(), user.Save)

	// Protected routes
	protected := api.Group("", middleware.FirebaseAuth())

	// Lessons
	protected.Get("/lessons", lesson.List)
	protected.Get("/lessons/:id", lesson.GetByID)
	protected.Post("/lessons/:id/start", lesson.Start)
	protected.Post("/lessons/:id/complete", lesson.Complete)

	// Exercises
	protected.Post("/exercises/:id/submit", exercise.Submit)

	// Camera
	protected.Post("/camera/solve", camera.Solve)

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
	protected.Get("/profile", user.Get)
	protected.Put("/profile", user.Update)
	protected.Get("/profile/stats", user.Stats)
}
