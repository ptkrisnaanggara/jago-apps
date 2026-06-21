import { useCallback, useEffect, useState } from "react";
import { NavLink, Outlet } from "react-router-dom";
import { api } from "@/lib/api";
import type { Stats } from "@/lib/types";
import { formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";

// DashboardShell wraps the list routes (Users / Transactions / Pools) with the
// headline stat cards and the tab navigation, which stay put as you switch tabs.
export default function DashboardShell() {
  const { creds, admin } = useAuth();
  const isSuperadmin = admin?.role === "superadmin";
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadStats = useCallback(() => {
    setError(null);
    api
      .stats(creds)
      .then(setStats)
      .catch((err: unknown) => {
        if (err instanceof Error) setError(err.message);
      });
  }, [creds]);

  useEffect(() => {
    loadStats();
  }, [loadStats]);

  return (
    <>
      {error && <p className="error banner">{error}</p>}

      <section className="cards">
        <StatCard label="Pengguna" value={stats?.users} />
        <StatCard label="Kartu" value={stats?.cards} />
        <StatCard label="Kantong" value={stats?.pockets} />
        <StatCard label="Transaksi" value={stats?.transactions} />
        <StatCard label="Transfer" value={stats?.transfers} />
        <StatCard label="Patungan" value={stats?.pools} />
        <StatCard
          label="Total Saldo Rekening"
          value={stats ? formatRupiah(stats.totalBalance) : undefined}
          wide
        />
        <StatCard
          label="Total Saldo Kantong"
          value={stats ? formatRupiah(stats.pocketBalance) : undefined}
          wide
        />
      </section>

      <nav className="tabs">
        <NavLink to="/" end>
          Pengguna
        </NavLink>
        <NavLink to="/transactions">Transaksi</NavLink>
        <NavLink to="/pools">Patungan</NavLink>
        <NavLink to="/charts">Grafik</NavLink>
        <NavLink to="/notifications">Notifikasi</NavLink>
        {isSuperadmin && <NavLink to="/admins">Admin</NavLink>}
        {isSuperadmin && <NavLink to="/audit">Audit</NavLink>}
      </nav>

      <Outlet />
    </>
  );
}

function StatCard({
  label,
  value,
  wide,
}: {
  label: string;
  value: number | string | undefined;
  wide?: boolean;
}) {
  return (
    <div className={`card${wide ? " card-wide" : ""}`}>
      <span className="card-label">{label}</span>
      <span className="card-value">{value ?? "—"}</span>
    </div>
  );
}
