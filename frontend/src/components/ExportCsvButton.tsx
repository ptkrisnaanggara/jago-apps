import { useState } from "react";
import { api } from "@/lib/api";
import { useAuth } from "@/context/auth";
import { downloadBlob } from "@/lib/download";

interface Props {
  kind: "users" | "transactions" | "audit-logs";
  params?: Record<string, string>;
}

// ExportCsvButton fetches a CSV export (with auth, forwarding any active
// filters) and downloads it.
export default function ExportCsvButton({ kind, params }: Props) {
  const { creds } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(false);

  async function handleClick() {
    setBusy(true);
    setError(false);
    try {
      const blob = await api.exportCsv(creds, kind, params ?? {});
      const stamp = new Date().toISOString().slice(0, 10);
      downloadBlob(blob, `${kind}-${stamp}.csv`);
    } catch {
      setError(true);
    } finally {
      setBusy(false);
    }
  }

  return (
    <button
      className="ghost small"
      onClick={handleClick}
      disabled={busy}
      title="Unduh CSV"
    >
      {busy ? "Mengekspor…" : error ? "Gagal — coba lagi" : "⬇ Export CSV"}
    </button>
  );
}
