import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { AuditLog } from "@/lib/types";
import { formatDate } from "@/lib/format";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";
import ExportCsvButton from "@/components/ExportCsvButton";
import DateRangeFilter from "@/components/DateRangeFilter";

// Maps an action code to a human label + a CSS modifier for its chip.
const ACTIONS: Record<string, { label: string; warn?: boolean }> = {
  "admin.login": { label: "Login admin" },
  "admin.create": { label: "Buat admin" },
  "admin.update": { label: "Ubah admin" },
  "admin.status": { label: "Status admin", warn: true },
  "user.update": { label: "Ubah pengguna" },
  "card.freeze": { label: "Bekukan kartu", warn: true },
  "card.unfreeze": { label: "Aktifkan kartu" },
};

export default function AuditTable() {
  const { creds } = useAuth();
  const [action, setAction] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  const fetcher = useCallback(
    (page: number) => api.auditLogs(creds, page, 20, action, from, to),
    [creds, action, from, to],
  );
  const { rows, meta, page, setPage, loading, error } = usePagedList<AuditLog>(
    fetcher,
    [creds, action, from, to],
  );

  // Changing any filter resets to the first page.
  useEffect(() => {
    if (page !== 1) setPage(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [action, from, to]);

  const toolbar = (
    <div className="table-toolbar">
      <select value={action} onChange={(e) => setAction(e.target.value)}>
        <option value="">Semua aksi</option>
        {Object.entries(ACTIONS).map(([value, { label }]) => (
          <option key={value} value={value}>
            {label}
          </option>
        ))}
      </select>
      <DateRangeFilter
        from={from}
        to={to}
        onChange={(r) => {
          setFrom(r.from);
          setTo(r.to);
        }}
      />
      <span className="chips-spacer" />
      <ExportCsvButton kind="audit-logs" params={{ action, from, to }} />
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
        <p className="muted">Belum ada aktivitas.</p>
      )}
      {!error && rows.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Waktu</th>
                  <th>Admin</th>
                  <th>Aksi</th>
                  <th>Detail</th>
                  <th>IP</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((e) => {
                  const a = ACTIONS[e.action];
                  return (
                    <tr key={e.id}>
                      <td className="muted">{formatDate(e.createdAt)}</td>
                      <td>{e.actorName}</td>
                      <td>
                        <span className={`chip${a?.warn ? " chip-warn" : ""}`}>
                          {a?.label ?? e.action}
                        </span>
                      </td>
                      <td>{e.detail}</td>
                      <td className="mono muted">{e.ip}</td>
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
