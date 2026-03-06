-- Usernames per registrazione (univoci)
CREATE TABLE IF NOT EXISTS usernames (
    username VARCHAR(100) UNIQUE NOT NULL PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
