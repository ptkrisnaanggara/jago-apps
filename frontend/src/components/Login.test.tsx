import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Login from "./Login";

function mockFetch(ok: boolean, status = ok ? 200 : 401) {
  vi.stubGlobal(
    "fetch",
    vi.fn(async () => ({
      ok,
      status,
      json: async () => (ok ? { data: { users: 1 } } : {}),
    })),
  );
}

describe("Login", () => {
  beforeEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("renders base URL and admin key fields first", () => {
    render(<Login onAuthenticated={vi.fn()} />);
    expect(screen.getByText("Base URL")).toBeInTheDocument();
    expect(screen.getByText("Admin Key")).toBeInTheDocument();
  });

  it("shows an error and stays on step 1 for a bad key", async () => {
    mockFetch(false);
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(screen.getByPlaceholderText("X-Admin-Key"), "wrong");
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));

    expect(await screen.findByText(/Admin key/)).toBeInTheDocument();
    expect(screen.getByText("Admin Key")).toBeInTheDocument();
    expect(onAuth).not.toHaveBeenCalled();
  });

  it("advances to the OTP step after a valid key (no auth yet)", async () => {
    mockFetch(true);
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(screen.getByPlaceholderText("X-Admin-Key"), "secret");
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));

    expect(await screen.findByText("Kode OTP")).toBeInTheDocument();
    expect(onAuth).not.toHaveBeenCalled();
  });

  it("rejects a wrong OTP", async () => {
    mockFetch(true);
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(screen.getByPlaceholderText("X-Admin-Key"), "secret");
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));
    await userEvent.type(
      await screen.findByPlaceholderText("••••••"),
      "000000",
    );
    await userEvent.click(screen.getByRole("button", { name: "Verifikasi" }));

    expect(await screen.findByText(/Kode OTP salah/)).toBeInTheDocument();
    expect(onAuth).not.toHaveBeenCalled();
  });

  it("authenticates with the demo OTP 123456", async () => {
    mockFetch(true);
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(screen.getByPlaceholderText("X-Admin-Key"), "secret");
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));
    await userEvent.type(
      await screen.findByPlaceholderText("••••••"),
      "123456",
    );
    await userEvent.click(screen.getByRole("button", { name: "Verifikasi" }));

    await waitFor(() => expect(onAuth).toHaveBeenCalledTimes(1));
    expect(onAuth.mock.calls[0][0]).toMatchObject({ adminKey: "secret" });
    expect(localStorage.getItem("jago.admin.credentials")).toContain("secret");
  });
});
