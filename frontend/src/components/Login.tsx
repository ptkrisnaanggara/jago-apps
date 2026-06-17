import { useState, type FormEvent } from "react";
import { api, saveCredentials, type Credentials } from "../api";

interface Props {
  onAuthenticated: (creds: Credentials) => void;
}

// Login captures the API base URL + admin key, verifies them against
// /admin/stats, and on success persists them and hands control to the app.
export default function Login({ onAuthenticated }: Props) {
  const [baseUrl, setBaseUrl] = useState("http://localhost:8080");
  const [adminKey, setAdminKey] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    const creds: Credentials = { baseUrl, adminKey };
    try {
      // A successful stats call validates both the URL and the key.
      await api.stats(creds);
      saveCredentials(creds);
      onAuthenticated(creds);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login gagal.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login">
      <form className="login-card" onSubmit={handleSubmit}>
        <div className="brand">
          <span className="brand-mark">JAGO</span>
          <span className="brand-sub">Admin Dashboard</span>
        </div>

        <label>
          Base URL
          <input
            type="text"
            value={baseUrl}
            onChange={(e) => setBaseUrl(e.target.value)}
            placeholder="http://localhost:8080"
            autoComplete="off"
            required
          />
        </label>

        <label>
          Admin Key
          <input
            type="password"
            value={adminKey}
            onChange={(e) => setAdminKey(e.target.value)}
            placeholder="X-Admin-Key"
            autoComplete="off"
            required
          />
        </label>

        {error && <p className="error">{error}</p>}

        <button type="submit" disabled={loading}>
          {loading ? "Menghubungkan…" : "Masuk"}
        </button>

        <p className="hint">
          Gunakan <code>ADMIN_API_KEY</code> dari backend (default{" "}
          <code>admin-secret</code>).
        </p>
      </form>
    </div>
  );
}
