package subscription

import (
	"errors"
	"strings"
	"time"

	"mathquest/backend/config"
	"mathquest/backend/internal/middleware"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

const (
	premiumProductID   = "com.kram.mathquest.subscription.premium.monthly"
	legacyProProductID = "com.kram.mathquest.subscription.pro.monthly"
	legacyMaxProductID = "com.kram.mathquest.subscription.max.monthly"
)

type Handler struct {
	db       *gorm.DB
	verifier *appleVerifier
}

type verifyRequest struct {
	OriginalTransactionID string `json:"original_transaction_id"`
	ProductID             string `json:"product_id"`
	Environment           string `json:"environment"`
}

type userSubscriptionRecord struct {
	ID                                uint       `gorm:"column:id"`
	FirebaseUID                       string     `gorm:"column:firebase_uid"`
	SubscriptionTier                  string     `gorm:"column:subscription_tier"`
	SubscriptionProductID             string     `gorm:"column:subscription_product_id"`
	SubscriptionOriginalTransactionID string     `gorm:"column:subscription_original_transaction_id"`
	SubscriptionExpiresAt             *time.Time `gorm:"column:subscription_expires_at"`
	SubscriptionCheckedAt             *time.Time `gorm:"column:subscription_checked_at"`
	SubscriptionSource                string     `gorm:"column:subscription_source"`
}

func (userSubscriptionRecord) TableName() string { return "users" }

func NewHandler(db *gorm.DB, cfg *config.Config) *Handler {
	return &Handler{
		db:       db,
		verifier: newAppleVerifier(cfg),
	}
}

// VerifyApple verifies a subscription transaction against the App Store Server API.
func (h *Handler) VerifyApple(c *fiber.Ctx) error {
	if h.db == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"error": "database unavailable",
		})
	}
	if h.verifier == nil || !h.verifier.isConfigured() {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"error": "app store verifier is not configured",
		})
	}

	var req verifyRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid request body",
		})
	}

	req.OriginalTransactionID = strings.TrimSpace(req.OriginalTransactionID)
	if req.OriginalTransactionID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "original_transaction_id is required",
		})
	}

	user, err := h.resolveOrCreateCurrentUser(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "missing user identity",
		})
	}

	verification, err := h.verifier.verifyOriginalTransaction(
		c.UserContext(),
		req.OriginalTransactionID,
		req.Environment,
	)
	if err != nil {
		return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{
			"error": "apple verification failed",
		})
	}

	normalizedProductID := normalizeProductID(verification.ProductID)
	tier := tierFromProductID(normalizedProductID, verification.Active)
	now := time.Now().UTC()

	updates := map[string]any{
		"subscription_tier":                    tier,
		"subscription_product_id":              normalizedProductID,
		"subscription_original_transaction_id": verification.OriginalTransactionID,
		"subscription_expires_at":              verification.ExpiresAt,
		"subscription_checked_at":              now,
		"subscription_source":                  "app_store",
	}

	if err := h.db.Table("users").Where("id = ?", user.ID).Updates(updates).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to persist subscription",
		})
	}

	return c.JSON(fiber.Map{
		"ok":                      true,
		"user_id":                 user.ID,
		"subscription_tier":       tier,
		"active":                  tier == "premium",
		"product_id":              normalizedProductID,
		"expires_at":              verification.ExpiresAt,
		"checked_at":              now,
		"environment":             verification.Environment,
		"original_transaction_id": verification.OriginalTransactionID,
	})
}

// Status returns the server-side subscription status for the current user.
func (h *Handler) Status(c *fiber.Ctx) error {
	if h.db == nil {
		return c.JSON(fiber.Map{
			"subscription_tier": "free",
			"active":            false,
			"source":            "none",
		})
	}

	user, err := h.resolveOrCreateCurrentUser(c)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "missing user identity",
		})
	}

	tier := normalizeStoredTier(user.SubscriptionTier)
	if tier == "premium" && user.SubscriptionExpiresAt != nil && user.SubscriptionExpiresAt.Before(time.Now().UTC()) {
		tier = "free"
	}

	return c.JSON(fiber.Map{
		"subscription_tier":       tier,
		"active":                  tier == "premium",
		"product_id":              normalizeProductID(user.SubscriptionProductID),
		"expires_at":              user.SubscriptionExpiresAt,
		"checked_at":              user.SubscriptionCheckedAt,
		"source":                  strings.TrimSpace(user.SubscriptionSource),
		"original_transaction_id": strings.TrimSpace(user.SubscriptionOriginalTransactionID),
	})
}

func (h *Handler) resolveOrCreateCurrentUser(c *fiber.Ctx) (userSubscriptionRecord, error) {
	var record userSubscriptionRecord
	if h.db == nil {
		return record, errors.New("database unavailable")
	}

	if userID, ok := c.Locals(middleware.UserIDKey).(uint); ok && userID > 0 {
		if err := h.db.Where("id = ?", userID).First(&record).Error; err == nil {
			return record, nil
		}
	}

	firebaseUID, _ := c.Locals(middleware.FirebaseUIDKey).(string)
	firebaseUID = strings.TrimSpace(firebaseUID)
	if firebaseUID == "" {
		return record, errors.New("missing firebase uid")
	}

	if err := h.db.Where("firebase_uid = ?", firebaseUID).First(&record).Error; err == nil {
		c.Locals(middleware.UserIDKey, record.ID)
		return record, nil
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return record, err
	}

	record = userSubscriptionRecord{
		FirebaseUID:        firebaseUID,
		SubscriptionTier:   "free",
		SubscriptionSource: "none",
	}
	if err := h.db.Create(&record).Error; err != nil {
		if lookupErr := h.db.Where("firebase_uid = ?", firebaseUID).First(&record).Error; lookupErr == nil {
			c.Locals(middleware.UserIDKey, record.ID)
			return record, nil
		}
		return record, err
	}

	c.Locals(middleware.UserIDKey, record.ID)
	return record, nil
}

func normalizeStoredTier(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "premium", "pro", "max":
		return "premium"
	default:
		return "free"
	}
}

func normalizeProductID(raw string) string {
	productID := strings.TrimSpace(raw)
	switch productID {
	case premiumProductID, legacyProProductID, legacyMaxProductID:
		return productID
	default:
		return productID
	}
}

func tierFromProductID(productID string, active bool) string {
	if !active {
		return "free"
	}
	switch normalizeProductID(productID) {
	case premiumProductID, legacyProProductID, legacyMaxProductID:
		return "premium"
	default:
		return "free"
	}
}
