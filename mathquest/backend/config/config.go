package config

import (
	"os"
	"path/filepath"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Port             string
	DatabaseURL      string
	RedisURL         string
	FirebaseCred     string
	MathPixKey       string
	Env              string
	ClaudeAPIKey     string
	CameraDailyLimit int
}

func Load() (*Config, error) {
	loadEnvFiles()

	dailyLimit, _ := strconv.Atoi(getEnv("CAMERA_DAILY_LIMIT", "5"))

	return &Config{
		Port:             getEnv("PORT", "8080"),
		DatabaseURL:      getEnv("DATABASE_URL", ""),
		RedisURL:         getEnv("REDIS_URL", ""),
		FirebaseCred:     getEnv("FIREBASE_CREDENTIALS_PATH", ""),
		MathPixKey:       getEnv("MATHPIX_API_KEY", ""),
		Env:              getEnv("ENV", "development"),
		ClaudeAPIKey:     getEnv("CLAUDE_API_KEY", ""),
		CameraDailyLimit: dailyLimit,
	}, nil
}

func loadEnvFiles() {
	candidates := []string{
		".env",
		filepath.Join("backend", ".env"),
		filepath.Join("..", ".env"),
	}

	for _, path := range candidates {
		if _, err := os.Stat(path); err == nil {
			_ = godotenv.Load(path)
			return
		}
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
