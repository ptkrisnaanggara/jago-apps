import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import type { AdminUser } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";
import { KYC_LABELS, kycChipClass } from "@/lib/userStatus";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";
import ExportCsvButton from "@/components/ExportCsvButton";

export default function UsersTable() {
  const { creds } = useAuth();
  const navigate = useNavigate();

  const fetcher = useCallback(
    (page: number) => api.users(creds, page),
    [creds],
  );
  const { rows, meta, setPage, loading, error } = usePagedList<AdminUser>(
    fetcher,
    [creds],
  );

  if (error) return <p className="error">{error}</p>;
  if (loading && rows.length === 0) return <p className="muted">Memuat…</p>;
  if (rows.length === 0) return <p className="muted">Belum ada pengguna.</p>;

  return (
    <>
      <div className="table-toolbar">
        <ExportCsvButton kind="users" />
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Nama</th>
              <th>Nomor HP</th>
              <th>KYC</th>
              <th className="num">Saldo</th>
              <th>Bergabung</th>
              <th aria-label="Detail"></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((u) => (
              <tr
                key={u.id}
                className="clickable"
                onClick={() => navigate(`/users/${u.id}`)}
                title="Lihat detail"
              >
                <td>
                  {u.name}
                  {u.status === "blocked" && (
                    <span className="chip chip-danger">Diblokir</span>
                  )}
                </td>
                <td>{u.phone}</td>
                <td>
                  <span className={kycChipClass(u.kycStatus)}>
                    {KYC_LABELS[u.kycStatus]}
                  </span>
                </td>
                <td className="num">{formatRupiah(u.balance)}</td>
                <td className="muted">{formatDate(u.createdAt)}</td>
                <td className="chevron" aria-hidden="true">
                  ›
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pager meta={meta} onPage={setPage} loading={loading} />
    </>
  );
}
