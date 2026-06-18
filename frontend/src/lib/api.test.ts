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

  it("trims surrounding whitespace", () => {
    expect(normalizeBase("  http://host  ")).toBe("http://host/api/v1");
  });
});

describe("api client", () => {
  const creds: Credentials = {
    baseUrl: "http://localhost:8080",
    adminKey: "secret",
  };

  beforeEach(() => {
    vi.restoreAllMocks();
  });
  afterEach(() => {
    vi.unstubAllGlobals();
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

  it("sends the admin key header and unwraps {data}", async () => {
    const fetchFn = mockFetch(200, { data: { users: 3 } });
    const stats = await api.stats(creds);

    expect(stats).toEqual({ users: 3 });
    const [url, init] = fetchFn.mock.calls[0];
    expect(url).toBe("http://localhost:8080/api/v1/admin/stats");
    expect(init?.headers).toMatchObject({
      "X-Admin-Key": "secret",
    });
  });

  it("maps a 401 to a friendly message", async () => {
    mockFetch(401, {});
    await expect(api.stats(creds)).rejects.toThrow(/Admin key/);
  });

  it("surfaces the backend error message on non-2xx", async () => {
    mockFetch(500, { error: { code: "internal", message: "boom" } });
    await expect(api.stats(creds)).rejects.toThrow("boom");
  });

  it("builds the transactions query with a type filter", async () => {
    const fetchFn = mockFetch(200, { data: [], meta: {} });
    await api.transactions(creds, 2, 20, "expense");

    const [url] = fetchFn.mock.calls[0];
    expect(url).toContain("/admin/transactions?");
    expect(url).toContain("page=2");
    expect(url).toContain("type=expense");
  });

  it("omits the type param when filter is empty", async () => {
    const fetchFn = mockFetch(200, { data: [], meta: {} });
    await api.transactions(creds, 1, 20, "");

    const [url] = fetchFn.mock.calls[0];
    expect(url).not.toContain("type=");
  });
});
