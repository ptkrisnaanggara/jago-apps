// Admin credentials: the API base URL + static admin key. Persisted in
// localStorage so a refresh keeps the operator signed in.

export interface Credentials {
  baseUrl: string;
  adminKey: string;
}

const STORAGE_KEY = "jago.admin.credentials";

export function loadCredentials(): Credentials | null {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Credentials;
  } catch {
    return null;
  }
}

export function saveCredentials(creds: Credentials): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(creds));
}

export function clearCredentials(): void {
  localStorage.removeItem(STORAGE_KEY);
}
