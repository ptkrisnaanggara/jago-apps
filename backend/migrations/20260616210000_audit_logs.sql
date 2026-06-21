-- +goose Up
CREATE TABLE audit_logs (
    id             uuid PRIMARY KEY,
    created_at     timestamptz,
    updated_at     timestamptz,
    deleted_at     timestamptz,
    actor_admin_id text,
    actor_name     text,
    action         text,
    target_type    text,
    target_id      text,
    detail         text,
    ip             text
);
CREATE INDEX idx_audit_logs_actor_admin_id ON audit_logs (actor_admin_id);
CREATE INDEX idx_audit_logs_action ON audit_logs (action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at);
CREATE INDEX idx_audit_logs_deleted_at ON audit_logs (deleted_at);

-- +goose Down
DROP TABLE IF EXISTS audit_logs;
