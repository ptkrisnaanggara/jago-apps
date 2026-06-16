-- +goose Up
-- Initial schema. Column names/types match what GORM expects for the models in
-- internal/model (snake_case, uuid PKs, bigint Rupiah, timestamptz, soft-delete).

CREATE TABLE users (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    name       text NOT NULL,
    phone      text NOT NULL
);
CREATE UNIQUE INDEX idx_users_phone ON users (phone);
CREATE INDEX idx_users_deleted_at ON users (deleted_at);

CREATE TABLE accounts (
    id             uuid PRIMARY KEY,
    created_at     timestamptz,
    updated_at     timestamptz,
    deleted_at     timestamptz,
    user_id        text NOT NULL,
    holder_name    text,
    account_number text,
    balance        bigint
);
CREATE UNIQUE INDEX idx_accounts_user_id ON accounts (user_id);
CREATE INDEX idx_accounts_deleted_at ON accounts (deleted_at);

CREATE TABLE pockets (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    user_id    text NOT NULL,
    name       text,
    balance    bigint,
    target     bigint,
    is_main    boolean
);
CREATE INDEX idx_pockets_user_id ON pockets (user_id);
CREATE INDEX idx_pockets_deleted_at ON pockets (deleted_at);

CREATE TABLE transactions (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    user_id    text NOT NULL,
    title      text,
    category   text,
    amount     bigint,
    type       text
);
CREATE INDEX idx_transactions_user_id ON transactions (user_id);
CREATE INDEX idx_transactions_deleted_at ON transactions (deleted_at);

CREATE TABLE transfers (
    id                uuid PRIMARY KEY,
    created_at        timestamptz,
    updated_at        timestamptz,
    deleted_at        timestamptz,
    user_id           text NOT NULL,
    recipient_name    text,
    recipient_bank    text,
    recipient_account text,
    amount            bigint,
    note              text,
    reference_id      text
);
CREATE INDEX idx_transfers_user_id ON transfers (user_id);
CREATE UNIQUE INDEX idx_transfers_reference_id ON transfers (reference_id);
CREATE INDEX idx_transfers_deleted_at ON transfers (deleted_at);

CREATE TABLE bills (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    user_id    text NOT NULL,
    biller     text,
    category   text,
    amount     bigint,
    due_date   timestamptz,
    is_paid    boolean,
    recurrence text
);
CREATE INDEX idx_bills_user_id ON bills (user_id);
CREATE INDEX idx_bills_deleted_at ON bills (deleted_at);

CREATE TABLE cards (
    id          uuid PRIMARY KEY,
    created_at  timestamptz,
    updated_at  timestamptz,
    deleted_at  timestamptz,
    user_id     text NOT NULL,
    label       text,
    number      text,
    holder_name text,
    expiry      text,
    cvv         text,
    type        text,
    is_frozen   boolean
);
CREATE INDEX idx_cards_user_id ON cards (user_id);
CREATE INDEX idx_cards_deleted_at ON cards (deleted_at);

CREATE TABLE notifications (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    user_id    text NOT NULL,
    title      text,
    body       text,
    category   text,
    is_read    boolean
);
CREATE INDEX idx_notifications_user_id ON notifications (user_id);
CREATE INDEX idx_notifications_deleted_at ON notifications (deleted_at);

CREATE TABLE contacts (
    id             uuid PRIMARY KEY,
    created_at     timestamptz,
    updated_at     timestamptz,
    deleted_at     timestamptz,
    user_id        text NOT NULL,
    name           text,
    bank_name      text,
    account_number text
);
CREATE INDEX idx_contacts_user_id ON contacts (user_id);
CREATE INDEX idx_contacts_deleted_at ON contacts (deleted_at);

-- +goose Down
DROP TABLE IF EXISTS contacts;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS cards;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS transfers;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS pockets;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS users;
