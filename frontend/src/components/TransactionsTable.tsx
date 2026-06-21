import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { AdminTransaction, TxFilter } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";
import ExportCsvButton from "@/components/ExportCsvButton";
import DateRangeFilter from "@/components/DateRangeFilter";

const FILTERS: { value: TxFilter; label: string }[] = [
  { value: "", label: "Semua" },
  { value: "income", label: "Masuk" },
  { value: "expense", label: "Keluar" },
];

export default function TransactionsTable() {
  const { creds } = useAuth();
  const [type, setType] = useState<TxFilter>("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  const fetcher = useCallback(
    (page: number) => api.transactions(creds, page, 20, type, from, to),
    [creds, type, from, to],
  );
  const { rows, meta, page, setPage, loading, error } =
    usePagedList<AdminTransaction>(fetcher, [creds, type, from, to]);

  // Changing any filter resets to the first page.
  useEffect(() => {
    if (page !== 1) setPage(1);
    // Only react to filter changes here.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [type, from, to]);

  const filterChips = (
    <div className="chips-row">
      {FILTERS.map((f) => (
        <button
          key={f.value}
          className={`filter-chip${type === f.value ? " active" : ""}`}
          onClick={() => setType(f.value)}
        >
          {f.label}
        </button>
      ))}
      <DateRangeFilter
        from={from}
        to={to}
        onChange={(r) => {
          setFrom(r.from);
          setTo(r.to);
        }}
      />
      <span className="chips-spacer" />
      <ExportCsvButton kind="transactions" params={{ type, from, to }} />
    </div>
  );

  return (
    <>
      {filterChips}
      {error && <p className="error">{error}</p>}
      {!error && loading && rows.length === 0 && (
        <p className="muted">Memuat…</p>
      )}
      {!error && !loading && rows.length === 0 && (
        <p className="muted">Belum ada transaksi.</p>
      )}
      {!error && rows.length > 0 && (
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
      )}
    </>
  );
}
