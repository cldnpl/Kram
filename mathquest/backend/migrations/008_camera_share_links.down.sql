DROP INDEX IF EXISTS idx_camera_solutions_share_token;

ALTER TABLE camera_solutions
    DROP COLUMN IF EXISTS share_token,
    DROP COLUMN IF EXISTS shared_at;
