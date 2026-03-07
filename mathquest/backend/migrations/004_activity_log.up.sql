CREATE TABLE IF NOT EXISTS activity_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    active_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, active_date)
);

CREATE INDEX IF NOT EXISTS idx_activity_log_user_date ON activity_log (user_id, active_date);
