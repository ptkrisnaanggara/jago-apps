import { useCallback, useEffect, useState } from "react";
import { api, type Credentials, type Stats } from "../api";
import { formatRupiah } from "../format";
import UsersTable from "./UsersTable";
import TransactionsTable from "./TransactionsTable";

interface Props {
  creds: Credentials;
  onLogout: () => void;
}

type Tab = "users" | "transactions";

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
          <span className="brand-mark">JAGO</span>
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
        </nav>

        {tab === "users" ? (
          <UsersTable creds={creds} />
        ) : (
          <TransactionsTable creds={creds} />
        )}
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
