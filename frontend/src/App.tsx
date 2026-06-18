import { useCallback, useMemo, useState } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import {
  clearCredentials,
  loadCredentials,
  type Credentials,
} from "@/lib/credentials";
import { AuthContext } from "@/context/auth";
import Login from "@/components/Login";
import AppLayout from "@/components/AppLayout";
import DashboardShell from "@/components/DashboardShell";
import UsersTable from "@/components/UsersTable";
import TransactionsTable from "@/components/TransactionsTable";
import PoolsTable from "@/components/PoolsTable";
import UserDetailPage from "@/pages/UserDetailPage";

export default function App() {
  const [creds, setCreds] = useState<Credentials | null>(() =>
    loadCredentials(),
  );

  const logout = useCallback(() => {
    clearCredentials();
    setCreds(null);
  }, []);

  const auth = useMemo(
    () => (creds ? { creds, logout } : null),
    [creds, logout],
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
            </Route>
            <Route path="users/:id" element={<UserDetailPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthContext.Provider>
  );
}
