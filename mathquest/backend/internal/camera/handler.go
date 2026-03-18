package camera

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"html"
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

const (
	freeDailyLimit      = 3
	unlimitedDailyLimit = -1
)

type appUser struct {
	ID          uint   `gorm:"column:id"`
	FirebaseUID string `gorm:"column:firebase_uid"`
	Username    string `gorm:"column:username"`
	Name        string `gorm:"column:name"`
}

type userSubscriptionSnapshot struct {
	SubscriptionTier      string     `gorm:"column:subscription_tier"`
	SubscriptionExpiresAt *time.Time `gorm:"column:subscription_expires_at"`
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
	case "premium", "pro", "max":
		return "premium"
	default:
		return "free"
	}
}

func normalizeSolutionLanguage(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "en":
		return "en"
	case "it":
		return "it"
	case "fr":
		return "fr"
	case "es":
		return "es"
	case "uz":
		return "uz"
	default:
		return "unknown"
	}
}

func (h *Handler) dailyLimitForTier(tier string) int {
	switch tier {
	case "premium":
		return unlimitedDailyLimit
	default:
		return freeDailyLimit
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

func (h *Handler) effectiveSubscriptionTier(c *fiber.Ctx, userID uint) string {
	if h.db != nil && userID > 0 {
		var snapshot userSubscriptionSnapshot
		err := h.db.Table("users").
			Select("subscription_tier, subscription_expires_at").
			Where("id = ?", userID).
			First(&snapshot).Error
		if err == nil {
			tier := normalizeSubscriptionTier(snapshot.SubscriptionTier)
			if tier == "premium" && snapshot.SubscriptionExpiresAt != nil && snapshot.SubscriptionExpiresAt.Before(time.Now().UTC()) {
				return "free"
			}
			return tier
		}
	}

	// Backward-compatible fallback during rollout: rely on client header only when
	// no server subscription state can be loaded.
	return normalizeSubscriptionTier(c.Get("X-Subscription-Tier"))
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

func parseSolutionSteps(raw json.RawMessage) []string {
	var steps []string
	if err := json.Unmarshal(raw, &steps); err != nil {
		return []string{}
	}
	if steps == nil {
		return []string{}
	}
	return steps
}

func isValidShareToken(token string) bool {
	if len(token) < 10 || len(token) > 64 {
		return false
	}
	for _, r := range token {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '-' || r == '_' {
			continue
		}
		return false
	}
	return true
}

func generateShareToken() (string, error) {
	buf := make([]byte, 18)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

func (h *Handler) ensureShareToken(solution *CameraSolution) (string, error) {
	if solution.ShareToken != "" {
		return solution.ShareToken, nil
	}
	if h.db == nil {
		return "", errors.New("database unavailable")
	}

	for attempt := 0; attempt < 5; attempt++ {
		token, err := generateShareToken()
		if err != nil {
			return "", err
		}

		now := time.Now()
		query := h.db.Model(&CameraSolution{})
		if solution.UserID > 0 {
			query = query.Where("id = ? AND user_id = ?", solution.ID, solution.UserID)
		} else {
			query = query.Where("id = ?", solution.ID)
		}
		err = query.Updates(map[string]any{
			"share_token": token,
			"shared_at":   now,
		}).Error

		if err != nil {
			if strings.Contains(strings.ToLower(err.Error()), "duplicate") {
				continue
			}
			return "", err
		}

		solution.ShareToken = token
		solution.SharedAt = &now
		return token, nil
	}

	return "", errors.New("failed to generate unique share token")
}

func normalizeShareCreateRequest(req *ShareCreateRequest) {
	req.Problem = strings.TrimSpace(req.Problem)
	req.Solution = strings.TrimSpace(req.Solution)
	req.RawLatex = strings.TrimSpace(req.RawLatex)
	req.DifficultyLevel = strings.TrimSpace(req.DifficultyLevel)
	if req.DifficultyLevel == "" {
		req.DifficultyLevel = "unknown"
	}
	if req.Steps == nil {
		req.Steps = []string{}
	}
}

func (h *Handler) loadSharedSolutionByToken(token string) (*SharedSolutionResponse, error) {
	if h.db == nil {
		return nil, gorm.ErrRecordNotFound
	}

	var solution CameraSolution
	if err := h.db.Where("share_token = ?", token).First(&solution).Error; err != nil {
		return nil, err
	}

	return &SharedSolutionResponse{
		Token:           token,
		Problem:         solution.OriginalProblem,
		Solution:        solution.Solution,
		Steps:           parseSolutionSteps(solution.StepsJSON),
		RawLatex:        solution.RawLatex,
		DifficultyLevel: solution.DifficultyLevel,
		CreatedAt:       solution.CreatedAt,
	}, nil
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
	firebaseUIDLower := strings.ToLower(firebaseUID)
	isUsernameAuth := strings.HasPrefix(firebaseUIDLower, "username:")
	usernameHint := ""
	if isUsernameAuth {
		usernameHint = strings.TrimSpace(strings.TrimPrefix(firebaseUIDLower, "username:"))
	}

	var user appUser
	if err := h.db.Where("firebase_uid = ?", firebaseUID).First(&user).Error; err == nil {
		c.Locals(middleware.UserIDKey, user.ID)
		return user.ID
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		fmt.Printf("failed to resolve user by firebase_uid: %v\n", err)
		return 0
	}

	// Username-based auth must never overwrite a real Firebase user (Apple/Google)
	// that happens to share the same username.
	if isUsernameAuth && usernameHint != "" {
		if err := h.db.
			Where("LOWER(username) = ? AND LOWER(firebase_uid) LIKE ?", usernameHint, "username:%").
			First(&user).Error; err == nil {
			if strings.TrimSpace(user.FirebaseUID) != firebaseUID {
				_ = h.db.Model(&appUser{}).
					Where("id = ?", user.ID).
					Update("firebase_uid", firebaseUID).Error
			}
			c.Locals(middleware.UserIDKey, user.ID)
			return user.ID
		}
	}

	createValues := map[string]any{
		"firebase_uid": firebaseUID,
		"name":         "",
	}
	if err := h.db.Table("users").Create(createValues).Error; err != nil {
		// If another request created the same user concurrently, fetch it.
		if err := h.db.Where("firebase_uid = ?", firebaseUID).First(&user).Error; err == nil {
			c.Locals(middleware.UserIDKey, user.ID)
			return user.ID
		}
		if usernameHint != "" {
			if err := h.db.Where("LOWER(username) = ?", usernameHint).First(&user).Error; err == nil {
				c.Locals(middleware.UserIDKey, user.ID)
				return user.ID
			}
		}
		fmt.Printf("failed to create user for firebase_uid=%s: %v\n", firebaseUID, err)
		return 0
	}

	// Reload the just-created user.
	if err := h.db.Where("firebase_uid = ?", firebaseUID).First(&user).Error; err != nil {
		fmt.Printf("failed to load created user for firebase_uid=%s: %v\n", firebaseUID, err)
		return 0
	}

	c.Locals(middleware.UserIDKey, user.ID)
	return user.ID
}

// Solve handles POST /api/camera/solve
func (h *Handler) Solve(c *fiber.Ctx) error {
	userID := h.resolveUserID(c)
	tier := h.effectiveSubscriptionTier(c, userID)
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

	if req.ImageBase64 == "" && req.ProblemText == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "image_base64 or problem_text is required",
		})
	}

	if req.MediaType == "" {
		req.MediaType = "image/jpeg"
	}

	// Call Claude API
	preferredLang := req.PreferredLanguage
	if preferredLang == "" {
		preferredLang = "en"
	}

	var (
		solution *claude.MathSolution
		solveErr error
	)
	if req.ProblemText != "" {
		solution, solveErr = h.claudeSvc.SolveMathProblemFromText(req.ProblemText)
	} else {
		solution, solveErr = h.claudeSvc.SolveMathProblem(req.ImageBase64, req.MediaType)
	}
	if solveErr != nil {
		remaining := unlimitedDailyLimit
		if effectiveDailyLimit >= 0 {
			remaining = effectiveDailyLimit - usedToday
			if remaining < 0 {
				remaining = 0
			}
		}
		return c.JSON(SolveResponse{
			ID:                  0,
			Problem:             "Problem text could not be read clearly from image.",
			Solution:            "I could not process this scan right now. Please retake the photo.",
			Steps:               []string{},
			RawLatex:            "",
			DifficultyLevel:     "unknown",
			DetectedLanguage:    "unknown",
			ShouldSaveToHistory: false,
			UsesRemainingToday:  remaining,
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

	shouldSaveToHistory := solution.ShouldSaveToHistory == nil || *solution.ShouldSaveToHistory
	var savedID uint
	if shouldSaveToHistory && h.db != nil && userID > 0 {
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

	var graphResp *GraphDataResponse

	stepsDetail := solution.StepsDetail
	if stepsDetail == nil {
		stepsDetail = []string{}
	}

	return c.JSON(SolveResponse{
		ID:                  savedID,
		Problem:             solution.Problem,
		Solution:            solution.Solution,
		Steps:               solution.Steps,
		StepsDetail:         stepsDetail,
		RawLatex:            solution.RawLatex,
		DifficultyLevel:     solution.DifficultyLevel,
		DetectedLanguage:    normalizeSolutionLanguage(solution.DetectedLanguage),
		ShouldSaveToHistory: shouldSaveToHistory,
		UsesRemainingToday:  remaining,
		GraphData:           graphResp,
	})
}

// Translate handles POST /api/camera/translate
func (h *Handler) Translate(c *fiber.Ctx) error {
	var req TranslateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid request body",
		})
	}

	targetLanguage := normalizeSolutionLanguage(req.TargetLanguage)
	if targetLanguage == "unknown" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "target_language is unsupported",
		})
	}

	source := &claude.MathSolution{
		Problem:             req.Problem,
		Solution:            req.Solution,
		Steps:               req.Steps,
		StepsDetail:         req.StepsDetail,
		RawLatex:            req.RawLatex,
		DifficultyLevel:     req.DifficultyLevel,
		DetectedLanguage:    normalizeSolutionLanguage(req.DetectedLanguage),
		ShouldSaveToHistory: &req.ShouldSaveToHistory,
	}

	if source.Steps == nil {
		source.Steps = []string{}
	}
	if source.StepsDetail == nil {
		source.StepsDetail = []string{}
	}
	if source.DifficultyLevel == "" {
		source.DifficultyLevel = "unknown"
	}

	translated, err := h.claudeSvc.TranslateMathSolution(source, targetLanguage)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": fmt.Sprintf("failed to translate solution: %v", err),
		})
	}

	if translated.Steps == nil {
		translated.Steps = []string{}
	}
	if translated.StepsDetail == nil {
		translated.StepsDetail = []string{}
	}
	if translated.DifficultyLevel == "" {
		translated.DifficultyLevel = source.DifficultyLevel
	}

	return c.JSON(TranslateResponse{
		Problem:             translated.Problem,
		Solution:            translated.Solution,
		Steps:               translated.Steps,
		StepsDetail:         translated.StepsDetail,
		RawLatex:            translated.RawLatex,
		DifficultyLevel:     translated.DifficultyLevel,
		DetectedLanguage:    normalizeSolutionLanguage(translated.DetectedLanguage),
		ShouldSaveToHistory: translated.ShouldSaveToHistory == nil || *translated.ShouldSaveToHistory,
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

	return c.JSON(HistoryDetailResponse{
		ID:              solution.ID,
		Problem:         solution.OriginalProblem,
		Solution:        solution.Solution,
		Steps:           parseSolutionSteps(solution.StepsJSON),
		RawLatex:        solution.RawLatex,
		DifficultyLevel: solution.DifficultyLevel,
		CreatedAt:       solution.CreatedAt,
	})
}

// ShareHistoryDetail handles POST /api/camera/history/:id/share
func (h *Handler) ShareHistoryDetail(c *fiber.Ctx) error {
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
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&solution).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error": "solution not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to fetch solution",
		})
	}

	token, err := h.ensureShareToken(&solution)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to create share link",
		})
	}

	return c.JSON(ShareHistoryResponse{
		Token: token,
		ID:    solution.ID,
	})
}

// ShareCreate handles POST /api/camera/share
// Creates a shareable solution record from client-provided content (used for local/offline items).
func (h *Handler) ShareCreate(c *fiber.Ctx) error {
	userID := h.resolveUserID(c)
	if h.db == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "database unavailable",
		})
	}

	var req ShareCreateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid request body",
		})
	}
	normalizeShareCreateRequest(&req)

	if req.Problem == "" || req.Solution == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "problem and solution are required",
		})
	}

	stepsJSON, _ := json.Marshal(req.Steps)
	now := time.Now()
	solution := CameraSolution{
		OriginalProblem: req.Problem,
		Solution:        req.Solution,
		StepsJSON:       stepsJSON,
		RawLatex:        req.RawLatex,
		DifficultyLevel: req.DifficultyLevel,
		CreatedAt:       now,
	}
	createQuery := h.db
	if userID > 0 {
		solution.UserID = userID
	} else {
		// Allow sharing even when auth token cannot be mapped to a users row yet.
		createQuery = createQuery.Omit("UserID")
	}

	if err := createQuery.Create(&solution).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to save shareable solution",
		})
	}

	token, err := h.ensureShareToken(&solution)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to create share link",
		})
	}

	return c.JSON(ShareHistoryResponse{
		Token: token,
		ID:    solution.ID,
	})
}

// SharedDetail handles GET /api/camera/shared/:token
func (h *Handler) SharedDetail(c *fiber.Ctx) error {
	token := strings.TrimSpace(c.Params("token"))
	if !isValidShareToken(token) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid token",
		})
	}

	shared, err := h.loadSharedSolutionByToken(token)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"error": "solution not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to load shared solution",
		})
	}

	return c.JSON(shared)
}

// SharedLandingPage handles GET /s/:token
func (h *Handler) SharedLandingPage(c *fiber.Ctx) error {
	token := strings.TrimSpace(c.Params("token"))
	if !isValidShareToken(token) {
		return c.Status(fiber.StatusBadRequest).SendString("Invalid link")
	}

	shared, err := h.loadSharedSolutionByToken(token)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).SendString("This shared solution was not found.")
		}
		return c.Status(fiber.StatusInternalServerError).SendString("Unable to open shared solution.")
	}

	baseURL := strings.TrimRight(c.BaseURL(), "/")
	shareURL := baseURL + "/s/" + token
	appURL := "kram://solution/" + token

	title := html.EscapeString("Kram Solution")
	problem := html.EscapeString(shared.Problem)
	answer := html.EscapeString(shared.Solution)
	escapedShareURL := html.EscapeString(shareURL)
	escapedAppURL := html.EscapeString(appURL)

	page := fmt.Sprintf(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>%s</title>
  <meta name="description" content="%s">
  <meta property="og:title" content="%s">
  <meta property="og:description" content="Answer: %s">
  <meta property="og:type" content="article">
  <meta property="og:url" content="%s">
  <meta name="twitter:card" content="summary">
  <meta name="apple-itunes-app" content="app-argument=%s">
  <style>
    body { margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background:#0b1220; color:#f4f7ff; }
    .wrap { max-width:720px; margin:0 auto; padding:24px 20px 40px; }
    h1 { font-size:28px; line-height:1.2; margin:0 0 10px; }
    .card { background:#141e35; border:1px solid #243154; border-radius:16px; padding:16px; margin-top:14px; }
    .label { color:#9fb0d9; font-size:12px; text-transform:uppercase; letter-spacing:0.08em; margin-bottom:8px; }
    .value { color:#f4f7ff; font-size:18px; line-height:1.4; }
    .cta { display:inline-block; margin-top:20px; background:#35c59d; color:#062c22; padding:12px 18px; border-radius:12px; font-weight:700; text-decoration:none; }
    .hint { margin-top:12px; color:#9fb0d9; font-size:14px; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Solve Math Faster with Kram</h1>
    <div class="card">
      <div class="label">Problem</div>
      <div class="value">%s</div>
    </div>
    <div class="card">
      <div class="label">Answer</div>
      <div class="value">%s</div>
    </div>
    <a class="cta" href="%s">Open in Kram App</a>
    <div class="hint">If the app is installed, this link opens it directly.</div>
  </div>
  <script>
    setTimeout(function () { window.location.href = %q; }, 120);
  </script>
</body>
</html>`,
		title,
		problem,
		title,
		answer,
		escapedShareURL,
		escapedAppURL,
		problem,
		answer,
		escapedAppURL,
		appURL,
	)

	c.Set("Content-Type", "text/html; charset=utf-8")
	c.Set("Cache-Control", "public, max-age=120")
	return c.SendString(page)
}

// DeleteHistoryDetail handles DELETE /api/camera/history/:id
func (h *Handler) DeleteHistoryDetail(c *fiber.Ctx) error {
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

	res := h.db.Where("id = ? AND user_id = ?", id, userID).Delete(&CameraSolution{})
	if res.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to delete solution",
		})
	}
	if res.RowsAffected == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "solution not found",
		})
	}

	return c.JSON(fiber.Map{
		"deleted": true,
	})
}

// Status handles GET /api/camera/status
func (h *Handler) Status(c *fiber.Ctx) error {
	userID := h.resolveUserID(c)
	tier := h.effectiveSubscriptionTier(c, userID)
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
