

CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token_name TEXT NOT NULL UNIQUE,
    expire_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked BOOLEAN DEFAULT false
);

