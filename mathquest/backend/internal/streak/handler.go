package streak

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

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

type ActivityLog struct {
	ID         uint      `gorm:"column:id;primaryKey"`
	UserID     uint      `gorm:"column:user_id"`
	ActiveDate time.Time `gorm:"column:active_date;type:date"`
	CreatedAt  time.Time `gorm:"column:created_at"`
}

func (ActivityLog) TableName() string { return "activity_log" }

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

	// Log this day in activity_log for calendar
	h.db.Clauses(clause.OnConflict{DoNothing: true}).Create(&ActivityLog{
		UserID:     userID,
		ActiveDate: todayDate,
		CreatedAt:  now,
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

// GetCalendar handles GET /api/streak/calendar?year=2026&month=3
// Returns list of active dates for the given month.
func (h *Handler) GetCalendar(c *fiber.Ctx) error {
	userID, _ := c.Locals(middleware.UserIDKey).(uint)
	if h.db == nil || userID == 0 {
		return c.JSON(fiber.Map{"active_dates": []string{}})
	}

	now := time.Now().UTC()
	year, _ := strconv.Atoi(c.Query("year", strconv.Itoa(now.Year())))
	month, _ := strconv.Atoi(c.Query("month", strconv.Itoa(int(now.Month()))))

	if month < 1 || month > 12 {
		month = int(now.Month())
	}
	if year < 2020 || year > 2100 {
		year = now.Year()
	}

	startDate := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC)
	endDate := startDate.AddDate(0, 1, 0)

	var logs []ActivityLog
	h.db.Where("user_id = ? AND active_date >= ? AND active_date < ?", userID, startDate, endDate).
		Order("active_date ASC").
		Find(&logs)

	dates := make([]string, len(logs))
	for i, log := range logs {
		dates[i] = log.ActiveDate.Format("2006-01-02")
	}

	return c.JSON(fiber.Map{
		"active_dates": dates,
		"year":         year,
		"month":        month,
	})
}
