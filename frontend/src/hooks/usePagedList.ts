import { useEffect, useState } from "react";
import type { Meta, Page } from "@/lib/types";

interface PagedState<T> {
  rows: T[];
  meta: Meta | null;
  page: number;
  setPage: (page: number) => void;
  loading: boolean;
  error: string | null;
}

/**
 * Drives a paginated list backed by a `Page<T>` endpoint: tracks the current
 * page, loading and error state, and cancels stale responses when inputs
 * change. `deps` lets callers reset/refetch (e.g. when a filter changes).
 *
 * The fetcher receives the 1-based page number and must resolve to a
 * `Page<T>` (the backend's `{ data, meta }` envelope).
 */
export function usePagedList<T>(
  fetcher: (page: number) => Promise<Page<T>>,
  deps: unknown[] = [],
): PagedState<T> {
  const [rows, setRows] = useState<T[]>([]);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    fetcher(page)
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
    // The fetcher closes over `deps`; callers list what should trigger a reload.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, ...deps]);

  return { rows, meta, page, setPage, loading, error };
}
