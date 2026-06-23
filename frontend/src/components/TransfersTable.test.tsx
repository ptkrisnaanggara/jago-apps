import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen } from "@testing-library/react";
import { AuthContext } from "@/context/auth";
import TransfersTable from "./TransfersTable";

function renderTable() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <TransfersTable />
    </AuthContext.Provider>,
  );
}

describe("TransfersTable", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("lists transfers with sender, recipient, and reference", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        status: 200,
        json: async () => ({
          data: [
            {
              id: "t-1",
              userId: "u-1",
              userName: "Nasabah",
              recipientName: "Budi",
              recipientBank: "BCA",
              recipientAccount: "123",
              amount: 50000,
              note: "lunch",
              referenceId: "JG12345678",
              createdAt: "2026-06-22T10:00:00Z",
            },
          ],
          meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
        }),
      })),
    );

    renderTable();
    expect(await screen.findByText("Budi")).toBeInTheDocument();
    expect(screen.getByText("Nasabah")).toBeInTheDocument();
    expect(screen.getByText("JG12345678")).toBeInTheDocument();
  });
});
