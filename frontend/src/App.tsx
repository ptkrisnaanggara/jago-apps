import { useCallback, useState } from "react";
import {
  clearCredentials,
  loadCredentials,
  type Credentials,
} from "@/lib/credentials";
import Login from "@/components/Login";
import Dashboard from "@/components/Dashboard";

export default function App() {
  const [creds, setCreds] = useState<Credentials | null>(() =>
    loadCredentials(),
  );

  const handleLogout = useCallback(() => {
    clearCredentials();
    setCreds(null);
  }, []);

  if (!creds) {
    return <Login onAuthenticated={setCreds} />;
  }
  return <Dashboard creds={creds} onLogout={handleLogout} />;
}
