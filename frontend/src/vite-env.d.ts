/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Default backend base URL for the login form (e.g. http://localhost:8080). */
  readonly VITE_API_BASE_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
