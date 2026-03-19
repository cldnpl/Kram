package streak

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"mathquest/backend/config"
	"mathquest/backend/internal/middleware"
)

type Handler struct {
	db            *gorm.DB
	redis         *redis.Client
	notifier      *liveActivityNotifier
	warningWindow time.Duration
	scanInterval  time.Duration
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

func NewHandler(db *gorm.DB, redisClient *redis.Client, cfg *config.Config) *Handler {
	handler := &Handler{
		db:            db,
		redis:         redisClient,
		notifier:      newLiveActivityNotifier(cfg),
		warningWindow: 4 * time.Hour,
		scanInterval:  15 * time.Minute,
	}

	if cfg != nil {
		if cfg.StreakWarnHours > 0 {
			handler.warningWindow = time.Duration(cfg.StreakWarnHours) * time.Hour
		}
		if cfg.StreakScanMins > 0 {
			handler.scanInterval = time.Duration(cfg.StreakScanMins) * time.Minute
		}
	}

	if handler.db != nil && handler.notifier != nil {
		go handler.startWarningLoop()
	}

	return handler
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

	// Send congratulations notification for streak milestones
	if h.notifier != nil && user.StreakDays >= 1 {
		go h.sendStreakCongrats(userID, user.StreakDays)
	}
}

func (h *Handler) markRecordedInRedis(ctx context.Context, userID uint, date string) {
	if h.redis == nil {
		return
	}
	key := fmt.Sprintf("streak_recorded:%d:%s", userID, date)
	h.redis.Set(ctx, key, "1", 48*time.Hour)
}

func (h *Handler) sendStreakCongrats(userID uint, streakDays int) {
	if h.db == nil || h.notifier == nil {
		return
	}

	var devices []IOSLiveActivityDevice
	h.db.Where("user_id = ? AND enabled = ? AND push_to_start_token <> ''", userID, true).Find(&devices)

	for _, device := range devices {
		title, body := streakCongratsMessage(streakDays)
		if err := h.notifier.SendAlert(device.PushToStartToken, title, body); err != nil {
			log.Printf("[StreakCongrats] send failed user=%d device=%s: %v", userID, device.DeviceID, err)
		}
	}
}

func streakCongratsMessage(days int) (string, string) {
	switch days {
	case 1:
		return "First streak day!", "Congratulations on your first streak day! Keep it up!"
	case 3:
		return "3-day streak!", "You're on fire! 3 days in a row. Keep going!"
	case 7:
		return "1 week streak!", "Amazing! A full week of learning. You're unstoppable!"
	case 14:
		return "2 week streak!", "Two weeks straight! Your dedication is paying off!"
	case 30:
		return "30-day streak!", "One month of daily learning! You're a math champion!"
	default:
		if days > 0 && days%10 == 0 {
			return fmt.Sprintf("%d-day streak!", days), fmt.Sprintf("Incredible! %d days of consistent learning!", days)
		}
		return "", ""
	}
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
