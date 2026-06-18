-- +goose Up
CREATE TABLE admin_users (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    name       text NOT NULL,
    phone      text NOT NULL,
    status     text NOT NULL DEFAULT 'active',
    role       text
);
CREATE UNIQUE INDEX idx_admin_users_phone ON admin_users (phone);
CREATE INDEX idx_admin_users_deleted_at ON admin_users (deleted_at);

-- +goose Down
DROP TABLE IF EXISTS admin_users;
