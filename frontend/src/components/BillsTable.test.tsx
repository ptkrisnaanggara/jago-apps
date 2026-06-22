import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import BillsTable from "./BillsTable";

function renderTable() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <BillsTable />
    </AuthContext.Provider>,
  );
}

const bill = {
  id: "b-1",
  userId: "u-1",
  userName: "Nasabah",
  biller: "PLN Pascabayar",
  category: "Listrik",
  amount: 320000,
  dueDate: "2030-06-25T00:00:00Z",
  isPaid: false,
  recurrence: "monthly",
};

describe("BillsTable", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("lists bills and applies the status filter", async () => {
    const calls: string[] = [];
    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string) => {
        calls.push(url);
        return {
          ok: true,
          status: 200,
          json: async () => ({
            data: [bill],
            meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
          }),
        } as Response;
      }),
    );

    renderTable();
    expect(await screen.findByText("PLN Pascabayar")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Lunas" }));
    await waitFor(() =>
      expect(calls.some((u) => u.includes("status=paid"))).toBe(true),
    );
  });
});
