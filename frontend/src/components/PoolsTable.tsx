import { useEffect, useState } from "react";
import { api, type AdminPool, type Credentials, type Meta } from "../api";
import { formatDate, formatRupiah } from "../format";
import Pager from "./Pager";

interface Props {
  creds: Credentials;
}

export default function PoolsTable({ creds }: Props) {
  const [rows, setRows] = useState<AdminPool[]>([]);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    api
      .pools(creds, page)
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
  if (rows.length === 0) return <p className="muted">Belum ada patungan.</p>;

  return (
    <>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Judul</th>
              <th>Pemilik</th>
              <th>Status</th>
              <th className="num">Terkumpul</th>
              <th className="num">Target</th>
              <th>Dibuat</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p) => (
              <tr key={p.id}>
                <td>{p.title}</td>
                <td>{p.ownerName || "—"}</td>
                <td>
                  <span className={`chip${p.status === "open" ? "" : " chip-warn"}`}>
                    {p.status === "open" ? "Aktif" : "Ditutup"}
                  </span>
                </td>
                <td className="num">{formatRupiah(p.collected)}</td>
                <td className="num">{formatRupiah(p.target)}</td>
                <td className="muted">{formatDate(p.createdAt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pager meta={meta} onPage={setPage} loading={loading} />
    </>
  );
}
