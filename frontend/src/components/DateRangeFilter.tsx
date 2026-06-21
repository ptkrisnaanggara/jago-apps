interface Props {
  from: string;
  to: string;
  onChange: (next: { from: string; to: string }) => void;
}

// DateRangeFilter is a pair of native date inputs (YYYY-MM-DD) with a reset.
export default function DateRangeFilter({ from, to, onChange }: Props) {
  return (
    <div className="date-range">
      <input
        type="date"
        value={from}
        max={to || undefined}
        onChange={(e) => onChange({ from: e.target.value, to })}
        aria-label="Dari tanggal"
      />
      <span className="muted">–</span>
      <input
        type="date"
        value={to}
        min={from || undefined}
        onChange={(e) => onChange({ from, to: e.target.value })}
        aria-label="Sampai tanggal"
      />
      {(from || to) && (
        <button
          type="button"
          className="link-button"
          onClick={() => onChange({ from: "", to: "" })}
        >
          Reset
        </button>
      )}
    </div>
  );
}
