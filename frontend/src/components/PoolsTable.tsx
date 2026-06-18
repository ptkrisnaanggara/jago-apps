import { useCallback } from "react";
import { api } from "@/lib/api";
import type { Credentials } from "@/lib/credentials";
import type { AdminPool } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";

interface Props {
  creds: Credentials;
}

export default function PoolsTable({ creds }: Props) {
  const fetcher = useCallback(
    (page: number) => api.pools(creds, page),
    [creds],
  );
  const { rows, meta, setPage, loading, error } = usePagedList<AdminPool>(
    fetcher,
    [creds],
  );

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
                  <span
                    className={`chip${p.status === "open" ? "" : " chip-warn"}`}
                  >
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
