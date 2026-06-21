import { useCallback, useState, type FormEvent } from "react";
import { api } from "@/lib/api";
import type { Admin } from "@/lib/types";
import { formatDate } from "@/lib/format";
import { useAuth } from "@/context/auth";
import { usePagedList } from "@/hooks/usePagedList";
import Pager from "@/components/Pager";
import AdminEditModal from "@/components/AdminEditModal";

export default function AdminsTable() {
  const { creds, admin: current } = useAuth();
  const [reloadKey, setReloadKey] = useState(0);
  const reload = useCallback(() => setReloadKey((k) => k + 1), []);

  const fetcher = useCallback(
    (page: number) => api.admins(creds, page),
    [creds],
  );
  const { rows, meta, setPage, loading, error } = usePagedList<Admin>(fetcher, [
    creds,
    reloadKey,
  ]);

  // Create form
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [role, setRole] = useState("admin");
  const [creating, setCreating] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [editing, setEditing] = useState<Admin | null>(null);

  async function handleCreate(e: FormEvent) {
    e.preventDefault();
    setFormError(null);
    setCreating(true);
    try {
      await api.createAdmin(creds, { name, phone, role });
      setName("");
      setPhone("");
      setRole("admin");
      reload();
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : "Gagal menambah admin.",
      );
    } finally {
      setCreating(false);
    }
  }

  async function toggleStatus(a: Admin) {
    setBusyId(a.id);
    setFormError(null);
    try {
      await api.setAdminStatus(
        creds,
        a.id,
        a.status === "active" ? "disabled" : "active",
      );
      reload();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : "Gagal memperbarui.");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <form className="admin-create" onSubmit={handleCreate}>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Nama"
          required
        />
        <input
          type="tel"
          inputMode="numeric"
          value={phone}
          onChange={(e) => setPhone(e.target.value.replace(/[^\d]/g, ""))}
          placeholder="Nomor HP (mis. 81255550001)"
          required
        />
        <select value={role} onChange={(e) => setRole(e.target.value)}>
          <option value="admin">admin</option>
          <option value="superadmin">superadmin</option>
        </select>
        <button type="submit" disabled={creating || phone.length < 6}>
          {creating ? "Menambah…" : "Tambah Admin"}
        </button>
      </form>
      {formError && <p className="error">{formError}</p>}

      {error ? (
        <p className="error">{error}</p>
      ) : loading && rows.length === 0 ? (
        <p className="muted">Memuat…</p>
      ) : rows.length === 0 ? (
        <p className="muted">Belum ada admin.</p>
      ) : (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Nama</th>
                  <th>Nomor HP</th>
                  <th>Peran</th>
                  <th>Status</th>
                  <th>Dibuat</th>
                  <th aria-label="Aksi"></th>
                </tr>
              </thead>
              <tbody>
                {rows.map((a) => {
                  const isSelf = a.id === current?.id;
                  return (
                    <tr key={a.id}>
                      <td>
                        {a.name}
                        {isSelf && <span className="chip">Anda</span>}
                      </td>
                      <td className="mono">{a.phone}</td>
                      <td>
                        <span className="chip">{a.role}</span>
                      </td>
                      <td>
                        <span
                          className={`chip${a.status === "active" ? "" : " chip-warn"}`}
                        >
                          {a.status === "active" ? "Aktif" : "Nonaktif"}
                        </span>
                      </td>
                      <td className="muted">{formatDate(a.createdAt)}</td>
                      <td className="num row-actions">
                        <button
                          className="ghost small"
                          onClick={() => setEditing(a)}
                        >
                          Ubah
                        </button>
                        <button
                          className="ghost small"
                          disabled={busyId === a.id || isSelf}
                          title={
                            isSelf
                              ? "Tidak dapat menonaktifkan akun sendiri"
                              : ""
                          }
                          onClick={() => toggleStatus(a)}
                        >
                          {busyId === a.id
                            ? "…"
                            : a.status === "active"
                              ? "Nonaktifkan"
                              : "Aktifkan"}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <Pager meta={meta} onPage={setPage} loading={loading} />
        </>
      )}

      {editing && (
        <AdminEditModal
          admin={editing}
          onClose={() => setEditing(null)}
          onSaved={reload}
        />
      )}
    </>
  );
}
