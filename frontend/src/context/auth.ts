import { createContext, useContext } from "react";
import type { Credentials } from "@/lib/credentials";
import type { AdminInfo } from "@/lib/types";

export interface AuthContextValue {
  creds: Credentials;
  /** The signed-in admin's profile (null until /admin/me resolves). */
  admin: AdminInfo | null;
  logout: () => void;
}

/**
 * Holds the authenticated admin credentials + logout for the whole app tree, so
 * routed pages can read them without prop-drilling. Only mounted once the user
 * has signed in, so the value is always present inside the dashboard.
 */
export const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within an AuthContext provider");
  }
  return ctx;
}
