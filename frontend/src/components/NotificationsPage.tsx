import { useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import { useAuth } from "@/context/auth";

const CATEGORIES: { value: string; label: string }[] = [
  { value: "info", label: "Info" },
  { value: "promo", label: "Promo" },
  { value: "security", label: "Keamanan" },
];

// NotificationsPage broadcasts an in-app notification to all users.
export default function NotificationsPage() {
  const { creds } = useAuth();
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [category, setCategory] = useState("info");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<number | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setResult(null);
    setSending(true);
    try {
      const { count } = await api.sendNotification(creds, {
        title,
        body,
        category,
      });
      setResult(count);
      setTitle("");
      setBody("");
      setCategory("info");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal mengirim.");
    } finally {
      setSending(false);
    }
  }

  return (
    <section className="chart-card compose-card">
      <h3>Kirim Notifikasi ke Semua Pengguna</h3>

      <form className="modal-form" onSubmit={handleSubmit}>
        <label>
          Judul
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="mis. Promo Spesial"
            maxLength={80}
            required
          />
        </label>

        <label>
          Isi Pesan
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Tulis pesan notifikasi…"
            rows={4}
            maxLength={500}
            required
          />
        </label>

        <label>
          Kategori
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
          >
            {CATEGORIES.map((c) => (
              <option key={c.value} value={c.value}>
                {c.label}
              </option>
            ))}
          </select>
        </label>

        {error && <p className="error">{error}</p>}
        {result !== null && (
          <p className="preview">Terkirim ke {result} pengguna.</p>
        )}

        <div className="modal-actions">
          <button
            type="submit"
            disabled={sending || !title.trim() || !body.trim()}
          >
            {sending ? "Mengirim…" : "Kirim ke Semua"}
          </button>
        </div>
      </form>
    </section>
  );
}
