// Thin client for the JAGO backend admin API. Admin endpoints authenticate
// with a static key in the X-Admin-Key header (no JWT). The base URL + key are
// supplied by the user at login and persisted in localStorage.

export interface Stats {
  users: number;
  accounts: number;
  pockets: number;
  cards: number;
  transactions: number;
  transfers: number;
  bills: number;
  pools: number;
  totalBalance: number;
  pocketBalance: number;
}

export interface AdminUser {
  id: string;
  name: string;
  phone: string;
  accountNumber: string;
  balance: number;
  createdAt: string;
}

export interface AdminTransaction {
  id: string;
  userId: string;
  userName: string;
  title: string;
  category: string;
  amount: number;
  type: "income" | "expense";
  createdAt: string;
}

export interface Meta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Page<T> {
  data: T[];
  meta: Meta;
}

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

// Normalize a base URL: trim a trailing slash; default to the /api/v1 path the
// backend mounts its routes under when none is given.
function normalizeBase(baseUrl: string): string {
  let b = baseUrl.trim().replace(/\/+$/, "");
  if (!/\/api\/v1$/.test(b)) {
    b = `${b}/api/v1`;
  }
  return b;
}

async function request<T>(creds: Credentials, path: string): Promise<T> {
  const url = `${normalizeBase(creds.baseUrl)}${path}`;
  let res: Response;
  try {
    res = await fetch(url, {
      headers: { "X-Admin-Key": creds.adminKey },
    });
  } catch {
    throw new Error("Tidak dapat terhubung ke server. Periksa Base URL.");
  }

  if (res.status === 401) {
    throw new Error("Admin key salah atau tidak ada.");
  }
  if (!res.ok) {
    let message = `Permintaan gagal (${res.status}).`;
    try {
      const body = (await res.json()) as { error?: { message?: string } };
      if (body.error?.message) message = body.error.message;
    } catch {
      // keep the default message
    }
    throw new Error(message);
  }
  return (await res.json()) as T;
}

export const api = {
  stats: (creds: Credentials) =>
    request<{ data: Stats }>(creds, "/admin/stats").then((r) => r.data),

  users: (creds: Credentials, page = 1, limit = 20) =>
    request<Page<AdminUser>>(creds, `/admin/users?page=${page}&limit=${limit}`),

  transactions: (creds: Credentials, page = 1, limit = 20) =>
    request<Page<AdminTransaction>>(
      creds,
      `/admin/transactions?page=${page}&limit=${limit}`,
    ),
};
