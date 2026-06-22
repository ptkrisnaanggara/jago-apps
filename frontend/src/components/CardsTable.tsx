import { useCallback, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { AdminCard } from "@/lib/types";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";

const FILTERS: { value: string; label: string }[] = [
  { value: "", label: "Semua" },
  { value: "false", label: "Aktif" },
  { value: "true", label: "Beku" },
];

export default function CardsTable() {
  const { creds } = useAuth();
  const [frozen, setFrozen] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const fetcher = useCallback(
    (page: number) => api.cards(creds, page, 20, frozen),
    [creds, frozen],
  );
  const { rows, meta, page, setPage, loading, error } = usePagedList<AdminCard>(
    fetcher,
    [creds, frozen, reloadKey],
  );

  // Changing the filter resets to the first page.
  useEffect(() => {
    if (page !== 1) setPage(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [frozen]);

  async function toggleFreeze(card: AdminCard) {
    setBusyId(card.id);
    setActionError(null);
    try {
      await api.freezeCard(creds, card.id, !card.isFrozen);
      setReloadKey((k) => k + 1);
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "Gagal memperbarui.");
    } finally {
      setBusyId(null);
    }
  }

  const toolbar = (
    <div className="chips-row">
      {FILTERS.map((f) => (
        <button
          key={f.value}
          className={`filter-chip${frozen === f.value ? " active" : ""}`}
          onClick={() => setFrozen(f.value)}
        >
          {f.label}
        </button>
      ))}
    </div>
  );

  return (
    <>
      {toolbar}
      {actionError && <p className="error">{actionError}</p>}
      {error && <p className="error">{error}</p>}
      {!error && loading && rows.length === 0 && (
        <p className="muted">Memuat…</p>
      )}
      {!error && !loading && rows.length === 0 && (
        <p className="muted">Belum ada kartu.</p>
      )}
      {!error && rows.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Pemilik</th>
                  <th>Kartu</th>
                  <th>Tipe</th>
                  <th className="mono">Nomor</th>
                  <th>Status</th>
                  <th aria-label="Aksi"></th>
                </tr>
              </thead>
              <tbody>
                {rows.map((card) => (
                  <tr key={card.id}>
                    <td>{card.userName || "—"}</td>
                    <td>{card.label}</td>
                    <td>
                      <span className="chip">{card.type}</span>
                    </td>
                    <td className="mono">•••• {card.last4}</td>
                    <td>
                      <span
                        className={`chip${card.isFrozen ? " chip-warn" : ""}`}
                      >
                        {card.isFrozen ? "Beku" : "Aktif"}
                      </span>
                    </td>
                    <td className="num">
                      <button
                        className="ghost small"
                        disabled={busyId === card.id}
                        onClick={() => toggleFreeze(card)}
                      >
                        {busyId === card.id
                          ? "…"
                          : card.isFrozen
                            ? "Aktifkan"
                            : "Bekukan"}
                      </button>
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
