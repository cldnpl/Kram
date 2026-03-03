-- Camera Solutions History
CREATE TABLE camera_solutions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    original_problem TEXT NOT NULL,
    solution TEXT NOT NULL,
    steps_json JSONB NOT NULL,
    raw_latex TEXT,
    difficulty_level VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_camera_solutions_user ON camera_solutions(user_id, created_at DESC);
