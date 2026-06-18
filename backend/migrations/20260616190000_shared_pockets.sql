-- +goose Up
ALTER TABLE pockets ADD COLUMN shared boolean;
UPDATE pockets SET shared = false;

CREATE TABLE pocket_members (
    id         uuid PRIMARY KEY,
    created_at timestamptz,
    updated_at timestamptz,
    deleted_at timestamptz,
    pocket_id  text NOT NULL,
    user_id    text NOT NULL,
    role       text
);
CREATE INDEX idx_pocket_members_pocket_id ON pocket_members (pocket_id);
CREATE INDEX idx_pocket_members_user_id ON pocket_members (user_id);
CREATE INDEX idx_pocket_members_deleted_at ON pocket_members (deleted_at);

-- +goose Down
DROP TABLE IF EXISTS pocket_members;
ALTER TABLE pockets DROP COLUMN shared;
