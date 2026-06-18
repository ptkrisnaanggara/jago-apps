// Thin client for the JAGO backend admin API. Admin endpoints authenticate
// with a static key in the X-Admin-Key header (no JWT).

import type { Credentials } from "./credentials";
import type {
  AdminPool,
  AdminTransaction,
  AdminUser,
  Card,
  Page,
  Stats,
  TxFilter,
  UserDetail,
} from "./types";

/**
 * Normalize a base URL: trim trailing slashes and append the `/api/v1` path the
 * backend mounts its routes under when it is not already present. Exported for
 * unit testing.
 */
export function normalizeBase(baseUrl: string): string {
  let b = baseUrl.trim().replace(/\/+$/, "");
  if (!/\/api\/v1$/.test(b)) {
    b = `${b}/api/v1`;
  }
  return b;
}

async function request<T>(
  creds: Credentials,
  path: string,
  init?: RequestInit,
): Promise<T> {
  const url = `${normalizeBase(creds.baseUrl)}${path}`;
  let res: Response;
  try {
    res = await fetch(url, {
      ...init,
      headers: {
        "X-Admin-Key": creds.adminKey,
        ...(init?.body ? { "Content-Type": "application/json" } : {}),
        ...init?.headers,
      },
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

const qs = (params: Record<string, string | number>): string =>
  Object.entries(params)
    .filter(([, v]) => v !== "")
    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
    .join("&");

export const api = {
  stats: (creds: Credentials) =>
    request<{ data: Stats }>(creds, "/admin/stats").then((r) => r.data),

  users: (creds: Credentials, page = 1, limit = 20) =>
    request<Page<AdminUser>>(creds, `/admin/users?${qs({ page, limit })}`),

  user: (creds: Credentials, id: string) =>
    request<{ data: UserDetail }>(creds, `/admin/users/${id}`).then(
      (r) => r.data,
    ),

  transactions: (
    creds: Credentials,
    page = 1,
    limit = 20,
    type: TxFilter = "",
  ) =>
    request<Page<AdminTransaction>>(
      creds,
      `/admin/transactions?${qs({ page, limit, type })}`,
    ),

  pools: (creds: Credentials, page = 1, limit = 20) =>
    request<Page<AdminPool>>(creds, `/admin/pools?${qs({ page, limit })}`),

  freezeCard: (creds: Credentials, cardId: string, frozen: boolean) =>
    request<{ data: Card }>(creds, `/admin/cards/${cardId}/freeze`, {
      method: "POST",
      body: JSON.stringify({ frozen }),
    }).then((r) => r.data),
};
