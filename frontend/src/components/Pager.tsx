import type { Meta } from "@/lib/types";

interface Props {
  meta: Meta | null;
  onPage: (page: number) => void;
  loading: boolean;
}

// Pager renders prev/next controls + a "page X of Y (N total)" label from the
// backend's pagination meta block.
export default function Pager({ meta, onPage, loading }: Props) {
  if (!meta) return null;
  const { page, totalPages, total } = meta;
  return (
    <div className="pager">
      <button disabled={loading || page <= 1} onClick={() => onPage(page - 1)}>
        ← Sebelumnya
      </button>
      <span className="muted">
        Halaman {page} dari {Math.max(totalPages, 1)} · {total} total
      </span>
      <button
        disabled={loading || page >= totalPages}
        onClick={() => onPage(page + 1)}
      >
        Berikutnya →
      </button>
    </div>
  );
}
