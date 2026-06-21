import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import AdminEditModal from "./AdminEditModal";
import type { Admin } from "@/lib/types";

const target: Admin = {
  id: "a-2",
  name: "Operator",
  phone: "81255550001",
  status: "active",
  role: "admin",
  createdAt: "2026-06-18T12:00:00Z",
};

function renderModal(
  over: { onSaved?: () => void; onClose?: () => void } = {},
) {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <AdminEditModal
        admin={target}
        onClose={over.onClose ?? vi.fn()}
        onSaved={over.onSaved ?? vi.fn()}
      />
    </AuthContext.Provider>,
  );
}

describe("AdminEditModal", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("prefills fields and PATCHes the edited values", async () => {
    let body: unknown;
    const fetchFn = vi.fn(async (_url: string, init?: RequestInit) => {
      body = JSON.parse(String(init?.body));
      return {
        ok: true,
        status: 200,
        json: async () => ({ data: { ...target, name: "Operator Dua" } }),
      } as Response;
    });
    vi.stubGlobal("fetch", fetchFn);
    const onSaved = vi.fn();

    renderModal({ onSaved });
    const nameInput = screen.getByDisplayValue("Operator");
    await userEvent.clear(nameInput);
    await userEvent.type(nameInput, "Operator Dua");
    await userEvent.click(screen.getByRole("button", { name: "Simpan" }));

    await waitFor(() => expect(onSaved).toHaveBeenCalledTimes(1));
    const [url, init] = fetchFn.mock.calls[0];
    expect(url).toContain("/admin/admins/a-2");
    expect(init?.method).toBe("PATCH");
    expect(body).toMatchObject({ name: "Operator Dua", role: "admin" });
  });

  it("surfaces a backend error and does not close", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: false,
        status: 409,
        json: async () => ({ error: { message: "Nomor HP sudah terdaftar" } }),
      })),
    );
    const onClose = vi.fn();

    renderModal({ onClose });
    await userEvent.click(screen.getByRole("button", { name: "Simpan" }));

    expect(await screen.findByText(/sudah terdaftar/)).toBeInTheDocument();
    expect(onClose).not.toHaveBeenCalled();
  });
});
