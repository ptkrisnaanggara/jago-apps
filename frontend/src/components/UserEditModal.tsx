import { useEffect, useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import { useAuth } from "@/context/auth";

interface Props {
  userId: string;
  initialName: string;
  initialPhone: string;
  onClose: () => void;
  onSaved: () => void;
}

// UserEditModal edits a customer's name and phone (phone stays unique).
export default function UserEditModal({
  userId,
  initialName,
  initialPhone,
  onClose,
  onSaved,
}: Props) {
  const { creds } = useAuth();
  const [name, setName] = useState(initialName);
  const [phone, setPhone] = useState(initialPhone);
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
      await api.updateUser(creds, userId, { name, phone });
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
          <h2>Ubah Pengguna</h2>
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
