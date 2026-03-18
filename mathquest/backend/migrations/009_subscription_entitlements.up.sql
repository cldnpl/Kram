ALTER TABLE users
    ADD COLUMN IF NOT EXISTS subscription_tier VARCHAR(32) NOT NULL DEFAULT 'free';

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS subscription_product_id VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS subscription_original_transaction_id VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS subscription_checked_at TIMESTAMPTZ;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS subscription_source VARCHAR(32) NOT NULL DEFAULT 'none';

CREATE INDEX IF NOT EXISTS idx_users_subscription_original_transaction_id
    ON users (subscription_original_transaction_id);
