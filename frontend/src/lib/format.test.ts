import { describe, expect, it } from "vitest";
import { formatDate, formatRupiah } from "./format";

describe("formatRupiah", () => {
  it("formats whole rupiah without decimals", () => {
    // Uses a non-breaking space and id-ID grouping (e.g. "Rp 12.750.000").
    const out = formatRupiah(12750000);
    expect(out).toMatch(/^Rp/);
    expect(out).toContain("12");
    expect(out).not.toContain(",00");
  });

  it("formats zero", () => {
    expect(formatRupiah(0)).toMatch(/Rp\s?0/);
  });
});

describe("formatDate", () => {
  it("returns an em dash for empty input", () => {
    expect(formatDate("")).toBe("—");
  });

  it("returns an em dash for an invalid date", () => {
    expect(formatDate("not-a-date")).toBe("—");
  });

  it("formats a valid ISO timestamp", () => {
    const out = formatDate("2026-06-17T08:19:48Z");
    expect(out).toContain("2026");
    expect(out).not.toBe("—");
  });
});
