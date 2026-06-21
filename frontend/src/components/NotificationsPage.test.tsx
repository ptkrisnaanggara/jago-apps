import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import NotificationsPage from "./NotificationsPage";

function renderPage() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <NotificationsPage />
    </AuthContext.Provider>,
  );
}

describe("NotificationsPage", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("broadcasts a notification and shows the recipient count", async () => {
    let body: unknown;
    const fetchFn = vi.fn(async (_url: string, init?: RequestInit) => {
      body = JSON.parse(String(init?.body));
      return {
        ok: true,
        status: 200,
        json: async () => ({ data: { count: 20 } }),
      } as Response;
    });
    vi.stubGlobal("fetch", fetchFn);

    renderPage();
    await userEvent.type(
      screen.getByPlaceholderText("mis. Promo Spesial"),
      "Promo",
    );
    await userEvent.type(
      screen.getByPlaceholderText("Tulis pesan notifikasi…"),
      "Diskon 50%",
    );
    await userEvent.selectOptions(screen.getByDisplayValue("Info"), "promo");
    await userEvent.click(
      screen.getByRole("button", { name: "Kirim ke Semua" }),
    );

    expect(await screen.findByText(/Terkirim ke 20 pengguna/)).toBeVisible();
    const [url, init] = fetchFn.mock.calls[0];
    expect(url).toContain("/admin/notifications");
    expect(init?.method).toBe("POST");
    expect(body).toMatchObject({
      title: "Promo",
      body: "Diskon 50%",
      category: "promo",
    });
  });
});
