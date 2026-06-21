import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { api, normalizeBase } from "./api";
import type { Credentials } from "./credentials";

describe("normalizeBase", () => {
  it("appends /api/v1 when missing", () => {
    expect(normalizeBase("http://localhost:8080")).toBe(
      "http://localhost:8080/api/v1",
    );
  });

  it("trims trailing slashes before appending", () => {
    expect(normalizeBase("http://localhost:8080///")).toBe(
      "http://localhost:8080/api/v1",
    );
  });

  it("leaves an already-suffixed URL unchanged", () => {
    expect(normalizeBase("https://api.example.com/api/v1")).toBe(
      "https://api.example.com/api/v1",
    );
  });
});

function mockFetch(status: number, body: unknown) {
  const fn = vi.fn((_url: string, _init?: RequestInit) =>
    Promise.resolve({
      ok: status >= 200 && status < 300,
      status,
      json: async () => body,
    } as Response),
  );
  vi.stubGlobal("fetch", fn);
  return fn;
}

describe("api auth endpoints", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("posts the phone to request an OTP", async () => {
    const fetchFn = mockFetch(200, {
      data: { message: "OTP sent", delivered: false, demoCode: "123456" },
    });
    const res = await api.requestOtp("http://localhost:8080", "81200000000");

    expect(res.demoCode).toBe("123456");
    const [url, init] = fetchFn.mock.calls[0];
    expect(url).toBe("http://localhost:8080/api/v1/admin/auth/otp/request");
    expect(init?.method).toBe("POST");
    expect(JSON.parse(String(init?.body))).toEqual({ phone: "81200000000" });
  });

  it("verifies an OTP and returns a token", async () => {
    mockFetch(200, {
      data: { token: "jwt-123", admin: { name: "Super Admin", role: "x" } },
    });
    const res = await api.verifyOtp("http://localhost:8080", "812", "123456");
    expect(res.token).toBe("jwt-123");
  });

  it("surfaces the backend error message", async () => {
    mockFetch(401, {
      error: { code: "unauthorized", message: "Nomor tidak terdaftar" },
    });
    await expect(
      api.requestOtp("http://localhost:8080", "000"),
    ).rejects.toThrow("Nomor tidak terdaftar");
  });
});

describe("api authenticated requests", () => {
  const creds: Credentials = {
    baseUrl: "http://localhost:8080",
    token: "jwt-abc",
  };

  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("attaches the bearer token and unwraps {data}", async () => {
    const fetchFn = mockFetch(200, { data: { users: 3 } });
    const stats = await api.stats(creds);

    expect(stats).toEqual({ users: 3 });
    const [url, init] = fetchFn.mock.calls[0];
    expect(url).toBe("http://localhost:8080/api/v1/admin/stats");
    expect(init?.headers).toMatchObject({ Authorization: "Bearer jwt-abc" });
  });

  it("builds the transactions query with a type filter", async () => {
    const fetchFn = mockFetch(200, { data: [], meta: {} });
    await api.transactions(creds, 2, 20, "expense");

    const [url] = fetchFn.mock.calls[0];
    expect(url).toContain("page=2");
    expect(url).toContain("type=expense");
  });

  it("omits the type param when the filter is empty", async () => {
    const fetchFn = mockFetch(200, { data: [], meta: {} });
    await api.transactions(creds, 1, 20, "");
    expect(fetchFn.mock.calls[0][0]).not.toContain("type=");
  });

  it("includes from/to date range when provided", async () => {
    const fetchFn = mockFetch(200, { data: [], meta: {} });
    await api.transactions(creds, 1, 20, "", "2026-06-01", "2026-06-15");
    const [url] = fetchFn.mock.calls[0];
    expect(url).toContain("from=2026-06-01");
    expect(url).toContain("to=2026-06-15");
  });

  it("forwards filters to a CSV export URL", async () => {
    const fetchFn = vi.fn(async (_url: string) => ({
      ok: true,
      status: 200,
      blob: async () => new Blob(["csv"]),
    }));
    vi.stubGlobal("fetch", fetchFn);

    await api.exportCsv(creds, "transactions", {
      type: "income",
      from: "2026-06-01",
      to: "",
    });
    const [url] = fetchFn.mock.calls[0];
    expect(url).toContain("/admin/export/transactions?");
    expect(url).toContain("type=income");
    expect(url).toContain("from=2026-06-01");
    expect(url).not.toContain("to="); // empty values are dropped
  });
});
