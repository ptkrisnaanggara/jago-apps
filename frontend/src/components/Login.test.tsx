import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Login from "./Login";

describe("Login", () => {
  beforeEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("renders base URL and admin key fields", () => {
    render(<Login onAuthenticated={vi.fn()} />);
    expect(screen.getByText("Base URL")).toBeInTheDocument();
    expect(screen.getByText("Admin Key")).toBeInTheDocument();
  });

  it("verifies credentials and calls onAuthenticated on success", async () => {
    const fetchFn = vi.fn(async () => ({
      ok: true,
      status: 200,
      json: async () => ({ data: { users: 1 } }),
    }));
    vi.stubGlobal("fetch", fetchFn);
    const onAuth = vi.fn();

    render(<Login onAuthenticated={onAuth} />);
    await userEvent.type(screen.getByPlaceholderText("X-Admin-Key"), "secret");
    await userEvent.click(screen.getByRole("button", { name: "Masuk" }));

    await waitFor(() => expect(onAuth).toHaveBeenCalledTimes(1));
    expect(onAuth.mock.calls[0][0]).toMatchObject({ adminKey: "secret" });
    expect(localStorage.getItem("jago.admin.credentials")).toContain("secret");
  });

  it("shows an error and does not authenticate on a bad key", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({ ok: false, status: 401, json: async () => ({}) })),
    );
    const onAuth = vi.fn();

    render(<Login onAuthenticated={onAuth} />);
    await userEvent.type(screen.getByPlaceholderText("X-Admin-Key"), "wrong");
    await userEvent.click(screen.getByRole("button", { name: "Masuk" }));

    expect(await screen.findByText(/Admin key/)).toBeInTheDocument();
    expect(onAuth).not.toHaveBeenCalled();
  });
});
