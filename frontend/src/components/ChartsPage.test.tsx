import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen } from "@testing-library/react";
import { AuthContext } from "@/context/auth";
import ChartsPage from "./ChartsPage";

function renderPage() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <ChartsPage />
    </AuthContext.Provider>,
  );
}

describe("ChartsPage", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("renders totals and top categories from the charts API", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        status: 200,
        json: async () => ({
          data: {
            days: 7,
            daily: [
              { date: "2026-06-20", income: 1000, expense: 400 },
              { date: "2026-06-21", income: 0, expense: 600 },
            ],
            topCategories: [
              { category: "Makan & Minum", total: 560000, count: 20 },
            ],
          },
        }),
      })),
    );
    renderPage();

    expect(await screen.findByText("Arus Kas Harian")).toBeInTheDocument();
    expect(
      screen.getByText("Kategori Pengeluaran Teratas"),
    ).toBeInTheDocument();
    expect(screen.getByText("Makan & Minum")).toBeInTheDocument();
    // Income total = 1000 (Rp1.000); just assert a category total renders.
    expect(screen.getByText(/560\.000/)).toBeInTheDocument();
  });
});
