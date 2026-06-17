-- +goose Up
CREATE TABLE money_pools (
    id            uuid PRIMARY KEY,
    created_at    timestamptz,
    updated_at    timestamptz,
    deleted_at    timestamptz,
    owner_user_id text NOT NULL,
    title         text,
    target        bigint,
    collected     bigint,
    status        text
);
CREATE INDEX idx_money_pools_owner_user_id ON money_pools (owner_user_id);
CREATE INDEX idx_money_pools_deleted_at ON money_pools (deleted_at);

CREATE TABLE pool_contributions (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    pool_id    text NOT NULL,
    name       text,
    amount     bigint
);
CREATE INDEX idx_pool_contributions_pool_id ON pool_contributions (pool_id);
CREATE INDEX idx_pool_contributions_deleted_at ON pool_contributions (deleted_at);

-- +goose Down
DROP TABLE IF EXISTS pool_contributions;
DROP TABLE IF EXISTS money_pools;
