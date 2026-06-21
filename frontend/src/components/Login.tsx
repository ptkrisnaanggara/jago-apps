import { useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import { DEFAULT_BASE_URL } from "@/lib/config";
import { saveCredentials, type Credentials } from "@/lib/credentials";
import Logo from "@/components/Logo";

interface Props {
  onAuthenticated: (creds: Credentials) => void;
}

type Step = "phone" | "otp";

// Login is a phone + OTP flow: (1) the admin enters their phone and we ask the
// backend to send a one-time code over WhatsApp (WAHA); (2) they enter the code
// to receive a bearer token. The demo backend accepts 123456.
export default function Login({ onAuthenticated }: Props) {
  const [step, setStep] = useState<Step>("phone");
  const [baseUrl, setBaseUrl] = useState(DEFAULT_BASE_URL);
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [demoCode, setDemoCode] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handlePhone(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await api.requestOtp(baseUrl, phone);
      setDemoCode(res.demoCode ?? null);
      setStep("otp");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Gagal mengirim OTP.");
    } finally {
      setLoading(false);
    }
  }

  async function handleOtp(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const { token } = await api.verifyOtp(baseUrl, phone, otp);
      const creds: Credentials = { baseUrl, token };
      saveCredentials(creds);
      onAuthenticated(creds);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Verifikasi gagal.");
    } finally {
      setLoading(false);
    }
  }

  function backToPhone() {
    setStep("phone");
    setOtp("");
    setError(null);
  }

  return (
    <div className="login">
      {step === "phone" ? (
        <form className="login-card" onSubmit={handlePhone}>
          <div className="brand">
            <Logo height={32} className="brand-logo" />
            <span className="brand-sub">Admin Dashboard</span>
          </div>

          <label>
            Nomor HP Admin
            <input
              type="tel"
              inputMode="numeric"
              value={phone}
              onChange={(e) => setPhone(e.target.value.replace(/[^\d]/g, ""))}
              placeholder="81200000000"
              autoComplete="off"
              autoFocus
              required
            />
          </label>

          <label className="advanced">
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

          {error && <p className="error">{error}</p>}

          <button type="submit" disabled={loading || phone.length < 6}>
            {loading ? "Mengirim…" : "Kirim OTP"}
          </button>

          <p className="hint">
            Kode OTP dikirim ke WhatsApp nomor admin terdaftar.
          </p>
        </form>
      ) : (
        <form className="login-card" onSubmit={handleOtp}>
          <div className="brand">
            <Logo height={32} className="brand-logo" />
            <span className="brand-sub">Verifikasi OTP</span>
          </div>

          <p className="muted otp-intro">
            Masukkan 6 digit kode yang dikirim ke WhatsApp +{phone}.
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

          <button type="submit" disabled={loading || otp.length < 6}>
            {loading ? "Memverifikasi…" : "Verifikasi"}
          </button>

          <button type="button" className="link-button" onClick={backToPhone}>
            ← Ganti nomor
          </button>

          {demoCode && (
            <p className="hint">
              Demo: gunakan kode <code>{demoCode}</code>.
            </p>
          )}
        </form>
      )}
    </div>
  );
}
