import { useEffect, useState } from "react";
import {
  api,
  type AdminTransaction,
  type Credentials,
  type Meta,
} from "../api";
import { formatDate, formatRupiah } from "../format";
import Pager from "./Pager";

interface Props {
  creds: Credentials;
}

export default function TransactionsTable({ creds }: Props) {
  const [rows, setRows] = useState<AdminTransaction[]>([]);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    api
      .transactions(creds, page)
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
  if (rows.length === 0) return <p className="muted">Belum ada transaksi.</p>;

  return (
    <>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Waktu</th>
              <th>Pengguna</th>
              <th>Judul</th>
              <th>Kategori</th>
              <th className="num">Nominal</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((t) => (
              <tr key={t.id}>
                <td className="muted">{formatDate(t.createdAt)}</td>
                <td>{t.userName || "—"}</td>
                <td>{t.title}</td>
                <td>
                  <span className="chip">{t.category}</span>
                </td>
                <td className={`num ${t.type}`}>
                  {t.type === "expense" ? "−" : "+"}
                  {formatRupiah(t.amount)}
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
