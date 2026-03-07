package streak

import (
	"context"
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	"mathquest/backend/internal/middleware"
)

type Handler struct {
	db    *gorm.DB
	redis *redis.Client
}

type User struct {
	ID         uint       `gorm:"column:id;primaryKey"`
	StreakDays int        `gorm:"column:streak_days"`
	LastActive *time.Time `gorm:"column:last_active"`
}

func (User) TableName() string { return "users" }

func NewHandler(db *gorm.DB, redisClient *redis.Client) *Handler {
	return &Handler{db: db, redis: redisClient}
}

// RecordActivity updates the user's streak based on Duolingo logic.
func (h *Handler) RecordActivity(userID uint) {
	if h.db == nil || userID == 0 {
		return
	}

	ctx := context.Background()
	today := time.Now().UTC().Format("2006-01-02")

	// Fast check via Redis — skip DB if already recorded today
	if h.redis != nil {
		key := fmt.Sprintf("streak_recorded:%d:%s", userID, today)
		exists, err := h.redis.Exists(ctx, key).Result()
		if err == nil && exists > 0 {
			return
		}
	}

	var user User
	if err := h.db.Select("id, streak_days, last_active").Where("id = ?", userID).First(&user).Error; err != nil {
		return
	}

	now := time.Now().UTC()
	todayDate := now.Truncate(24 * time.Hour)

	if user.LastActive != nil {
		lastDate := user.LastActive.UTC().Truncate(24 * time.Hour)

		if lastDate.Equal(todayDate) {
			// Already active today — mark in Redis and return
			h.markRecordedInRedis(ctx, userID, today)
			return
		}

		yesterday := todayDate.Add(-24 * time.Hour)
		if lastDate.Equal(yesterday) {
			// Active yesterday — increment streak
			user.StreakDays++
		} else {
			// Missed a day — reset
			user.StreakDays = 1
		}
	} else {
		// First ever activity
		user.StreakDays = 1
	}

	user.LastActive = &now
	h.db.Model(&User{}).Where("id = ?", userID).Updates(map[string]interface{}{
		"streak_days": user.StreakDays,
		"last_active": user.LastActive,
	})

	h.markRecordedInRedis(ctx, userID, today)
}

func (h *Handler) markRecordedInRedis(ctx context.Context, userID uint, date string) {
	if h.redis == nil {
		return
	}
	key := fmt.Sprintf("streak_recorded:%d:%s", userID, date)
	h.redis.Set(ctx, key, "1", 48*time.Hour)
}

// GetStreak handles GET /api/streak
func (h *Handler) GetStreak(c *fiber.Ctx) error {
	userID, _ := c.Locals(middleware.UserIDKey).(uint)
	if h.db == nil || userID == 0 {
		return c.JSON(fiber.Map{
			"streak_days":  0,
			"active_today": false,
		})
	}

	var user User
	if err := h.db.Select("id, streak_days, last_active").Where("id = ?", userID).First(&user).Error; err != nil {
		return c.JSON(fiber.Map{
			"streak_days":  0,
			"active_today": false,
		})
	}

	now := time.Now().UTC()
	todayDate := now.Truncate(24 * time.Hour)
	yesterday := todayDate.Add(-24 * time.Hour)

	streakDays := user.StreakDays
	activeToday := false

	if user.LastActive != nil {
		lastDate := user.LastActive.UTC().Truncate(24 * time.Hour)

		if lastDate.Equal(todayDate) {
			activeToday = true
		} else if lastDate.Before(yesterday) {
			// Streak expired
			streakDays = 0
		}
	} else {
		streakDays = 0
	}

	return c.JSON(fiber.Map{
		"streak_days":  streakDays,
		"active_today": activeToday,
	})
}
