ALTER TABLE camera_solutions
    ADD COLUMN IF NOT EXISTS share_token VARCHAR(64),
    ADD COLUMN IF NOT EXISTS shared_at TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS idx_camera_solutions_share_token
    ON camera_solutions(share_token)
    WHERE share_token IS NOT NULL;
