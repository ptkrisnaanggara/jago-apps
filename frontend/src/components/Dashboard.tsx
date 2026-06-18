import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { Credentials } from "@/lib/credentials";
import type { Stats } from "@/lib/types";
import { formatRupiah } from "@/lib/format";
import UsersTable from "@/components/UsersTable";
import TransactionsTable from "@/components/TransactionsTable";
import PoolsTable from "@/components/PoolsTable";
import Logo from "@/components/Logo";

interface Props {
  creds: Credentials;
  onLogout: () => void;
}

type Tab = "users" | "transactions" | "pools";

export default function Dashboard({ creds, onLogout }: Props) {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>("users");

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
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <Logo height={26} className="brand-logo" />
          <span className="brand-sub">Admin</span>
        </div>
        <div className="topbar-actions">
          <span className="muted">{creds.baseUrl}</span>
          <button className="ghost" onClick={loadStats}>
            Muat ulang
          </button>
          <button className="ghost" onClick={onLogout}>
            Keluar
          </button>
        </div>
      </header>

      <main className="content">
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
          <button
            className={tab === "users" ? "active" : ""}
            onClick={() => setTab("users")}
          >
            Pengguna
          </button>
          <button
            className={tab === "transactions" ? "active" : ""}
            onClick={() => setTab("transactions")}
          >
            Transaksi
          </button>
          <button
            className={tab === "pools" ? "active" : ""}
            onClick={() => setTab("pools")}
          >
            Patungan
          </button>
        </nav>

        {tab === "users" && <UsersTable creds={creds} />}
        {tab === "transactions" && <TransactionsTable creds={creds} />}
        {tab === "pools" && <PoolsTable creds={creds} />}
      </main>
    </div>
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
