CREATE TABLE IF NOT EXISTS ios_live_activity_devices (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(64) NOT NULL UNIQUE,
    push_to_start_token TEXT NOT NULL DEFAULT '',
    timezone_name VARCHAR(128) NOT NULL DEFAULT 'UTC',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    last_warning_local_day VARCHAR(10) NOT NULL DEFAULT '',
    last_warning_sent_at TIMESTAMPTZ,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ios_live_activity_devices_user_id
    ON ios_live_activity_devices(user_id);
