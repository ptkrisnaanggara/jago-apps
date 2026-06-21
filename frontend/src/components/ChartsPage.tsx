import { useCallback, useEffect, useMemo, useState } from "react";
import { api } from "@/lib/api";
import type { ChartsData } from "@/lib/types";
import { formatRupiah } from "@/lib/format";
import { useAuth } from "@/context/auth";

const RANGES = [7, 14, 30];

// ChartsPage shows a daily income/expense bar chart plus the top expense
// categories. Charts are hand-rolled (CSS/flex) — no charting dependency.
export default function ChartsPage() {
  const { creds } = useAuth();
  const [days, setDays] = useState(14);
  const [data, setData] = useState<ChartsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    let active = true;
    setLoading(true);
    setError(null);
    api
      .charts(creds, days)
      .then((d) => active && setData(d))
      .catch(
        (e: unknown) => active && e instanceof Error && setError(e.message),
      )
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, [creds, days]);

  useEffect(() => load(), [load]);

  const maxDaily = useMemo(() => {
    if (!data) return 1;
    return Math.max(1, ...data.daily.flatMap((d) => [d.income, d.expense]));
  }, [data]);

  const totals = useMemo(() => {
    const income = data?.daily.reduce((s, d) => s + d.income, 0) ?? 0;
    const expense = data?.daily.reduce((s, d) => s + d.expense, 0) ?? 0;
    return { income, expense };
  }, [data]);

  const maxCat = useMemo(
    () => Math.max(1, ...(data?.topCategories.map((c) => c.total) ?? [])),
    [data],
  );

  if (error) return <p className="error">{error}</p>;
  if (loading && !data) return <p className="muted">Memuat…</p>;
  if (!data) return null;

  return (
    <>
      <div className="table-toolbar">
        <div className="chart-legend">
          <span>
            <i className="dot dot-income" /> Masuk{" "}
            <strong>{formatRupiah(totals.income)}</strong>
          </span>
          <span>
            <i className="dot dot-expense" /> Keluar{" "}
            <strong>{formatRupiah(totals.expense)}</strong>
          </span>
        </div>
        <span className="chips-spacer" />
        <select value={days} onChange={(e) => setDays(Number(e.target.value))}>
          {RANGES.map((r) => (
            <option key={r} value={r}>
              {r} hari
            </option>
          ))}
        </select>
      </div>

      <section className="chart-card">
        <h3>Arus Kas Harian</h3>
        <div className="bars" role="img" aria-label="Grafik arus kas harian">
          {data.daily.map((d) => (
            <div className="bar-group" key={d.date}>
              <div className="bar-pair">
                <div
                  className="bar bar-income"
                  style={{ height: `${(d.income / maxDaily) * 100}%` }}
                  title={`${d.date} · Masuk ${formatRupiah(d.income)}`}
                />
                <div
                  className="bar bar-expense"
                  style={{ height: `${(d.expense / maxDaily) * 100}%` }}
                  title={`${d.date} · Keluar ${formatRupiah(d.expense)}`}
                />
              </div>
              <span className="bar-label">{d.date.slice(5)}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="chart-card">
        <h3>Kategori Pengeluaran Teratas</h3>
        {data.topCategories.length === 0 ? (
          <p className="muted">Belum ada pengeluaran.</p>
        ) : (
          <div className="cat-list">
            {data.topCategories.map((c) => (
              <div className="cat-row" key={c.category}>
                <span className="cat-name" title={c.category}>
                  {c.category}
                </span>
                <div className="cat-track">
                  <div
                    className="cat-bar"
                    style={{ width: `${(c.total / maxCat) * 100}%` }}
                  />
                </div>
                <span className="cat-val num">{formatRupiah(c.total)}</span>
              </div>
            ))}
          </div>
        )}
      </section>
    </>
  );
}
