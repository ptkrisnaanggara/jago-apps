import { useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import { DEFAULT_BASE_URL, DEMO_OTP } from "@/lib/config";
import { saveCredentials, type Credentials } from "@/lib/credentials";
import Logo from "@/components/Logo";

interface Props {
  onAuthenticated: (creds: Credentials) => void;
}

type Step = "credentials" | "otp";

// Login is a two-step flow: (1) verify the Base URL + Admin Key against the API,
// then (2) confirm a one-time code. The demo OTP is 123456 (see VITE_DEMO_OTP).
export default function Login({ onAuthenticated }: Props) {
  const [step, setStep] = useState<Step>("credentials");
  const [baseUrl, setBaseUrl] = useState(DEFAULT_BASE_URL);
  const [adminKey, setAdminKey] = useState("");
  const [otp, setOtp] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleCredentials(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      // A successful stats call validates both the URL and the key before we
      // move on to the OTP step.
      await api.stats({ baseUrl, adminKey });
      setStep("otp");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login gagal.");
    } finally {
      setLoading(false);
    }
  }

  function handleOtp(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (otp.trim() !== DEMO_OTP) {
      setError("Kode OTP salah. Coba lagi.");
      return;
    }
    const creds: Credentials = { baseUrl, adminKey };
    saveCredentials(creds);
    onAuthenticated(creds);
  }

  function backToCredentials() {
    setStep("credentials");
    setOtp("");
    setError(null);
  }

  return (
    <div className="login">
      {step === "credentials" ? (
        <form className="login-card" onSubmit={handleCredentials}>
          <div className="brand">
            <Logo height={32} className="brand-logo" />
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
            {loading ? "Menghubungkan…" : "Kirim OTP"}
          </button>

          <p className="hint">
            Gunakan <code>ADMIN_API_KEY</code> dari backend (default{" "}
            <code>admin-secret</code>).
          </p>
        </form>
      ) : (
        <form className="login-card" onSubmit={handleOtp}>
          <div className="brand">
            <Logo height={32} className="brand-logo" />
            <span className="brand-sub">Verifikasi OTP</span>
          </div>

          <p className="muted otp-intro">
            Masukkan 6 digit kode OTP untuk masuk.
          </p>

          <label>
            Kode OTP
            <input
              className="otp-input"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              value={otp}
              onChange={(e) =>
                setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))
              }
              placeholder="••••••"
              autoFocus
              required
            />
          </label>

          {error && <p className="error">{error}</p>}

          <button type="submit" disabled={otp.length < 6}>
            Verifikasi
          </button>

          <button
            type="button"
            className="link-button"
            onClick={backToCredentials}
          >
            ← Kembali
          </button>

          <p className="hint">
            Demo: gunakan kode <code>{DEMO_OTP}</code>.
          </p>
        </form>
      )}
    </div>
  );
}
