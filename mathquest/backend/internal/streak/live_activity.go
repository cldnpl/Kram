package streak

import (
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"mathquest/backend/config"
	"mathquest/backend/internal/middleware"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type IOSLiveActivityDevice struct {
	ID                  uint      `gorm:"column:id;primaryKey"`
	UserID              uint      `gorm:"column:user_id"`
	DeviceID            string    `gorm:"column:device_id"`
	PushToStartToken    string    `gorm:"column:push_to_start_token"`
	TimezoneName        string    `gorm:"column:timezone_name"`
	Enabled             bool      `gorm:"column:enabled"`
	LastWarningLocalDay string    `gorm:"column:last_warning_local_day"`
	LastWarningSentAt   time.Time `gorm:"column:last_warning_sent_at"`
	LastSeenAt          time.Time `gorm:"column:last_seen_at"`
	CreatedAt           time.Time `gorm:"column:created_at"`
	UpdatedAt           time.Time `gorm:"column:updated_at"`
}

func (IOSLiveActivityDevice) TableName() string { return "ios_live_activity_devices" }

type liveActivityRegistrationRequest struct {
	DeviceID         string `json:"device_id"`
	PushToStartToken string `json:"push_to_start_token"`
	Timezone         string `json:"timezone"`
	Enabled          *bool  `json:"enabled"`
}

type streakWarningCandidate struct {
	ID                  uint       `gorm:"column:id"`
	UserID              uint       `gorm:"column:user_id"`
	DeviceID            string     `gorm:"column:device_id"`
	PushToStartToken    string     `gorm:"column:push_to_start_token"`
	TimezoneName        string     `gorm:"column:timezone_name"`
	LastWarningLocalDay string     `gorm:"column:last_warning_local_day"`
	StreakDays          int        `gorm:"column:streak_days"`
	LastActive          *time.Time `gorm:"column:last_active"`
}

type liveActivityNotifier struct {
	client      *http.Client
	privateKey  *ecdsa.PrivateKey
	teamID      string
	keyID       string
	bundleID    string
	environment string

	mu              sync.Mutex
	cachedJWT       string
	cachedJWTIssued time.Time
}

type apnsFailure struct {
	StatusCode int
	Reason     string
	Body       string
}

func (e *apnsFailure) Error() string {
	if e == nil {
		return ""
	}
	if e.Reason != "" {
		return fmt.Sprintf("apns request failed (%d): %s", e.StatusCode, e.Reason)
	}
	if e.Body != "" {
		return fmt.Sprintf("apns request failed (%d): %s", e.StatusCode, e.Body)
	}
	return fmt.Sprintf("apns request failed (%d)", e.StatusCode)
}

func newLiveActivityNotifier(cfg *config.Config) *liveActivityNotifier {
	if cfg == nil {
		return nil
	}
	if cfg.APNSTeamID == "" || cfg.APNSKeyID == "" || cfg.APNSBundleID == "" || cfg.APNSPrivateKey == "" {
		log.Printf("[StreakLiveActivity] APNs config incomplete; backend-triggered Live Activities disabled")
		return nil
	}

	privateKey, err := loadAPNSPrivateKey(cfg.APNSPrivateKey)
	if err != nil {
		log.Printf("[StreakLiveActivity] failed to load APNs private key: %v", err)
		return nil
	}

	return &liveActivityNotifier{
		client:      &http.Client{Timeout: 10 * time.Second},
		privateKey:  privateKey,
		teamID:      cfg.APNSTeamID,
		keyID:       cfg.APNSKeyID,
		bundleID:    cfg.APNSBundleID,
		environment: cfg.APNSEnvironment,
	}
}

func loadAPNSPrivateKey(path string) (*ecdsa.PrivateKey, error) {
	pemBytes, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	block, _ := pem.Decode(pemBytes)
	if block == nil {
		return nil, errors.New("invalid PEM data")
	}

	switch block.Type {
	case "PRIVATE KEY":
		key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
		if err != nil {
			return nil, err
		}
		ecdsaKey, ok := key.(*ecdsa.PrivateKey)
		if !ok {
			return nil, fmt.Errorf("unexpected private key type %T", key)
		}
		return ecdsaKey, nil
	case "EC PRIVATE KEY":
		return x509.ParseECPrivateKey(block.Bytes)
	default:
		return nil, fmt.Errorf("unsupported PEM type %q", block.Type)
	}
}

func (n *liveActivityNotifier) host() string {
	switch strings.ToLower(strings.TrimSpace(n.environment)) {
	case "development", "sandbox":
		return "https://api.sandbox.push.apple.com"
	default:
		return "https://api.push.apple.com"
	}
}

func (n *liveActivityNotifier) authToken(now time.Time) (string, error) {
	n.mu.Lock()
	defer n.mu.Unlock()

	if n.cachedJWT != "" && now.Sub(n.cachedJWTIssued) < 50*time.Minute {
		return n.cachedJWT, nil
	}

	headerJSON, err := json.Marshal(map[string]string{
		"alg": "ES256",
		"kid": n.keyID,
	})
	if err != nil {
		return "", err
	}

	claimsJSON, err := json.Marshal(map[string]any{
		"iss": n.teamID,
		"iat": now.Unix(),
	})
	if err != nil {
		return "", err
	}

	signingInput := base64.RawURLEncoding.EncodeToString(headerJSON) + "." +
		base64.RawURLEncoding.EncodeToString(claimsJSON)
	hash := sha256.Sum256([]byte(signingInput))
	signature, err := ecdsa.SignASN1(rand.Reader, n.privateKey, hash[:])
	if err != nil {
		return "", err
	}

	n.cachedJWT = signingInput + "." + base64.RawURLEncoding.EncodeToString(signature)
	n.cachedJWTIssued = now
	return n.cachedJWT, nil
}

func (n *liveActivityNotifier) SendStart(pushToStartToken string, streakDays int, deadline time.Time) error {
	if n == nil {
		return errors.New("live activity notifier is not configured")
	}

	now := time.Now().UTC()
	token, err := n.authToken(now)
	if err != nil {
		return err
	}

	payload := map[string]any{
		"aps": map[string]any{
			"timestamp":       now.Unix(),
			"event":           "start",
			"attributes-type": "StreakActivityAttributes",
			"attributes": map[string]any{
				"streakDays": streakDays,
			},
			"content-state": map[string]any{
				"deadlineTimestamp": deadline.Unix(),
				"streakDays":        streakDays,
			},
			"alert": map[string]any{
				"title": "Streak at risk",
				"body":  "Complete a lesson or solve a problem before midnight to keep your streak.",
				"sound": "default",
			},
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequest(
		http.MethodPost,
		n.host()+"/3/device/"+pushToStartToken,
		strings.NewReader(string(body)),
	)
	if err != nil {
		return err
	}

	req.Header.Set("authorization", "bearer "+token)
	req.Header.Set("apns-push-type", "liveactivity")
	req.Header.Set("apns-priority", "10")
	req.Header.Set("apns-topic", n.bundleID+".push-type.liveactivity")
	req.Header.Set("content-type", "application/json")

	res, err := n.client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	resBody, _ := io.ReadAll(res.Body)
	if res.StatusCode >= 200 && res.StatusCode < 300 {
		return nil
	}

	var parsed struct {
		Reason string `json:"reason"`
	}
	_ = json.Unmarshal(resBody, &parsed)
	return &apnsFailure{
		StatusCode: res.StatusCode,
		Reason:     parsed.Reason,
		Body:       string(resBody),
	}
}

// SendAlert sends a regular push notification (not a Live Activity) to a device.
func (n *liveActivityNotifier) SendAlert(pushToken string, title, body string) error {
	if n == nil {
		return errors.New("live activity notifier is not configured")
	}
	if title == "" {
		return nil
	}

	now := time.Now().UTC()
	token, err := n.authToken(now)
	if err != nil {
		return err
	}

	payload := map[string]any{
		"aps": map[string]any{
			"alert": map[string]any{
				"title": title,
				"body":  body,
			},
			"sound": "default",
		},
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequest(
		http.MethodPost,
		n.host()+"/3/device/"+pushToken,
		strings.NewReader(string(payloadBytes)),
	)
	if err != nil {
		return err
	}

	req.Header.Set("authorization", "bearer "+token)
	req.Header.Set("apns-push-type", "alert")
	req.Header.Set("apns-priority", "10")
	req.Header.Set("apns-topic", n.bundleID)
	req.Header.Set("content-type", "application/json")

	res, err := n.client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	resBody, _ := io.ReadAll(res.Body)
	if res.StatusCode >= 200 && res.StatusCode < 300 {
		return nil
	}

	var parsed struct {
		Reason string `json:"reason"`
	}
	_ = json.Unmarshal(resBody, &parsed)
	return &apnsFailure{
		StatusCode: res.StatusCode,
		Reason:     parsed.Reason,
		Body:       string(resBody),
	}
}

func (h *Handler) startWarningLoop() {
	if h.db == nil || h.notifier == nil {
		return
	}

	log.Printf(
		"[StreakLiveActivity] scheduler enabled (window=%s, interval=%s)",
		h.warningWindow,
		h.scanInterval,
	)

	h.scanAndSendWarnings()

	ticker := time.NewTicker(h.scanInterval)
	defer ticker.Stop()

	for range ticker.C {
		h.scanAndSendWarnings()
	}
}

func (h *Handler) scanAndSendWarnings() {
	if h.db == nil || h.notifier == nil {
		return
	}

	var candidates []streakWarningCandidate
	err := h.db.
		Table("ios_live_activity_devices d").
		Select(`
			d.id,
			d.user_id,
			d.device_id,
			d.push_to_start_token,
			d.timezone_name,
			d.last_warning_local_day,
			u.streak_days,
			u.last_active
		`).
		Joins("JOIN users u ON u.id = d.user_id").
		Where("d.enabled = ? AND d.push_to_start_token <> ''", true).
		Scan(&candidates).Error
	if err != nil {
		log.Printf("[StreakLiveActivity] query failed: %v", err)
		return
	}

	now := time.Now().UTC()
	for _, candidate := range candidates {
		deadline, localDay, shouldSend := h.shouldSendWarning(candidate, now)
		if !shouldSend {
			continue
		}

		if err := h.notifier.SendStart(candidate.PushToStartToken, candidate.StreakDays, deadline); err != nil {
			log.Printf(
				"[StreakLiveActivity] send failed for user=%d device=%s: %v",
				candidate.UserID,
				candidate.DeviceID,
				err,
			)
			continue
		}

		if err := h.db.Model(&IOSLiveActivityDevice{}).
			Where("id = ?", candidate.ID).
			Updates(map[string]any{
				"last_warning_local_day": localDay,
				"last_warning_sent_at":   now,
				"updated_at":             now,
			}).Error; err != nil {
			log.Printf(
				"[StreakLiveActivity] failed to persist warning marker for user=%d device=%s: %v",
				candidate.UserID,
				candidate.DeviceID,
				err,
			)
		}
	}
}

func (h *Handler) shouldSendWarning(candidate streakWarningCandidate, now time.Time) (time.Time, string, bool) {
	if candidate.StreakDays <= 0 || candidate.LastActive == nil {
		return time.Time{}, "", false
	}

	location := time.UTC
	if candidate.TimezoneName != "" {
		if loaded, err := time.LoadLocation(candidate.TimezoneName); err == nil {
			location = loaded
		}
	}

	localNow := now.In(location)
	localDay := localNow.Format("2006-01-02")
	if candidate.LastWarningLocalDay == localDay {
		return time.Time{}, "", false
	}

	nextMidnight := time.Date(
		localNow.Year(),
		localNow.Month(),
		localNow.Day()+1,
		0,
		0,
		0,
		0,
		location,
	)
	if remaining := nextMidnight.Sub(localNow); remaining <= 0 || remaining > h.warningWindow {
		return time.Time{}, "", false
	}

	lastActiveLocal := candidate.LastActive.In(location)
	if sameLocalDay(lastActiveLocal, localNow) {
		return time.Time{}, "", false
	}
	if !sameLocalDay(lastActiveLocal, localNow.AddDate(0, 0, -1)) {
		return time.Time{}, "", false
	}

	return nextMidnight, localDay, true
}

func sameLocalDay(a, b time.Time) bool {
	ay, am, ad := a.Date()
	by, bm, bd := b.Date()
	return ay == by && am == bm && ad == bd
}

func (h *Handler) UpsertLiveActivityDevice(c *fiber.Ctx) error {
	if h.db == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"error": "database_unavailable",
		})
	}

	var req liveActivityRegistrationRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_request_body",
		})
	}

	req.DeviceID = strings.TrimSpace(req.DeviceID)
	req.PushToStartToken = strings.ToLower(strings.TrimSpace(req.PushToStartToken))
	req.Timezone = strings.TrimSpace(req.Timezone)
	if req.Timezone == "" {
		req.Timezone = "UTC"
	}
	enabled := true
	if req.Enabled != nil {
		enabled = *req.Enabled
	}

	if req.DeviceID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "device_id_required",
		})
	}
	if _, err := time.LoadLocation(req.Timezone); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_timezone",
		})
	}
	if enabled {
		if req.PushToStartToken == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "push_to_start_token_required",
			})
		}
		if _, err := hex.DecodeString(req.PushToStartToken); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "invalid_push_to_start_token",
			})
		}
	}

	userID := h.resolveOrCreateUserID(c)
	if userID == 0 {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "unable_to_resolve_user",
		})
	}

	now := time.Now().UTC()
	var existing IOSLiveActivityDevice
	err := h.db.Where("device_id = ?", req.DeviceID).First(&existing).Error
	switch {
	case err == nil:
		updates := map[string]any{
			"user_id":       userID,
			"timezone_name": req.Timezone,
			"enabled":       enabled,
			"last_seen_at":  now,
			"updated_at":    now,
		}
		if req.PushToStartToken != "" {
			updates["push_to_start_token"] = req.PushToStartToken
		}
		if err := h.db.Model(&IOSLiveActivityDevice{}).Where("id = ?", existing.ID).Updates(updates).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "device_update_failed"})
		}
	case errors.Is(err, gorm.ErrRecordNotFound):
		if req.PushToStartToken == "" {
			return c.JSON(fiber.Map{"ok": true})
		}
		device := IOSLiveActivityDevice{
			UserID:           userID,
			DeviceID:         req.DeviceID,
			PushToStartToken: req.PushToStartToken,
			TimezoneName:     req.Timezone,
			Enabled:          enabled,
			LastSeenAt:       now,
			CreatedAt:        now,
			UpdatedAt:        now,
		}
		if err := h.db.Create(&device).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "device_create_failed"})
		}
	default:
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "device_lookup_failed"})
	}

	return c.JSON(fiber.Map{"ok": true})
}

func (h *Handler) resolveOrCreateUserID(c *fiber.Ctx) uint {
	if userID, ok := c.Locals(middleware.UserIDKey).(uint); ok && userID > 0 {
		return userID
	}
	if h.db == nil {
		return 0
	}

	firebaseUID, _ := c.Locals(middleware.FirebaseUIDKey).(string)
	firebaseUID = strings.TrimSpace(firebaseUID)
	if firebaseUID == "" {
		return 0
	}

	var user User
	if err := h.db.Select("id, streak_days, last_active").Where("firebase_uid = ?", firebaseUID).First(&user).Error; err == nil {
		return user.ID
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		log.Printf("[StreakLiveActivity] resolve user failed: %v", err)
		return 0
	}

	createPayload := map[string]any{
		"firebase_uid": firebaseUID,
		"name":         "",
		"created_at":   time.Now().UTC(),
	}
	if err := h.db.Table("users").Create(createPayload).Error; err != nil {
		var created User
		if lookupErr := h.db.Select("id, streak_days, last_active").Where("firebase_uid = ?", firebaseUID).First(&created).Error; lookupErr == nil {
			return created.ID
		}
		log.Printf("[StreakLiveActivity] create user failed: %v", err)
		return 0
	}

	var created User
	if err := h.db.Select("id, streak_days, last_active").Where("firebase_uid = ?", firebaseUID).First(&created).Error; err != nil {
		return 0
	}
	return created.ID
}
