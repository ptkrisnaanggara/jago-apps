import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import PocketsTable from "./PocketsTable";

function renderTable() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <PocketsTable />
    </AuthContext.Provider>,
  );
}

const pocket = {
  id: "p-1",
  userId: "u-1",
  userName: "Nasabah",
  name: "Dana Darurat",
  type: "saving",
  balance: 4500000,
  target: 10000000,
  isMain: false,
  locked: true,
  shared: false,
};

describe("PocketsTable", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("lists pockets and applies the type filter", async () => {
    const calls: string[] = [];
    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string) => {
        calls.push(url);
        return {
          ok: true,
          status: 200,
          json: async () => ({
            data: [pocket],
            meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
          }),
        } as Response;
      }),
    );

    renderTable();
    expect(await screen.findByText("Dana Darurat")).toBeInTheDocument();
    expect(screen.getByText("Terkunci")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Nabung" }));
    await waitFor(() =>
      expect(calls.some((u) => u.includes("type=saving"))).toBe(true),
    );
  });
});
