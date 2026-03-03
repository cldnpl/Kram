package main

import (
	"log"

	"mathquest/backend/config"
	"mathquest/backend/internal/middleware"
	"mathquest/backend/internal/router"
	"mathquest/backend/pkg/database"
	redispkg "mathquest/backend/pkg/redis"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	redis "github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config load: %v", err)
	}

	// Initialize database (optional: only if DATABASE_URL is set)
	var db *gorm.DB
	if cfg.DatabaseURL != "" {
		var err error
		db, err = database.NewPostgres(cfg.DatabaseURL)
		if err != nil {
			log.Printf("warning: database connection failed: %v", err)
			db = nil
		}
	} else {
		log.Printf("database: skipped (no DATABASE_URL)")
	}

	// Initialize Redis (optional: only if REDIS_URL is set)
	var redisClient *redis.Client
	if cfg.RedisURL != "" {
		var err error
		redisClient, err = redispkg.NewClient(cfg.RedisURL)
		if err != nil {
			log.Printf("warning: redis connection failed: %v", err)
			redisClient = nil
		}
	} else {
		log.Printf("redis: skipped (no REDIS_URL)")
	}

	app := fiber.New(fiber.Config{
		ErrorHandler: middleware.ErrorHandler,
	})

	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(func(c *fiber.Ctx) error {
		log.Printf("[REQ] %s %s", c.Method(), c.Path())
		return c.Next()
	})
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	router.Setup(app, cfg, db, redisClient)

	log.Printf("MathQuest API listening on :%s", cfg.Port)
	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Fatalf("listen: %v", err)
	}
}
