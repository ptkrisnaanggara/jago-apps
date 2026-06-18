import { useCallback, useEffect, useState, type ReactNode } from "react";
import { api } from "@/lib/api";
import type { Credentials } from "@/lib/credentials";
import type { UserDetail as Detail } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";

interface Props {
  creds: Credentials;
  userId: string;
  onClose: () => void;
}

// UserDetail is a modal drill-down for one user: account, pockets, cards (with
// an operator freeze toggle), bills, and recent transactions.
export default function UserDetail({ creds, userId, onClose }: Props) {
  const [detail, setDetail] = useState<Detail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyCard, setBusyCard] = useState<string | null>(null);

  const load = useCallback(() => {
    setError(null);
    api
      .user(creds, userId)
      .then(setDetail)
      .catch((err: unknown) => {
        if (err instanceof Error) setError(err.message);
      });
  }, [creds, userId]);

  useEffect(() => {
    load();
  }, [load]);

  // Close on Escape for keyboard users.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  async function toggleFreeze(cardId: string, frozen: boolean) {
    setBusyCard(cardId);
    setError(null);
    try {
      await api.freezeCard(creds, cardId, frozen);
      load(); // refresh to reflect the new state
    } catch (err) {
      if (err instanceof Error) setError(err.message);
    } finally {
      setBusyCard(null);
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <header className="modal-head">
          <div>
            <h2>{detail?.user.name ?? "Memuat…"}</h2>
            {detail && (
              <p className="muted">
                {detail.user.phone} · Bergabung{" "}
                {formatDate(detail.user.createdAt)}
              </p>
            )}
          </div>
          <button className="ghost" onClick={onClose} aria-label="Tutup">
            ✕
          </button>
        </header>

        <div className="modal-body">
          {error && <p className="error banner">{error}</p>}
          {!detail && !error && <p className="muted">Memuat…</p>}

          {detail && (
            <>
              <div className="detail-account">
                <span className="card-label">Saldo Rekening</span>
                <span className="card-value">
                  {detail.account ? formatRupiah(detail.account.balance) : "—"}
                </span>
                {detail.account && (
                  <span className="mono muted">
                    {detail.account.accountNumber}
                  </span>
                )}
              </div>

              <Section title={`Kantong (${detail.pockets.length})`}>
                {detail.pockets.length === 0 ? (
                  <Empty />
                ) : (
                  <ul className="detail-list">
                    {detail.pockets.map((p) => (
                      <li key={p.id}>
                        <span>
                          {p.name}
                          {p.isMain && <span className="chip">Utama</span>}
                          {p.locked && <span className="chip">Terkunci</span>}
                          {p.shared && <span className="chip">Bersama</span>}
                        </span>
                        <span className="num">{formatRupiah(p.balance)}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </Section>

              <Section title={`Kartu (${detail.cards.length})`}>
                {detail.cards.length === 0 ? (
                  <Empty />
                ) : (
                  <ul className="detail-list">
                    {detail.cards.map((card) => (
                      <li key={card.id}>
                        <span>
                          {card.label}
                          <span className="chip">{card.type}</span>
                          {card.isFrozen && (
                            <span className="chip chip-warn">Beku</span>
                          )}
                        </span>
                        <button
                          className="ghost small"
                          disabled={busyCard === card.id}
                          onClick={() => toggleFreeze(card.id, !card.isFrozen)}
                        >
                          {busyCard === card.id
                            ? "…"
                            : card.isFrozen
                              ? "Aktifkan"
                              : "Bekukan"}
                        </button>
                      </li>
                    ))}
                  </ul>
                )}
              </Section>

              <Section title={`Tagihan (${detail.bills.length})`}>
                {detail.bills.length === 0 ? (
                  <Empty />
                ) : (
                  <ul className="detail-list">
                    {detail.bills.map((b) => (
                      <li key={b.id}>
                        <span>
                          {b.biller}
                          <span className="chip">{b.category}</span>
                          {b.isPaid ? (
                            <span className="chip">Lunas</span>
                          ) : (
                            <span className="chip chip-warn">Belum</span>
                          )}
                        </span>
                        <span className="num">{formatRupiah(b.amount)}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </Section>

              <Section title={`Patungan (${detail.pools.length})`}>
                {detail.pools.length === 0 ? (
                  <Empty />
                ) : (
                  <ul className="detail-list">
                    {detail.pools.map((p) => (
                      <li key={p.id}>
                        <span>
                          {p.title}
                          <span className="chip">
                            {p.status === "open" ? "Aktif" : "Ditutup"}
                          </span>
                        </span>
                        <span className="num">
                          {formatRupiah(p.collected)} / {formatRupiah(p.target)}
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
              </Section>

              <Section title="Transaksi Terakhir">
                {detail.transactions.length === 0 ? (
                  <Empty />
                ) : (
                  <ul className="detail-list">
                    {detail.transactions.map((t) => (
                      <li key={t.id}>
                        <span>
                          {t.title}
                          <span className="muted">
                            {" "}
                            · {formatDate(t.createdAt)}
                          </span>
                        </span>
                        <span className={`num ${t.type}`}>
                          {t.type === "expense" ? "−" : "+"}
                          {formatRupiah(t.amount)}
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
              </Section>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="detail-section">
      <h3>{title}</h3>
      {children}
    </section>
  );
}

function Empty() {
  return <p className="muted">Tidak ada.</p>;
}
