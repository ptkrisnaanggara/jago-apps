import { useCallback, useState } from "react";
import { api } from "@/lib/api";
import type { Credentials } from "@/lib/credentials";
import type { AdminUser } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";
import UserDetail from "@/components/UserDetail";

interface Props {
  creds: Credentials;
}

export default function UsersTable({ creds }: Props) {
  const [selected, setSelected] = useState<AdminUser | null>(null);

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
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Nama</th>
              <th>Nomor HP</th>
              <th>No. Rekening</th>
              <th className="num">Saldo</th>
              <th>Bergabung</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((u) => (
              <tr
                key={u.id}
                className="clickable"
                onClick={() => setSelected(u)}
                title="Lihat detail"
              >
                <td>{u.name}</td>
                <td>{u.phone}</td>
                <td className="mono">{u.accountNumber || "—"}</td>
                <td className="num">{formatRupiah(u.balance)}</td>
                <td className="muted">{formatDate(u.createdAt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pager meta={meta} onPage={setPage} loading={loading} />
      {selected && (
        <UserDetail
          creds={creds}
          userId={selected.id}
          onClose={() => setSelected(null)}
        />
      )}
    </>
  );
}
