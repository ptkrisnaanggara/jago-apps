import { useCallback, useEffect, useState, type ReactNode } from "react";
import { Link, useParams } from "react-router-dom";
import { api } from "@/lib/api";
import type { UserDetail as Detail } from "@/lib/types";
import { formatDate, formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";
import UserEditModal from "@/components/UserEditModal";
import BalanceAdjustModal from "@/components/BalanceAdjustModal";

// UserDetailPage is a full-page drill-down for one user: account, pockets,
// cards (with an operator freeze toggle), bills, pools, and recent transactions.
export default function UserDetailPage() {
  const { id = "" } = useParams();
  const { creds } = useAuth();
  const [detail, setDetail] = useState<Detail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyCard, setBusyCard] = useState<string | null>(null);
  const [editing, setEditing] = useState(false);
  const [adjusting, setAdjusting] = useState(false);

  const load = useCallback(() => {
    setError(null);
    api
      .user(creds, id)
      .then(setDetail)
      .catch((err: unknown) => {
        if (err instanceof Error) setError(err.message);
      })
      .finally(() => setLoading(false));
  }, [creds, id]);

  useEffect(() => {
    load();
  }, [load]);

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
    <div className="detail-page">
      <Link to="/" className="back-link">
        ← Pengguna
      </Link>

      {error && <p className="error banner">{error}</p>}
      {loading && !detail && <p className="muted">Memuat…</p>}

      {detail && (
        <>
          <header className="detail-header">
            <div>
              <h1>{detail.user.name}</h1>
              <p className="muted">
                {detail.user.phone} · Bergabung{" "}
                {formatDate(detail.user.createdAt)}
              </p>
              <button className="ghost small" onClick={() => setEditing(true)}>
                Ubah pengguna
              </button>
            </div>
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
              {detail.account && (
                <button
                  className="ghost small"
                  onClick={() => setAdjusting(true)}
                >
                  Sesuaikan saldo
                </button>
              )}
            </div>
          </header>

          <div className="detail-grid">
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

            <Section title="Transaksi Terakhir" wide>
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
          </div>

          {editing && (
            <UserEditModal
              userId={detail.user.id}
              initialName={detail.user.name}
              initialPhone={detail.user.phone}
              onClose={() => setEditing(false)}
              onSaved={load}
            />
          )}

          {adjusting && detail.account && (
            <BalanceAdjustModal
              userId={detail.user.id}
              userName={detail.user.name}
              currentBalance={detail.account.balance}
              onClose={() => setAdjusting(false)}
              onSaved={load}
            />
          )}
        </>
      )}
    </div>
  );
}

function Section({
  title,
  children,
  wide,
}: {
  title: string;
  children: ReactNode;
  wide?: boolean;
}) {
  return (
    <section className={`detail-section${wide ? " detail-section-wide" : ""}`}>
      <h3>{title}</h3>
      {children}
    </section>
  );
}

function Empty() {
  return <p className="muted">Tidak ada.</p>;
}
