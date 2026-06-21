import { useCallback, useEffect, useMemo, useState } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { api } from "@/lib/api";
import {
  clearCredentials,
  loadCredentials,
  type Credentials,
} from "@/lib/credentials";
import type { AdminInfo } from "@/lib/types";
import { AuthContext } from "@/context/auth";
import Login from "@/components/Login";
import AppLayout from "@/components/AppLayout";
import DashboardShell from "@/components/DashboardShell";
import UsersTable from "@/components/UsersTable";
import TransactionsTable from "@/components/TransactionsTable";
import PoolsTable from "@/components/PoolsTable";
import ChartsPage from "@/components/ChartsPage";
import NotificationsPage from "@/components/NotificationsPage";
import AdminsTable from "@/components/AdminsTable";
import AuditTable from "@/components/AuditTable";
import UserDetailPage from "@/pages/UserDetailPage";

export default function App() {
  const [creds, setCreds] = useState<Credentials | null>(() =>
    loadCredentials(),
  );
  const [admin, setAdmin] = useState<AdminInfo | null>(null);

  const logout = useCallback(() => {
    clearCredentials();
    setCreds(null);
    setAdmin(null);
  }, []);

  // Resolve the signed-in admin once per session. A failure here is treated as
  // an invalid/expired token, so we sign out.
  useEffect(() => {
    if (!creds) return;
    let active = true;
    api
      .me(creds)
      .then((a) => {
        if (active) setAdmin(a);
      })
      .catch(() => {
        if (active) logout();
      });
    return () => {
      active = false;
    };
  }, [creds, logout]);

  const auth = useMemo(
    () => (creds ? { creds, admin, logout } : null),
    [creds, admin, logout],
  );

  if (!auth) {
    return <Login onAuthenticated={setCreds} />;
  }

  return (
    <AuthContext.Provider value={auth}>
      <BrowserRouter>
        <Routes>
          <Route element={<AppLayout />}>
            <Route element={<DashboardShell />}>
              <Route index element={<UsersTable />} />
              <Route path="transactions" element={<TransactionsTable />} />
              <Route path="pools" element={<PoolsTable />} />
              <Route path="charts" element={<ChartsPage />} />
              <Route path="notifications" element={<NotificationsPage />} />
              <Route path="admins" element={<AdminsTable />} />
              <Route path="audit" element={<AuditTable />} />
            </Route>
            <Route path="users/:id" element={<UserDetailPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthContext.Provider>
  );
}
