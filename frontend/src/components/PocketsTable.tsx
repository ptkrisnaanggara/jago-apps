import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { AdminPocket } from "@/lib/types";
import { formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";

const FILTERS: { value: string; label: string }[] = [
  { value: "", label: "Semua" },
  { value: "main", label: "Utama" },
  { value: "spending", label: "Belanja" },
  { value: "saving", label: "Nabung" },
];

const TYPE_LABEL: Record<string, string> = {
  main: "Utama",
  spending: "Belanja",
  saving: "Nabung",
};

export default function PocketsTable() {
  const { creds } = useAuth();
  const [type, setType] = useState("");

  const fetcher = useCallback(
    (page: number) => api.pockets(creds, page, 20, type),
    [creds, type],
  );
  const { rows, meta, page, setPage, loading, error } =
    usePagedList<AdminPocket>(fetcher, [creds, type]);

  // Changing the filter resets to the first page.
  useEffect(() => {
    if (page !== 1) setPage(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [type]);

  const toolbar = (
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
        <p className="muted">Belum ada kantong.</p>
      )}
      {!error && rows.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Pemilik</th>
                  <th>Kantong</th>
                  <th>Jenis</th>
                  <th className="num">Saldo</th>
                  <th>Target</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((p) => {
                  const pct =
                    p.target && p.target > 0
                      ? Math.min(100, (p.balance / p.target) * 100)
                      : null;
                  return (
                    <tr key={p.id}>
                      <td>{p.userName || "—"}</td>
                      <td>
                        {p.name}
                        {p.isMain && <span className="chip">Utama</span>}
                        {p.locked && (
                          <span className="chip chip-warn">Terkunci</span>
                        )}
                        {p.shared && <span className="chip">Bersama</span>}
                      </td>
                      <td>
                        <span className="chip">{TYPE_LABEL[p.type]}</span>
                      </td>
                      <td className="num">{formatRupiah(p.balance)}</td>
                      <td>
                        {pct === null ? (
                          <span className="muted">—</span>
                        ) : (
                          <div
                            className="cat-track"
                            title={formatRupiah(p.target!)}
                          >
                            <div
                              className="cat-bar"
                              style={{ width: `${pct}%` }}
                            />
                          </div>
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
