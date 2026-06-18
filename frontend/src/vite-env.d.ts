/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Default backend base URL for the login form (e.g. http://localhost:8080). */
  readonly VITE_API_BASE_URL?: string;
  /** Accepted OTP code for the demo login (defaults to 123456). */
  readonly VITE_DEMO_OTP?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
