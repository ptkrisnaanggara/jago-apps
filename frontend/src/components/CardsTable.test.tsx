import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import CardsTable from "./CardsTable";

function renderTable() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <CardsTable />
    </AuthContext.Provider>,
  );
}

const card = {
  id: "c-1",
  userId: "u-1",
  userName: "Nasabah",
  label: "Kartu Utama",
  type: "physical",
  last4: "6789",
  isFrozen: false,
  createdAt: "2026-06-18T12:00:00Z",
};

describe("CardsTable", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("lists cards with a masked PAN and freezes one", async () => {
    const calls: string[] = [];
    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string, init?: RequestInit) => {
        calls.push(`${init?.method ?? "GET"} ${url}`);
        const isFreeze = init?.method === "POST";
        return {
          ok: true,
          status: 200,
          json: async () =>
            isFreeze
              ? { data: { ...card, isFrozen: true } }
              : {
                  data: [card],
                  meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
                },
        } as Response;
      }),
    );

    renderTable();
    expect(await screen.findByText("•••• 6789")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Bekukan" }));

    await waitFor(() =>
      expect(
        calls.some(
          (c) => c.includes("POST") && c.includes("/cards/c-1/freeze"),
        ),
      ).toBe(true),
    );
  });
});
