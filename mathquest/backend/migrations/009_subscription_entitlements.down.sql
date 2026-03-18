DROP INDEX IF EXISTS idx_users_subscription_original_transaction_id;

ALTER TABLE users DROP COLUMN IF EXISTS subscription_source;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_checked_at;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_expires_at;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_original_transaction_id;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_product_id;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_tier;
