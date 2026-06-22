import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { AdminBill } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";

const FILTERS: { value: string; label: string }[] = [
  { value: "", label: "Semua" },
  { value: "unpaid", label: "Belum" },
  { value: "paid", label: "Lunas" },
];

export default function BillsTable() {
  const { creds } = useAuth();
  const [status, setStatus] = useState("");

  const fetcher = useCallback(
    (page: number) => api.bills(creds, page, 20, status),
    [creds, status],
  );
  const { rows, meta, page, setPage, loading, error } = usePagedList<AdminBill>(
    fetcher,
    [creds, status],
  );

  // Changing the filter resets to the first page.
  useEffect(() => {
    if (page !== 1) setPage(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status]);

  const now = Date.now();

  const toolbar = (
    <div className="chips-row">
      {FILTERS.map((f) => (
        <button
          key={f.value}
          className={`filter-chip${status === f.value ? " active" : ""}`}
          onClick={() => setStatus(f.value)}
        >
          {f.label}
        </button>
      ))}
    </div>
  );

  return (
    <>
      {toolbar}
      {error && <p className="error">{error}</p>}
      {!error && loading && rows.length === 0 && (
        <p className="muted">Memuat…</p>
      )}
      {!error && !loading && rows.length === 0 && (
        <p className="muted">Belum ada tagihan.</p>
      )}
      {!error && rows.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Pemilik</th>
                  <th>Tagihan</th>
                  <th>Kategori</th>
                  <th>Jatuh Tempo</th>
                  <th className="num">Nominal</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((b) => {
                  const overdue =
                    !b.isPaid && new Date(b.dueDate).getTime() < now;
                  return (
                    <tr key={b.id}>
                      <td>{b.userName || "—"}</td>
                      <td>{b.biller}</td>
                      <td>
                        <span className="chip">{b.category}</span>
                      </td>
                      <td className={overdue ? "expense" : "muted"}>
                        {formatDate(b.dueDate)}
                      </td>
                      <td className="num">{formatRupiah(b.amount)}</td>
                      <td>
                        {b.isPaid ? (
                          <span className="chip chip-ok">Lunas</span>
                        ) : overdue ? (
                          <span className="chip chip-danger">Terlambat</span>
                        ) : (
                          <span className="chip chip-warn">Belum</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <Pager meta={meta} onPage={setPage} loading={loading} />
        </>
      )}
    </>
  );
}
