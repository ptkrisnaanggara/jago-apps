// App-wide configuration sourced from Vite env vars (all must be VITE_*).

/**
 * Default backend base URL shown on the login form. The client appends
 * `/api/v1`. Override with `VITE_API_BASE_URL`.
 */
export const DEFAULT_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8080";

/**
 * The accepted OTP code for the demo login. Override with `VITE_DEMO_OTP`.
 * Mirrors the mobile app / backend demo code (`123456`).
 */
export const DEMO_OTP = import.meta.env.VITE_DEMO_OTP ?? "123456";
