import { describe, expect, it, vi } from "vitest";
import { renderHook, waitFor, act } from "@testing-library/react";
import { usePagedList } from "./usePagedList";
import type { Page } from "@/lib/types";

function page<T>(data: T[], pageNo: number): Page<T> {
  return {
    data,
    meta: { page: pageNo, limit: 20, total: 100, totalPages: 5 },
  };
}

describe("usePagedList", () => {
  it("loads the first page and exposes meta", async () => {
    const fetcher = vi.fn(async (p: number) => page([`row-${p}`], p));
    const { result } = renderHook(() => usePagedList(fetcher, []));

    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.rows).toEqual(["row-1"]);
    expect(result.current.meta?.totalPages).toBe(5);
    expect(fetcher).toHaveBeenCalledWith(1);
  });

  it("refetches when the page changes", async () => {
    const fetcher = vi.fn(async (p: number) => page([`row-${p}`], p));
    const { result } = renderHook(() => usePagedList(fetcher, []));
    await waitFor(() => expect(result.current.loading).toBe(false));

    act(() => result.current.setPage(2));
    await waitFor(() => expect(result.current.rows).toEqual(["row-2"]));
    expect(fetcher).toHaveBeenLastCalledWith(2);
  });

  it("captures an error message", async () => {
    const fetcher = vi.fn(async () => {
      throw new Error("nope");
    });
    const { result } = renderHook(() => usePagedList(fetcher, []));

    await waitFor(() => expect(result.current.error).toBe("nope"));
    expect(result.current.loading).toBe(false);
  });
});
