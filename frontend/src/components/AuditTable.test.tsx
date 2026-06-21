import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen } from "@testing-library/react";
import { AuthContext } from "@/context/auth";
import AuditTable from "./AuditTable";

function renderTable() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <AuditTable />
    </AuthContext.Provider>,
  );
}

describe("AuditTable", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("renders entries with a humanized action label", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        status: 200,
        json: async () => ({
          data: [
            {
              id: "e-1",
              actorAdminId: "a-1",
              actorName: "Super Admin",
              action: "card.freeze",
              targetType: "card",
              targetId: "c-1",
              detail: "Bekukan kartu Kartu Utama",
              ip: "127.0.0.1",
              createdAt: "2026-06-21T05:00:00Z",
            },
          ],
          meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
        }),
      })),
    );
    renderTable();

    expect(await screen.findByText("Super Admin")).toBeInTheDocument();
    // The action code is mapped to a friendly label.
    expect(screen.getByText("Bekukan kartu")).toBeInTheDocument();
    expect(screen.getByText("Bekukan kartu Kartu Utama")).toBeInTheDocument();
    expect(screen.getByText("127.0.0.1")).toBeInTheDocument();
  });
});
