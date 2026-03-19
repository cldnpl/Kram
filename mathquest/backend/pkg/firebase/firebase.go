package firebase

import (
	"context"
	"log"
	"sync"

	firebaseAdmin "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

var (
	authClient *auth.Client
	once       sync.Once
)

// Init initializes the Firebase Admin SDK with the given credentials file.
func Init(credentialsPath string) {
	once.Do(func() {
		if credentialsPath == "" {
			log.Println("[Firebase] no credentials path — token verification disabled")
			return
		}

		ctx := context.Background()
		app, err := firebaseAdmin.NewApp(ctx, nil, option.WithCredentialsFile(credentialsPath))
		if err != nil {
			log.Printf("[Firebase] failed to initialize app: %v", err)
			return
		}

		client, err := app.Auth(ctx)
		if err != nil {
			log.Printf("[Firebase] failed to get auth client: %v", err)
			return
		}

		authClient = client
		log.Println("[Firebase] initialized successfully")
	})
}

// VerifyIDToken verifies the Firebase ID token and returns the UID.
func VerifyIDToken(ctx context.Context, idToken string) (string, error) {
	if authClient == nil {
		return "", nil
	}

	token, err := authClient.VerifyIDToken(ctx, idToken)
	if err != nil {
		return "", err
	}

	return token.UID, nil
}
