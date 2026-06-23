import { useCallback } from "react";
import { api } from "@/lib/api";
import type { AdminTransfer } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";
import ExportCsvButton from "@/components/ExportCsvButton";

export default function TransfersTable() {
  const { creds } = useAuth();

  const fetcher = useCallback(
    (page: number) => api.transfers(creds, page),
    [creds],
  );
  const { rows, meta, setPage, loading, error } = usePagedList<AdminTransfer>(
    fetcher,
    [creds],
  );

  if (error) return <p className="error">{error}</p>;
  if (loading && rows.length === 0) return <p className="muted">Memuat…</p>;
  if (rows.length === 0) return <p className="muted">Belum ada transfer.</p>;

  return (
    <>
      <div className="table-toolbar">
        <span className="chips-spacer" />
        <ExportCsvButton kind="transfers" />
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Waktu</th>
              <th>Pengirim</th>
              <th>Penerima</th>
              <th>Bank</th>
              <th className="num">Nominal</th>
              <th>Referensi</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((t) => (
              <tr key={t.id}>
                <td className="muted">{formatDate(t.createdAt)}</td>
                <td>{t.userName || "—"}</td>
                <td>
                  {t.recipientName}
                  {t.note && <span className="muted"> · {t.note}</span>}
                </td>
                <td>
                  <span className="chip">{t.recipientBank}</span>{" "}
                  <span className="mono muted">{t.recipientAccount}</span>
                </td>
                <td className="num expense">−{formatRupiah(t.amount)}</td>
                <td className="mono muted">{t.referenceId}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pager meta={meta} onPage={setPage} loading={loading} />
    </>
  );
}
