// Thin client for the JAGO backend admin API. The dashboard authenticates with
// a bearer token obtained from the phone + OTP login (api.auth.*).

import type { Credentials } from "./credentials";
import type {
  Admin,
  AdminCard,
  AdminInfo,
  AdminPool,
  AdminTransaction,
  AdminUser,
  AuditLog,
  Card,
  ChartsData,
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

// raw issues a request to `${baseUrl}/api/v1${path}`. Auth/extra headers are
// supplied by the caller; used directly by the public auth endpoints.
async function raw<T>(
  baseUrl: string,
  path: string,
  init?: RequestInit,
): Promise<T> {
  const url = `${normalizeBase(baseUrl)}${path}`;
  let res: Response;
  try {
    res = await fetch(url, {
      ...init,
      headers: {
        ...(init?.body ? { "Content-Type": "application/json" } : {}),
        ...init?.headers,
      },
    });
  } catch {
    throw new Error("Tidak dapat terhubung ke server. Periksa Base URL.");
  }

  if (!res.ok) {
    let message = `Permintaan gagal (${res.status}).`;
    try {
      const body = (await res.json()) as { error?: { message?: string } };
      if (body.error?.message) message = body.error.message;
    } catch {
      // keep the default message
    }
    if (res.status === 401 && message.startsWith("Permintaan gagal")) {
      message = "Sesi tidak valid. Masuk kembali.";
    }
    throw new Error(message);
  }
  return (await res.json()) as T;
}

// request is an authenticated call: attaches the bearer token from creds.
function request<T>(
  creds: Credentials,
  path: string,
  init?: RequestInit,
): Promise<T> {
  return raw<T>(creds.baseUrl, path, {
    ...init,
    headers: {
      Authorization: `Bearer ${creds.token}`,
      ...init?.headers,
    },
  });
}

const qs = (params: Record<string, string | number>): string =>
  Object.entries(params)
    .filter(([, v]) => v !== "")
    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
    .join("&");

export interface OtpRequestResult {
  message: string;
  delivered: boolean;
  demoCode?: string;
}

export interface VerifyResult {
  token: string;
  admin: AdminInfo;
}

export const api = {
  // --- Auth (public: phone + OTP over WhatsApp/WAHA) ---
  requestOtp: (baseUrl: string, phone: string) =>
    raw<{ data: OtpRequestResult }>(baseUrl, "/admin/auth/otp/request", {
      method: "POST",
      body: JSON.stringify({ phone }),
    }).then((r) => r.data),

  verifyOtp: (baseUrl: string, phone: string, code: string) =>
    raw<{ data: VerifyResult }>(baseUrl, "/admin/auth/otp/verify", {
      method: "POST",
      body: JSON.stringify({ phone, code }),
    }).then((r) => r.data),

  // --- Authenticated admin endpoints (bearer token) ---
  me: (creds: Credentials) =>
    request<{ data: AdminInfo }>(creds, "/admin/me").then((r) => r.data),

  stats: (creds: Credentials) =>
    request<{ data: Stats }>(creds, "/admin/stats").then((r) => r.data),

  charts: (creds: Credentials, days = 14) =>
    request<{ data: ChartsData }>(
      creds,
      `/admin/stats/charts?${qs({ days })}`,
    ).then((r) => r.data),

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
    from = "",
    to = "",
  ) =>
    request<Page<AdminTransaction>>(
      creds,
      `/admin/transactions?${qs({ page, limit, type, from, to })}`,
    ),

  pools: (creds: Credentials, page = 1, limit = 20) =>
    request<Page<AdminPool>>(creds, `/admin/pools?${qs({ page, limit })}`),

  cards: (creds: Credentials, page = 1, limit = 20, frozen = "") =>
    request<Page<AdminCard>>(
      creds,
      `/admin/cards?${qs({ page, limit, frozen })}`,
    ),

  auditLogs: (
    creds: Credentials,
    page = 1,
    limit = 20,
    action = "",
    from = "",
    to = "",
  ) =>
    request<Page<AuditLog>>(
      creds,
      `/admin/audit-logs?${qs({ page, limit, action, from, to })}`,
    ),

  updateUser: (
    creds: Credentials,
    id: string,
    input: { name?: string; phone?: string },
  ) =>
    request<{ data: { id: string; name: string; phone: string } }>(
      creds,
      `/admin/users/${id}`,
      { method: "PATCH", body: JSON.stringify(input) },
    ).then((r) => r.data),

  adjustBalance: (
    creds: Credentials,
    id: string,
    input: { type: "credit" | "debit"; amount: number; reason: string },
  ) =>
    request<{ data: { id: string; balance: number } }>(
      creds,
      `/admin/users/${id}/adjust`,
      { method: "POST", body: JSON.stringify(input) },
    ).then((r) => r.data),

  // Fetches a CSV export with auth and returns it as a Blob for download. Any
  // params (type/action/from/to) are forwarded so the export matches the view.
  exportCsv: (
    creds: Credentials,
    kind: "users" | "transactions" | "audit-logs",
    params: Record<string, string> = {},
  ) => {
    const query = qs(params);
    const url = `${normalizeBase(creds.baseUrl)}/admin/export/${kind}${
      query ? `?${query}` : ""
    }`;
    return fetch(url, {
      headers: { Authorization: `Bearer ${creds.token}` },
    }).then((res) => {
      if (!res.ok) throw new Error(`Ekspor gagal (${res.status}).`);
      return res.blob();
    });
  },

  freezeCard: (creds: Credentials, cardId: string, frozen: boolean) =>
    request<{ data: Card }>(creds, `/admin/cards/${cardId}/freeze`, {
      method: "POST",
      body: JSON.stringify({ frozen }),
    }).then((r) => r.data),

  // Sends an in-app notification to one user (userId set) or all users.
  sendNotification: (
    creds: Credentials,
    input: { userId?: string; title: string; body: string; category: string },
  ) =>
    request<{ data: { count: number } }>(creds, "/admin/notifications", {
      method: "POST",
      body: JSON.stringify(input),
    }).then((r) => r.data),

  // --- Admin management (superadmin only) ---
  admins: (creds: Credentials, page = 1, limit = 20) =>
    request<Page<Admin>>(creds, `/admin/admins?${qs({ page, limit })}`),

  createAdmin: (
    creds: Credentials,
    input: { name: string; phone: string; role: string },
  ) =>
    request<{ data: Admin }>(creds, "/admin/admins", {
      method: "POST",
      body: JSON.stringify(input),
    }).then((r) => r.data),

  updateAdmin: (
    creds: Credentials,
    id: string,
    input: { name?: string; phone?: string; role?: string },
  ) =>
    request<{ data: Admin }>(creds, `/admin/admins/${id}`, {
      method: "PATCH",
      body: JSON.stringify(input),
    }).then((r) => r.data),

  setAdminStatus: (
    creds: Credentials,
    id: string,
    status: "active" | "disabled",
  ) =>
    request<{ data: Admin }>(creds, `/admin/admins/${id}/status`, {
      method: "POST",
      body: JSON.stringify({ status }),
    }).then((r) => r.data),
};
