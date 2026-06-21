import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import UserEditModal from "./UserEditModal";

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
      <UserEditModal
        userId="u-1"
        initialName="Nasabah"
        initialPhone="81200001111"
        initialKyc="none"
        initialStatus="active"
        onClose={over.onClose ?? vi.fn()}
        onSaved={over.onSaved ?? vi.fn()}
      />
    </AuthContext.Provider>,
  );
}

describe("UserEditModal", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("PATCHes the edited name and calls onSaved", async () => {
    let body: unknown;
    const fetchFn = vi.fn(async (_url: string, init?: RequestInit) => {
      body = JSON.parse(String(init?.body));
      return {
        ok: true,
        status: 200,
        json: async () => ({ data: { id: "u-1", name: "Baru", phone: "8" } }),
      } as Response;
    });
    vi.stubGlobal("fetch", fetchFn);
    const onSaved = vi.fn();

    renderModal({ onSaved });
    const nameInput = screen.getByDisplayValue("Nasabah");
    await userEvent.clear(nameInput);
    await userEvent.type(nameInput, "Nasabah Baru");
    await userEvent.click(screen.getByRole("button", { name: "Simpan" }));

    await waitFor(() => expect(onSaved).toHaveBeenCalledTimes(1));
    const [url, init] = fetchFn.mock.calls[0];
    expect(url).toContain("/admin/users/u-1");
    expect(init?.method).toBe("PATCH");
    expect(body).toMatchObject({
      name: "Nasabah Baru",
      kycStatus: "none",
      status: "active",
    });
  });

  it("submits an updated KYC + access status", async () => {
    let body: unknown;
    const fetchFn = vi.fn(async (_url: string, init?: RequestInit) => {
      body = JSON.parse(String(init?.body));
      return {
        ok: true,
        status: 200,
        json: async () => ({
          data: { id: "u-1", name: "Nasabah", phone: "8" },
        }),
      } as Response;
    });
    vi.stubGlobal("fetch", fetchFn);
    const onSaved = vi.fn();

    renderModal({ onSaved });
    await userEvent.selectOptions(
      screen.getByDisplayValue("Belum KYC"),
      "verified",
    );
    await userEvent.selectOptions(screen.getByDisplayValue("Aktif"), "blocked");
    await userEvent.click(screen.getByRole("button", { name: "Simpan" }));

    await waitFor(() => expect(onSaved).toHaveBeenCalledTimes(1));
    expect(body).toMatchObject({ kycStatus: "verified", status: "blocked" });
  });

  it("surfaces a duplicate-phone error and stays open", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: false,
        status: 409,
        json: async () => ({ error: { message: "Nomor HP sudah digunakan" } }),
      })),
    );
    const onClose = vi.fn();

    renderModal({ onClose });
    await userEvent.click(screen.getByRole("button", { name: "Simpan" }));

    expect(await screen.findByText(/sudah digunakan/)).toBeInTheDocument();
    expect(onClose).not.toHaveBeenCalled();
  });
});
