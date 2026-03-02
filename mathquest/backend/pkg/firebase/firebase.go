package firebase

import "context"

// VerifyIDToken verifies the Firebase token and returns the UID
func VerifyIDToken(ctx context.Context, idToken string) (string, error) {
	// TODO: Firebase Admin SDK - InitializeApp + Auth().VerifyIDToken
	return "", nil
}
