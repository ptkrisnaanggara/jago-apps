import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthContext } from "@/context/auth";
import BalanceAdjustModal from "./BalanceAdjustModal";

function renderModal(over: { onSaved?: () => void } = {}) {
  return render(
    <AuthContext.Provider
      value={{
        creds: { baseUrl: "http://localhost:8080", token: "t" },
        admin: { id: "a-1", name: "Super", phone: "8120", role: "superadmin" },
        logout: vi.fn(),
      }}
    >
      <BalanceAdjustModal
        userId="u-1"
        userName="Nasabah"
        currentBalance={1000000}
        onClose={vi.fn()}
        onSaved={over.onSaved ?? vi.fn()}
      />
    </AuthContext.Provider>,
  );
}

describe("BalanceAdjustModal", () => {
  beforeEach(() => vi.restoreAllMocks());
  afterEach(() => vi.unstubAllGlobals());

  it("posts a credit adjustment with reason", async () => {
    let body: unknown;
    const fetchFn = vi.fn(async (_url: string, init?: RequestInit) => {
      body = JSON.parse(String(init?.body));
      return {
        ok: true,
        status: 200,
        json: async () => ({ data: { id: "u-1", balance: 1250000 } }),
      } as Response;
    });
    vi.stubGlobal("fetch", fetchFn);
    const onSaved = vi.fn();

    renderModal({ onSaved });
    await userEvent.type(screen.getByPlaceholderText("0"), "250000");
    await userEvent.type(
      screen.getByPlaceholderText("mis. Refund / Koreksi"),
      "Refund",
    );
    await userEvent.click(screen.getByRole("button", { name: "Simpan" }));

    await waitFor(() => expect(onSaved).toHaveBeenCalledTimes(1));
    const [url, init] = fetchFn.mock.calls[0];
    expect(url).toContain("/admin/users/u-1/adjust");
    expect(init?.method).toBe("POST");
    expect(body).toMatchObject({
      type: "credit",
      amount: 250000,
      reason: "Refund",
    });
  });

  it("blocks a debit that exceeds the balance", async () => {
    renderModal();
    await userEvent.click(screen.getByRole("button", { name: "Debit (−)" }));
    await userEvent.type(screen.getByPlaceholderText("0"), "9999999");
    await userEvent.type(
      screen.getByPlaceholderText("mis. Refund / Koreksi"),
      "x",
    );

    expect(screen.getByText(/melebihi saldo/)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Simpan" })).toBeDisabled();
  });
});
