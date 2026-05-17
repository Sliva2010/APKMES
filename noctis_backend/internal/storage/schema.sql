-- NOCTIS MVP schema. Idempotent.
-- Real migrations (goose) will replace this file as the project grows.

CREATE TABLE IF NOT EXISTS users (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid            UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    phone_e164      TEXT UNIQUE,
    display_name    TEXT NOT NULL DEFAULT '',
    username        TEXT UNIQUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sessions (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_hash    BYTEA NOT NULL UNIQUE,
    user_agent      TEXT,
    ip_inet         INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_active_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_sessions_user_active
    ON sessions(user_id) WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS chats (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid            UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    kind            TEXT NOT NULL DEFAULT 'direct',
    title           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chat_members (
    chat_id         BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_up_to_seq  BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY(chat_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    chat_id             BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    seq                 BIGINT NOT NULL,
    sender_id           BIGINT NOT NULL REFERENCES users(id),
    client_message_id   UUID NOT NULL,
    body_text           TEXT,
    edited_at           TIMESTAMPTZ,
    deleted_for_all_at  TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(chat_id, seq),
    UNIQUE(chat_id, sender_id, client_message_id)
);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id_id
    ON messages(chat_id, id DESC);
