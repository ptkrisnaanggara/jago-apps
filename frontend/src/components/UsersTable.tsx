import { useEffect, useState } from "react";
import { api, type AdminUser, type Credentials, type Meta } from "../api";
import { formatDate, formatRupiah } from "../format";
import Pager from "./Pager";
import UserDetail from "./UserDetail";

interface Props {
  creds: Credentials;
}

export default function UsersTable({ creds }: Props) {
  const [rows, setRows] = useState<AdminUser[]>([]);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<AdminUser | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    api
      .users(creds, page)
      .then((res) => {
        if (!active) return;
        setRows(res.data);
        setMeta(res.meta);
      })
      .catch((err: unknown) => {
        if (active && err instanceof Error) setError(err.message);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [creds, page]);

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
