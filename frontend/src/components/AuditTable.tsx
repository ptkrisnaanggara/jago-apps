import { useCallback } from "react";
import { api } from "@/lib/api";
import type { AuditLog } from "@/lib/types";
import { formatDate } from "@/lib/format";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";

// Maps an action code to a human label + a CSS modifier for its chip.
const ACTIONS: Record<string, { label: string; warn?: boolean }> = {
  "admin.create": { label: "Buat admin" },
  "admin.update": { label: "Ubah admin" },
  "admin.status": { label: "Status admin", warn: true },
  "card.freeze": { label: "Bekukan kartu", warn: true },
  "card.unfreeze": { label: "Aktifkan kartu" },
};

export default function AuditTable() {
  const { creds } = useAuth();

  const fetcher = useCallback(
    (page: number) => api.auditLogs(creds, page),
    [creds],
  );
  const { rows, meta, setPage, loading, error } = usePagedList<AuditLog>(
    fetcher,
    [creds],
  );

  if (error) return <p className="error">{error}</p>;
  if (loading && rows.length === 0) return <p className="muted">Memuat…</p>;
  if (rows.length === 0) return <p className="muted">Belum ada aktivitas.</p>;

  return (
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
  );
}
