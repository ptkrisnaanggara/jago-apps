-- +goose Up
ALTER TABLE pockets ADD COLUMN type text;
UPDATE pockets SET type = CASE WHEN is_main THEN 'main' ELSE 'saving' END;

-- +goose Down
ALTER TABLE pockets DROP COLUMN type;
