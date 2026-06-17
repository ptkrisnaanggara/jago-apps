import { useEffect, useState } from "react";
import {
  api,
  type AdminTransaction,
  type Credentials,
  type Meta,
  type TxFilter,
} from "../api";
import { formatDate, formatRupiah } from "../format";
import Pager from "./Pager";

interface Props {
  creds: Credentials;
}

const FILTERS: { value: TxFilter; label: string }[] = [
  { value: "", label: "Semua" },
  { value: "income", label: "Masuk" },
  { value: "expense", label: "Keluar" },
];

export default function TransactionsTable({ creds }: Props) {
  const [rows, setRows] = useState<AdminTransaction[]>([]);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [page, setPage] = useState(1);
  const [type, setType] = useState<TxFilter>("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    api
      .transactions(creds, page, 20, type)
      .then((res) => {
        if (!active) return;
        setRows(res.data);
        setMeta(res.meta);
      })
      .catch((err: unknown) => {
        if (active && err instanceof Error) setError(err.message);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [creds, page, type]);

  // Switching the filter resets to the first page.
  function selectType(value: TxFilter) {
    setType(value);
    setPage(1);
  }

  const filterChips = (
    <div className="chips-row">
      {FILTERS.map((f) => (
        <button
          key={f.value}
          className={`filter-chip${type === f.value ? " active" : ""}`}
          onClick={() => selectType(f.value)}
        >
          {f.label}
        </button>
      ))}
    </div>
  );

  if (error)
    return (
      <>
        {filterChips}
        <p className="error">{error}</p>
      </>
    );
  if (loading && rows.length === 0)
    return (
      <>
        {filterChips}
        <p className="muted">Memuat…</p>
      </>
    );

  return (
    <>
      {filterChips}
      {rows.length === 0 ? (
        <p className="muted">Belum ada transaksi.</p>
      ) : (
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
