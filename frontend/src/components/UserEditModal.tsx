import { useEffect, useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import type { KycStatus, UserStatus } from "@/lib/types";
import {
  KYC_LABELS,
  KYC_OPTIONS,
  STATUS_LABELS,
  STATUS_OPTIONS,
} from "@/lib/userStatus";
import { useAuth } from "@/context/auth";

interface Props {
  userId: string;
  initialName: string;
  initialPhone: string;
  initialKyc: KycStatus;
  initialStatus: UserStatus;
  onClose: () => void;
  onSaved: () => void;
}

// UserEditModal edits a customer's name, phone, KYC status, and access status.
export default function UserEditModal({
  userId,
  initialName,
  initialPhone,
  initialKyc,
  initialStatus,
  onClose,
  onSaved,
}: Props) {
  const { creds } = useAuth();
  const [name, setName] = useState(initialName);
  const [phone, setPhone] = useState(initialPhone);
  const [kycStatus, setKycStatus] = useState<KycStatus>(initialKyc);
  const [status, setStatus] = useState<UserStatus>(initialStatus);
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
      await api.updateUser(creds, userId, { name, phone, kycStatus, status });
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

          <label>
            Status KYC
            <select
              value={kycStatus}
              onChange={(e) => setKycStatus(e.target.value as KycStatus)}
            >
              {KYC_OPTIONS.map((k) => (
                <option key={k} value={k}>
                  {KYC_LABELS[k]}
                </option>
              ))}
            </select>
          </label>

          <label>
            Status Akun
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value as UserStatus)}
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {STATUS_LABELS[s]}
                </option>
              ))}
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
