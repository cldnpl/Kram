package camera

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"mathquest/backend/config"
	"mathquest/backend/internal/claude"
	"mathquest/backend/internal/middleware"

	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type Handler struct {
	db         *gorm.DB
	redis      *redis.Client
	claudeSvc  *claude.Service
	dailyLimit int
}

const unlimitedDailyLimit = -1

type appUser struct {
	ID          uint   `gorm:"column:id"`
	FirebaseUID string `gorm:"column:firebase_uid"`
	Name        string `gorm:"column:name"`
}

func (appUser) TableName() string {
	return "users"
}

func NewHandler(db *gorm.DB, redisClient *redis.Client, cfg *config.Config) *Handler {
	return &Handler{
		db:         db,
		redis:      redisClient,
		claudeSvc:  claude.NewService(cfg.ClaudeAPIKey),
		dailyLimit: cfg.CameraDailyLimit,
	}
}

func normalizeSubscriptionTier(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "pro":
		return "pro"
	case "max":
		return "max"
	default:
		return "free"
	}
}

func (h *Handler) dailyLimitForTier(tier string) int {
	switch tier {
	case "pro":
		return 10
	case "max":
		return unlimitedDailyLimit
	default:
		return h.dailyLimit
	}
}

func (h *Handler) isGuestRequest(c *fiber.Ctx) bool {
	firebaseUID, _ := c.Locals(middleware.FirebaseUIDKey).(string)
	firebaseUID = strings.TrimSpace(strings.ToLower(firebaseUID))
	if firebaseUID == "" {
		return true
	}
	return strings.HasPrefix(firebaseUID, "guest:")
}

func (h *Handler) dailyLimitForRequest(c *fiber.Ctx, tier string) int {
	if h.isGuestRequest(c) {
		return 1
	}
	return h.dailyLimitForTier(tier)
}

func (h *Handler) getDailyUsage(ctx context.Context, userID uint) (int, error) {
	if h.redis == nil {
		return 0, nil
	}

	key := fmt.Sprintf("camera_usage:%d:%s", userID, time.Now().Format("2006-01-02"))
	count, err := h.redis.Get(ctx, key).Int()
	if err == redis.Nil {
		return 0, nil
	}
	return count, err
}

func (h *Handler) incrementDailyUsage(ctx context.Context, userID uint) error {
	if h.redis == nil {
		return nil
	}

	key := fmt.Sprintf("camera_usage:%d:%s", userID, time.Now().Format("2006-01-02"))
	pipe := h.redis.Pipeline()
	pipe.Incr(ctx, key)
	// Expire at midnight
	pipe.ExpireAt(ctx, key, time.Now().Add(24*time.Hour).Truncate(24*time.Hour))
	_, err := pipe.Exec(ctx)
	return err
}

func (h *Handler) resolveUserID(c *fiber.Ctx) uint {
	if userID, ok := c.Locals(middleware.UserIDKey).(uint); ok && userID > 0 {
		return userID
	}

	if h.db == nil {
		return 0
	}

	firebaseUID, _ := c.Locals(middleware.FirebaseUIDKey).(string)
	firebaseUID = strings.TrimSpace(firebaseUID)
	if firebaseUID == "" {
		firebaseUID = "dev-anonymous-user"
	}

	var user appUser
	if err := h.db.Where("firebase_uid = ?", firebaseUID).First(&user).Error; err == nil {
		return user.ID
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		fmt.Printf("failed to resolve user by firebase_uid: %v\n", err)
		return 0
	}

	user = appUser{
		FirebaseUID: firebaseUID,
		Name:        "",
	}
	if err := h.db.Create(&user).Error; err != nil {
		// If another request created the same user concurrently, fetch it.
		if err := h.db.Where("firebase_uid = ?", firebaseUID).First(&user).Error; err == nil {
			return user.ID
		}
		fmt.Printf("failed to create user for firebase_uid=%s: %v\n", firebaseUID, err)
		return 0
	}

	return user.ID
}

// Solve handles POST /api/camera/solve
func (h *Handler) Solve(c *fiber.Ctx) error {
	userID := h.resolveUserID(c)
	tier := normalizeSubscriptionTier(c.Get("X-Subscription-Tier"))
	effectiveDailyLimit := h.dailyLimitForRequest(c, tier)

	ctx := context.Background()

	// Check rate limit
	usedToday, err := h.getDailyUsage(ctx, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to check usage limit",
		})
	}

	if effectiveDailyLimit >= 0 && usedToday >= effectiveDailyLimit {
		return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
			"error":                "daily limit reached",
			"uses_remaining_today": 0,
		})
	}

	// Parse request
	var req SolveRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid request body",
		})
	}

	if req.ImageBase64 == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "image_base64 is required",
		})
	}

	if req.MediaType == "" {
		req.MediaType = "image/jpeg"
	}

	// Call Claude API
	solution, err := h.claudeSvc.SolveMathProblem(req.ImageBase64, req.MediaType)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": fmt.Sprintf("failed to solve problem: %v", err),
		})
	}

	// Normalize nullable fields so mobile clients get a stable JSON shape.
	if solution.Steps == nil {
		solution.Steps = []string{}
	}
	if solution.DifficultyLevel == "" {
		solution.DifficultyLevel = "unknown"
	}

	// Increment usage
	if err := h.incrementDailyUsage(ctx, userID); err != nil {
		// Log but don't fail the request
		fmt.Printf("failed to increment usage: %v\n", err)
	}

	var savedID uint
	if h.db != nil && userID > 0 {
		stepsJSON, _ := json.Marshal(solution.Steps)
		cameraSolution := CameraSolution{
			UserID:          userID,
			OriginalProblem: solution.Problem,
			Solution:        solution.Solution,
			StepsJSON:       stepsJSON,
			RawLatex:        solution.RawLatex,
			DifficultyLevel: solution.DifficultyLevel,
			CreatedAt:       time.Now(),
		}

		if err := h.db.Create(&cameraSolution).Error; err != nil {
			// Log but don't fail the request
			fmt.Printf("failed to save solution: %v\n", err)
		} else {
			savedID = cameraSolution.ID
		}
	}

	remaining := unlimitedDailyLimit
	if effectiveDailyLimit >= 0 {
		remaining = effectiveDailyLimit - usedToday - 1
		if remaining < 0 {
			remaining = 0
		}
	}

	return c.JSON(SolveResponse{
		ID:                 savedID,
		Problem:            solution.Problem,
		Solution:           solution.Solution,
		Steps:              solution.Steps,
		RawLatex:           solution.RawLatex,
		DifficultyLevel:    solution.DifficultyLevel,
		UsesRemainingToday: remaining,
	})
}

// History handles GET /api/camera/history
func (h *Handler) History(c *fiber.Ctx) error {
	userID := h.resolveUserID(c)
	if h.db == nil || userID == 0 {
		return c.JSON(fiber.Map{
			"history": []HistoryItem{},
		})
	}

	var solutions []CameraSolution
	if err := h.db.Where("user_id = ?", userID).
		Order("created_at DESC").
		Limit(50).
		Find(&solutions).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to fetch history",
		})
	}

	history := make([]HistoryItem, len(solutions))
	for i, s := range solutions {
		history[i] = HistoryItem{
			ID:              s.ID,
			Problem:         s.OriginalProblem,
			Solution:        s.Solution,
			DifficultyLevel: s.DifficultyLevel,
			CreatedAt:       s.CreatedAt,
		}
	}

	return c.JSON(fiber.Map{
		"history": history,
	})
}

// HistoryDetail handles GET /api/camera/history/:id
func (h *Handler) HistoryDetail(c *fiber.Ctx) error {
	userID := h.resolveUserID(c)
	if h.db == nil || userID == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "solution not found",
		})
	}

	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid id",
		})
	}

	var solution CameraSolution
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).
		First(&solution).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error": "solution not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to fetch solution",
		})
	}

	var steps []string
	if err := json.Unmarshal(solution.StepsJSON, &steps); err != nil {
		steps = []string{}
	}
	if steps == nil {
		steps = []string{}
	}

	return c.JSON(HistoryDetailResponse{
		ID:              solution.ID,
		Problem:         solution.OriginalProblem,
		Solution:        solution.Solution,
		Steps:           steps,
		RawLatex:        solution.RawLatex,
		DifficultyLevel: solution.DifficultyLevel,
		CreatedAt:       solution.CreatedAt,
	})
}

// Status handles GET /api/camera/status
func (h *Handler) Status(c *fiber.Ctx) error {
	userID := h.resolveUserID(c)
	tier := normalizeSubscriptionTier(c.Get("X-Subscription-Tier"))
	effectiveDailyLimit := h.dailyLimitForRequest(c, tier)

	ctx := context.Background()
	usedToday, err := h.getDailyUsage(ctx, userID)
	if err != nil {
		usedToday = 0
	}

	remaining := unlimitedDailyLimit
	if effectiveDailyLimit >= 0 {
		remaining = effectiveDailyLimit - usedToday
		if remaining < 0 {
			remaining = 0
		}
	}

	return c.JSON(StatusResponse{
		DailyLimit: effectiveDailyLimit,
		UsedToday:  usedToday,
		Remaining:  remaining,
	})
}
