import { useEffect, useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import type { Admin } from "@/lib/types";
import { useAuth } from "@/context/auth";

interface Props {
  admin: Admin;
  onClose: () => void;
  onSaved: () => void;
}

// AdminEditModal edits an admin's name, phone, and role. The signed-in admin
// cannot demote their own role, so the role field is locked on the self row.
export default function AdminEditModal({ admin, onClose, onSaved }: Props) {
  const { creds, admin: current } = useAuth();
  const isSelf = admin.id === current?.id;

  const [name, setName] = useState(admin.name);
  const [phone, setPhone] = useState(admin.phone);
  const [role, setRole] = useState(admin.role);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSaving(true);
    try {
      await api.updateAdmin(creds, admin.id, { name, phone, role });
      onSaved();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal menyimpan.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <header className="modal-head">
          <h2>Ubah Admin</h2>
          <button className="ghost" onClick={onClose} aria-label="Tutup">
            ✕
          </button>
        </header>

        <form className="modal-form" onSubmit={handleSubmit}>
          <label>
            Nama
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </label>

          <label>
            Nomor HP
            <input
              type="tel"
              inputMode="numeric"
              value={phone}
              onChange={(e) => setPhone(e.target.value.replace(/[^\d]/g, ""))}
              required
            />
          </label>

          <label>
            Peran
            <select
              value={role}
              onChange={(e) => setRole(e.target.value)}
              disabled={isSelf}
              title={isSelf ? "Tidak dapat mengubah peran sendiri" : ""}
            >
              <option value="admin">admin</option>
              <option value="superadmin">superadmin</option>
            </select>
          </label>

          {error && <p className="error">{error}</p>}

          <div className="modal-actions">
            <button type="button" className="ghost" onClick={onClose}>
              Batal
            </button>
            <button type="submit" disabled={saving || phone.length < 6}>
              {saving ? "Menyimpan…" : "Simpan"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
