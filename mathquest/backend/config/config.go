package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port         string
	DatabaseURL  string
	RedisURL     string
	FirebaseCred string
	MathPixKey   string
	Env          string
}

func Load() (*Config, error) {
	_ = godotenv.Load()

	return &Config{
		Port:         getEnv("PORT", "8080"),
		DatabaseURL:  getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/mathquest?sslmode=disable"),
		RedisURL:     getEnv("REDIS_URL", "redis://localhost:6379"),
		FirebaseCred: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
		MathPixKey:   getEnv("MATHPIX_API_KEY", ""),
		Env:          getEnv("ENV", "development"),
	}, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
