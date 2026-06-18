import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { AuthContext } from "@/context/auth";
import UsersTable from "./UsersTable";

function renderWithRouter() {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", adminKey: "k" },
        logout: vi.fn(),
      }}
    >
      <MemoryRouter initialEntries={["/"]}>
        <Routes>
          <Route path="/" element={<UsersTable />} />
          <Route path="/users/:id" element={<div>Detail Page</div>} />
        </Routes>
      </MemoryRouter>
    </AuthContext.Provider>,
  );
}

describe("UsersTable", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        status: 200,
        json: async () => ({
          data: [
            {
              id: "u-1",
              name: "Nasabah Jago",
              phone: "8120001",
              accountNumber: "100 1",
              balance: 12750000,
              createdAt: "2026-06-17T08:19:48Z",
            },
          ],
          meta: { page: 1, limit: 20, total: 1, totalPages: 1 },
        }),
      })),
    );
  });
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("renders a user row and navigates to the detail page on click", async () => {
    renderWithRouter();

    const row = await screen.findByText("Nasabah Jago");
    await userEvent.click(row);

    await waitFor(() =>
      expect(screen.getByText("Detail Page")).toBeInTheDocument(),
    );
  });
});
