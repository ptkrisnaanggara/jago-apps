import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Login from "./Login";

type Json = Record<string, unknown>;

// Queues fetch responses in call order (request OTP, then verify OTP).
function queueFetch(
  ...responses: { ok: boolean; status?: number; body: Json }[]
) {
  let i = 0;
  vi.stubGlobal(
    "fetch",
    vi.fn(async () => {
      const r = responses[Math.min(i, responses.length - 1)];
      i += 1;
      return {
        ok: r.ok,
        status: r.status ?? (r.ok ? 200 : 400),
        json: async () => r.body,
      } as Response;
    }),
  );
}

describe("Login (phone + OTP)", () => {
  beforeEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });
  afterEach(() => vi.unstubAllGlobals());

  it("renders the phone field first", () => {
    render(<Login onAuthenticated={vi.fn()} />);
    expect(screen.getByText("Nomor HP Admin")).toBeInTheDocument();
  });

  it("shows an error and stays on step 1 for an unregistered phone", async () => {
    queueFetch({
      ok: false,
      status: 401,
      body: { error: { message: "Nomor tidak terdaftar sebagai admin" } },
    });
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(
      screen.getByPlaceholderText("81200000000"),
      "89999999999",
    );
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));

    expect(await screen.findByText(/tidak terdaftar/)).toBeInTheDocument();
    expect(screen.getByText("Nomor HP Admin")).toBeInTheDocument();
    expect(onAuth).not.toHaveBeenCalled();
  });

  it("advances to OTP after the code is requested (no auth yet)", async () => {
    queueFetch({ ok: true, body: { data: { demoCode: "123456" } } });
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(
      screen.getByPlaceholderText("81200000000"),
      "81200000000",
    );
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));

    expect(await screen.findByText("Kode OTP")).toBeInTheDocument();
    expect(onAuth).not.toHaveBeenCalled();
  });

  it("verifies the OTP and authenticates with the returned token", async () => {
    queueFetch(
      { ok: true, body: { data: { demoCode: "123456" } } },
      { ok: true, body: { data: { token: "jwt-xyz", admin: { name: "A" } } } },
    );
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(
      screen.getByPlaceholderText("81200000000"),
      "81200000000",
    );
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));
    await userEvent.type(
      await screen.findByPlaceholderText("••••••"),
      "123456",
    );
    await userEvent.click(screen.getByRole("button", { name: "Verifikasi" }));

    await waitFor(() => expect(onAuth).toHaveBeenCalledTimes(1));
    expect(onAuth.mock.calls[0][0]).toMatchObject({ token: "jwt-xyz" });
    expect(localStorage.getItem("jago.admin.credentials")).toContain("jwt-xyz");
  });

  it("rejects a wrong OTP", async () => {
    queueFetch(
      { ok: true, body: { data: { demoCode: "123456" } } },
      {
        ok: false,
        status: 401,
        body: { error: { message: "Invalid OTP code" } },
      },
    );
    const onAuth = vi.fn();
    render(<Login onAuthenticated={onAuth} />);

    await userEvent.type(
      screen.getByPlaceholderText("81200000000"),
      "81200000000",
    );
    await userEvent.click(screen.getByRole("button", { name: "Kirim OTP" }));
    await userEvent.type(
      await screen.findByPlaceholderText("••••••"),
      "000000",
    );
    await userEvent.click(screen.getByRole("button", { name: "Verifikasi" }));

    expect(await screen.findByText(/Invalid OTP/)).toBeInTheDocument();
    expect(onAuth).not.toHaveBeenCalled();
  });
});
