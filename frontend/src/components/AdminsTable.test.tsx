import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import AdminsTable from "./AdminsTable";

const SUPERADMIN = {
  id: "a-1",
  name: "Super Admin",
  phone: "81200000000",
  role: "superadmin",
};

function renderTable() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: SUPERADMIN,
        logout: vi.fn(),
      }}
    >
      <AdminsTable />
    </AuthContext.Provider>,
  );
}

function adminRow(over: Record<string, unknown> = {}) {
  return {
    id: "a-1",
    name: "Super Admin",
    phone: "81200000000",
    status: "active",
    role: "superadmin",
    createdAt: "2026-06-18T12:00:00Z",
    ...over,
  };
}

describe("AdminsTable", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("lists admins and disables the self-row action", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        status: 200,
        json: async () => ({
          data: [adminRow()],
          meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
        }),
      })),
    );
    renderTable();

    expect(await screen.findByText("Super Admin")).toBeInTheDocument();
    // The only row is the current admin → its action button is disabled.
    expect(screen.getByRole("button", { name: "Nonaktifkan" })).toBeDisabled();
  });

  it("creates an admin and refetches the list", async () => {
    const calls: string[] = [];
    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string, init?: RequestInit) => {
        calls.push(`${init?.method ?? "GET"} ${url}`);
        const isCreate = init?.method === "POST";
        return {
          ok: true,
          status: isCreate ? 201 : 200,
          json: async () =>
            isCreate
              ? {
                  data: adminRow({
                    id: "a-2",
                    name: "Operator",
                    phone: "8125",
                  }),
                }
              : {
                  data: [adminRow()],
                  meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
                },
        } as Response;
      }),
    );
    renderTable();
    await screen.findByText("Super Admin");

    await userEvent.type(screen.getByPlaceholderText("Nama"), "Operator");
    await userEvent.type(
      screen.getByPlaceholderText(/Nomor HP/),
      "81255550001",
    );
    await userEvent.click(screen.getByRole("button", { name: "Tambah Admin" }));

    await waitFor(() =>
      expect(
        calls.some((c) => c.startsWith("POST") && c.includes("/admin/admins")),
      ).toBe(true),
    );
    // A refetch (GET) happens after the create.
    await waitFor(() =>
      expect(calls.filter((c) => c.startsWith("GET")).length).toBeGreaterThan(
        1,
      ),
    );
  });
});
