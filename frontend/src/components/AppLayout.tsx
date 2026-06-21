import { Link, Outlet } from "react-router-dom";
import { useAuth } from "@/context/auth";
import Logo from "@/components/Logo";

// AppLayout is the persistent chrome (brand topbar + signed-in admin + sign-out)
// shared by every authenticated page; the active route renders into <Outlet />.
export default function AppLayout() {
  const { admin, logout } = useAuth();
  return (
    <div className="app">
      <header className="topbar">
        <Link to="/" className="brand" aria-label="Beranda">
          <Logo height={26} className="brand-logo" />
          <span className="brand-sub">Admin</span>
        </Link>
        <div className="topbar-actions">
          {admin && (
            <span className="admin-id" title={admin.phone}>
              {admin.name}
              <span className="chip">{admin.role}</span>
            </span>
          )}
          <button className="ghost" onClick={logout}>
            Keluar
          </button>
        </div>
      </header>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
