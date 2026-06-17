// Display helpers shared across the dashboard.

const rupiah = new Intl.NumberFormat("id-ID", {
  style: "currency",
  currency: "IDR",
  maximumFractionDigits: 0,
});

export function formatRupiah(amount: number): string {
  return rupiah.format(amount);
}

const compact = new Intl.NumberFormat("id-ID", { notation: "compact" });

export function formatCompact(n: number): string {
  return compact.format(n);
}

export function formatDate(iso: string): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
