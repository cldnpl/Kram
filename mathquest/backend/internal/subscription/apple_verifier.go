package subscription

import (
	"context"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"mathquest/backend/config"
)

const (
	appStoreProdBaseURL    = "https://api.storekit.itunes.apple.com"
	appStoreSandboxBaseURL = "https://api.storekit-sandbox.itunes.apple.com"
)

type appleVerifier struct {
	httpClient  *http.Client
	issuerID    string
	keyID       string
	bundleID    string
	defaultEnv  string
	privateKey  *ecdsa.PrivateKey
	prodBaseURL string
	sbxBaseURL  string
}

type appleVerificationResult struct {
	OriginalTransactionID string
	ProductID             string
	ExpiresAt             *time.Time
	Active                bool
	Environment           string
}

type appleSubscriptionsResponse struct {
	Environment string                    `json:"environment"`
	Data        []appleSubscriptionStatus `json:"data"`
}

type appleSubscriptionStatus struct {
	Status           int                    `json:"status"`
	LastTransactions []appleLastTransaction `json:"lastTransactions"`
}

type appleLastTransaction struct {
	OriginalTransactionID string `json:"originalTransactionId"`
	Status                int    `json:"status"`
	SignedTransactionInfo string `json:"signedTransactionInfo"`
}

type signedTransactionPayload struct {
	BundleID              string `json:"bundleId"`
	ProductID             string `json:"productId"`
	OriginalTransactionID string `json:"originalTransactionId"`
	TransactionID         string `json:"transactionId"`
	PurchaseDate          int64  `json:"purchaseDate"`
	ExpiresDate           int64  `json:"expiresDate"`
	RevocationDate        int64  `json:"revocationDate"`
}

func newAppleVerifier(cfg *config.Config) *appleVerifier {
	verifier := &appleVerifier{
		httpClient:  &http.Client{Timeout: 10 * time.Second},
		prodBaseURL: appStoreProdBaseURL,
		sbxBaseURL:  appStoreSandboxBaseURL,
	}
	if cfg == nil {
		return verifier
	}

	verifier.issuerID = strings.TrimSpace(cfg.AppStoreIssuerID)
	verifier.keyID = strings.TrimSpace(cfg.AppStoreKeyID)
	verifier.bundleID = strings.TrimSpace(cfg.AppStoreBundleID)
	verifier.defaultEnv = strings.TrimSpace(strings.ToLower(cfg.AppStoreEnv))

	if verifier.defaultEnv == "" {
		verifier.defaultEnv = "production"
	}

	if keyPath := strings.TrimSpace(cfg.AppStoreKeyPath); keyPath != "" {
		privateKey, err := loadAppStorePrivateKey(keyPath)
		if err == nil {
			verifier.privateKey = privateKey
		}
	}

	return verifier
}

func (v *appleVerifier) isConfigured() bool {
	return v != nil &&
		v.privateKey != nil &&
		v.issuerID != "" &&
		v.keyID != "" &&
		v.bundleID != ""
}

func (v *appleVerifier) verifyOriginalTransaction(
	ctx context.Context,
	originalTransactionID string,
	envHint string,
) (*appleVerificationResult, error) {
	if !v.isConfigured() {
		return nil, errors.New("app store verifier is not configured")
	}

	originalTransactionID = strings.TrimSpace(originalTransactionID)
	if originalTransactionID == "" {
		return nil, errors.New("original_transaction_id is required")
	}

	var lastErr error
	for _, env := range v.requestEnvironments(envHint) {
		response, err := v.fetchSubscriptions(ctx, originalTransactionID, env)
		if err != nil {
			lastErr = err
			continue
		}

		result, err := pickVerificationResult(response, v.bundleID)
		if err != nil {
			lastErr = err
			continue
		}

		result.Environment = env
		if result.OriginalTransactionID == "" {
			result.OriginalTransactionID = originalTransactionID
		}
		return result, nil
	}

	if lastErr == nil {
		lastErr = errors.New("apple verification failed")
	}
	return nil, lastErr
}

func (v *appleVerifier) requestEnvironments(envHint string) []string {
	preferred := strings.TrimSpace(strings.ToLower(envHint))
	if preferred == "" {
		preferred = v.defaultEnv
	}
	if preferred != "sandbox" {
		preferred = "production"
	}

	if preferred == "sandbox" {
		return []string{"sandbox", "production"}
	}
	return []string{"production", "sandbox"}
}

func (v *appleVerifier) fetchSubscriptions(
	ctx context.Context,
	originalTransactionID string,
	environment string,
) (*appleSubscriptionsResponse, error) {
	baseURL := v.prodBaseURL
	if environment == "sandbox" {
		baseURL = v.sbxBaseURL
	}

	endpoint := strings.TrimRight(baseURL, "/") + "/inApps/v1/subscriptions/" + url.PathEscape(originalTransactionID)
	token, err := v.signedJWT(time.Now().UTC())
	if err != nil {
		return nil, fmt.Errorf("create app store jwt: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Accept", "application/json")

	resp, err := v.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("call app store api: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("app store api %d (%s): %s", resp.StatusCode, environment, strings.TrimSpace(string(body)))
	}

	var parsed appleSubscriptionsResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("decode app store response: %w", err)
	}

	return &parsed, nil
}

func (v *appleVerifier) signedJWT(now time.Time) (string, error) {
	header := map[string]string{
		"alg": "ES256",
		"kid": v.keyID,
		"typ": "JWT",
	}

	claims := map[string]any{
		"iss": v.issuerID,
		"iat": now.Unix(),
		"exp": now.Add(20 * time.Minute).Unix(),
		"aud": "appstoreconnect-v1",
		"bid": v.bundleID,
	}

	headerJSON, _ := json.Marshal(header)
	claimsJSON, _ := json.Marshal(claims)

	encodedHeader := base64.RawURLEncoding.EncodeToString(headerJSON)
	encodedClaims := base64.RawURLEncoding.EncodeToString(claimsJSON)
	signingInput := encodedHeader + "." + encodedClaims

	hash := sha256.Sum256([]byte(signingInput))
	signature, err := ecdsa.SignASN1(rand.Reader, v.privateKey, hash[:])
	if err != nil {
		return "", err
	}

	return signingInput + "." + base64.RawURLEncoding.EncodeToString(signature), nil
}

func pickVerificationResult(
	response *appleSubscriptionsResponse,
	expectedBundleID string,
) (*appleVerificationResult, error) {
	if response == nil {
		return nil, errors.New("empty app store response")
	}

	now := time.Now().UTC()
	var best *appleVerificationResult
	var bestSort verificationSort

	for _, group := range response.Data {
		for _, tx := range group.LastTransactions {
			payload, err := parseSignedTransactionPayload(tx.SignedTransactionInfo)
			if err != nil {
				continue
			}

			if expectedBundleID != "" && payload.BundleID != "" && !strings.EqualFold(payload.BundleID, expectedBundleID) {
				continue
			}

			expiresAt := millisToTimePtr(payload.ExpiresDate)
			revoked := payload.RevocationDate > 0

			activeByStatus := group.Status == 1 || group.Status == 3 || group.Status == 4 ||
				tx.Status == 1 || tx.Status == 3 || tx.Status == 4
			activeByExpiry := expiresAt != nil && expiresAt.After(now)
			active := !revoked && (activeByStatus || activeByExpiry)

			result := &appleVerificationResult{
				OriginalTransactionID: firstNonEmpty(payload.OriginalTransactionID, tx.OriginalTransactionID),
				ProductID:             strings.TrimSpace(payload.ProductID),
				ExpiresAt:             expiresAt,
				Active:                active,
			}

			sortKey := verificationSort{
				active:       active,
				expiresAt:    expiresAt,
				purchaseDate: payload.PurchaseDate,
			}

			if best == nil || sortKey.isBetterThan(bestSort) {
				best = result
				bestSort = sortKey
			}
		}
	}

	if best == nil {
		return nil, errors.New("no verifiable transaction found in app store response")
	}

	return best, nil
}

type verificationSort struct {
	active       bool
	expiresAt    *time.Time
	purchaseDate int64
}

func (v verificationSort) isBetterThan(other verificationSort) bool {
	if v.active != other.active {
		return v.active
	}

	if compareTimePtr(v.expiresAt, other.expiresAt) != 0 {
		return compareTimePtr(v.expiresAt, other.expiresAt) > 0
	}

	return v.purchaseDate > other.purchaseDate
}

func compareTimePtr(left, right *time.Time) int {
	switch {
	case left == nil && right == nil:
		return 0
	case left != nil && right == nil:
		return 1
	case left == nil && right != nil:
		return -1
	default:
		if left.After(*right) {
			return 1
		}
		if left.Before(*right) {
			return -1
		}
		return 0
	}
}

func parseSignedTransactionPayload(signed string) (*signedTransactionPayload, error) {
	parts := strings.Split(strings.TrimSpace(signed), ".")
	if len(parts) < 2 {
		return nil, errors.New("invalid signed transaction info")
	}

	payloadBytes, err := decodeBase64URL(parts[1])
	if err != nil {
		return nil, fmt.Errorf("decode signed payload: %w", err)
	}

	var payload signedTransactionPayload
	if err := json.Unmarshal(payloadBytes, &payload); err != nil {
		return nil, fmt.Errorf("parse signed payload: %w", err)
	}

	return &payload, nil
}

func decodeBase64URL(value string) ([]byte, error) {
	if decoded, err := base64.RawURLEncoding.DecodeString(value); err == nil {
		return decoded, nil
	}

	padded := value
	if rem := len(value) % 4; rem > 0 {
		padded += strings.Repeat("=", 4-rem)
	}
	return base64.URLEncoding.DecodeString(padded)
}

func millisToTimePtr(ms int64) *time.Time {
	if ms <= 0 {
		return nil
	}
	t := time.UnixMilli(ms).UTC()
	return &t
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func loadAppStorePrivateKey(path string) (*ecdsa.PrivateKey, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read app store private key: %w", err)
	}

	block, _ := pem.Decode(raw)
	if block == nil {
		return nil, errors.New("invalid app store key pem")
	}

	if keyAny, err := x509.ParsePKCS8PrivateKey(block.Bytes); err == nil {
		if key, ok := keyAny.(*ecdsa.PrivateKey); ok {
			return key, nil
		}
	}

	if key, err := x509.ParseECPrivateKey(block.Bytes); err == nil {
		return key, nil
	}

	return nil, errors.New("failed to parse app store private key")
}
