-- +goose Up
ALTER TABLE pockets ADD COLUMN locked boolean;
ALTER TABLE pockets ADD COLUMN lock_until timestamptz;
ALTER TABLE pockets ADD COLUMN autosave_amount bigint;
ALTER TABLE pockets ADD COLUMN autosave_frequency text;
UPDATE pockets SET locked = false, autosave_amount = 0, autosave_frequency = 'none';

-- +goose Down
ALTER TABLE pockets DROP COLUMN autosave_frequency;
ALTER TABLE pockets DROP COLUMN autosave_amount;
ALTER TABLE pockets DROP COLUMN lock_until;
ALTER TABLE pockets DROP COLUMN locked;
