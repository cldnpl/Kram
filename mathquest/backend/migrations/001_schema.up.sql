-- Users
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    age INT,
    math_level VARCHAR(50),
    coin_balance INT DEFAULT 0,
    streak_days INT DEFAULT 0,
    last_active TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Lessons
CREATE TABLE IF NOT EXISTS lessons (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    difficulty INT,
    coin_cost INT NOT NULL,
    coin_reward INT NOT NULL,
    order_index INT DEFAULT 0,
    content_json JSONB
);

-- Exercises
CREATE TABLE IF NOT EXISTS exercises (
    id BIGSERIAL PRIMARY KEY,
    lesson_id BIGINT REFERENCES lessons(id),
    question TEXT NOT NULL,
    type VARCHAR(50),
    options_json JSONB,
    correct_answer TEXT,
    xp_reward INT DEFAULT 0
);

-- User Progress
CREATE TABLE IF NOT EXISTS user_lessons (
    user_id BIGINT REFERENCES users(id),
    lesson_id BIGINT REFERENCES lessons(id),
    status VARCHAR(20) DEFAULT 'locked',
    completed_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, lesson_id)
);

CREATE TABLE IF NOT EXISTS user_exercises (
    user_id BIGINT REFERENCES users(id),
    exercise_id BIGINT REFERENCES exercises(id),
    is_correct BOOLEAN,
    submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Coin Transactions
CREATE TABLE IF NOT EXISTS coin_transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    amount INT NOT NULL,
    type VARCHAR(50),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily Rewards
CREATE TABLE IF NOT EXISTS daily_rewards (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    claimed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Camera Usage (persistenza; limite giornaliero in Redis)
CREATE TABLE IF NOT EXISTS camera_usage (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    used_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reward Tasks
CREATE TABLE IF NOT EXISTS reward_tasks (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    title VARCHAR(255),
    description TEXT,
    coin_reward INT NOT NULL,
    is_repeatable BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS user_reward_tasks (
    user_id BIGINT REFERENCES users(id),
    task_id BIGINT REFERENCES reward_tasks(id),
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, task_id)
);

-- Invite System
CREATE TABLE IF NOT EXISTS invites (
    id BIGSERIAL PRIMARY KEY,
    inviter_user_id BIGINT REFERENCES users(id),
    code VARCHAR(20) UNIQUE NOT NULL,
    redeemed_by_user_id BIGINT REFERENCES users(id),
    redeemed_at TIMESTAMPTZ
);

-- Store
CREATE TABLE IF NOT EXISTS store_items (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    coin_cost INT NOT NULL,
    item_type VARCHAR(50),
    metadata_json JSONB
);

CREATE TABLE IF NOT EXISTS user_purchases (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    item_id BIGINT REFERENCES store_items(id),
    purchased_at TIMESTAMPTZ DEFAULT NOW()
);
