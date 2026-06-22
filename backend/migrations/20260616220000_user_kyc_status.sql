-- +goose Up
ALTER TABLE users ADD COLUMN kyc_status text NOT NULL DEFAULT 'none';
ALTER TABLE users ADD COLUMN status text NOT NULL DEFAULT 'active';

-- +goose Down
ALTER TABLE users DROP COLUMN status;
ALTER TABLE users DROP COLUMN kyc_status;
