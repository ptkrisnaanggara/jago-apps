import { useEffect, useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import { formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";

interface Props {
  userId: string;
  userName: string;
  currentBalance: number;
  onClose: () => void;
  onSaved: () => void;
}

// BalanceAdjustModal lets an operator credit or debit a user's balance with a
// required reason. The adjustment is audited and recorded as a transaction.
export default function BalanceAdjustModal({
  userId,
  userName,
  currentBalance,
  onClose,
  onSaved,
}: Props) {
  const { creds } = useAuth();
  const [type, setType] = useState<"credit" | "debit">("credit");
  const [amount, setAmount] = useState("");
  const [reason, setReason] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const amountNum = Number(amount) || 0;
  const preview =
    type === "credit" ? currentBalance + amountNum : currentBalance - amountNum;
  const overdraw = type === "debit" && amountNum > currentBalance;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSaving(true);
    try {
      await api.adjustBalance(creds, userId, {
        type,
        amount: amountNum,
        reason: reason.trim(),
      });
      onSaved();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Gagal menyesuaikan saldo.",
      );
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
          <h2>Sesuaikan Saldo</h2>
          <button className="ghost" onClick={onClose} aria-label="Tutup">
            ✕
          </button>
        </header>

        <form className="modal-form" onSubmit={handleSubmit}>
          <p className="muted" style={{ margin: 0 }}>
            {userName} · Saldo {formatRupiah(currentBalance)}
          </p>

          <div className="seg">
            <button
              type="button"
              className={`seg-btn${type === "credit" ? " active" : ""}`}
              onClick={() => setType("credit")}
            >
              Kredit (+)
            </button>
            <button
              type="button"
              className={`seg-btn${type === "debit" ? " active" : ""}`}
              onClick={() => setType("debit")}
            >
              Debit (−)
            </button>
          </div>

          <label>
            Jumlah (Rp)
            <input
              type="number"
              min="1"
              inputMode="numeric"
              value={amount}
              onChange={(e) => setAmount(e.target.value.replace(/[^\d]/g, ""))}
              placeholder="0"
              autoFocus
              required
            />
          </label>

          <label>
            Alasan
            <input
              type="text"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="mis. Refund / Koreksi"
              required
            />
          </label>

          {amountNum > 0 && (
            <p className={`muted preview${overdraw ? " over" : ""}`}>
              Saldo baru: {formatRupiah(preview)}
              {overdraw && " — melebihi saldo"}
            </p>
          )}
          {error && <p className="error">{error}</p>}

          <div className="modal-actions">
            <button type="button" className="ghost" onClick={onClose}>
              Batal
            </button>
            <button
              type="submit"
              disabled={saving || amountNum <= 0 || !reason.trim() || overdraw}
            >
              {saving ? "Menyimpan…" : "Simpan"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
