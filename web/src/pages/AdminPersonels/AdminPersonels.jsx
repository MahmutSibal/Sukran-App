import { useEffect, useState } from 'react';
import './AdminPersonels.css';
import { getStaff, createStaff, setStaffActive, deleteStaff } from '../../api/staff.js';
import { UserRole, USER_ROLE_LABELS } from '../../api/config.js';

const ROLE_OPTIONS = [
  { value: UserRole.Kitchen, label: 'Mutfak' },
  { value: UserRole.Waiter, label: 'Garson' },
];

export default function AdminPersonels() {
  const [personels, setPersonels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', password: '', role: '' });

  const load = async () => {
    setLoading(true);
    try {
      const data = await getStaff();
      setPersonels(data || []);
      setError('');
    } catch (e) {
      setError(e?.message || 'Personeller yüklenemedi.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleAddPersonel = async () => {
    if (!form.name.trim() || !form.email.trim() || !form.password.trim() || !form.role) {
      alert('Lütfen tüm alanları doldurun.');
      return;
    }
    setSaving(true);
    try {
      await createStaff({
        name: form.name.trim(),
        email: form.email.trim(),
        password: form.password,
        role: Number(form.role),
      });
      setForm({ name: '', email: '', password: '', role: '' });
      await load();
    } catch (e) {
      alert(e?.message || 'Personel eklenemedi.');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleStatus = async (personel) => {
    try {
      await setStaffActive(personel.id, !personel.isActive);
      setPersonels((prev) =>
        prev.map((p) => (p.id === personel.id ? { ...p, isActive: !p.isActive } : p))
      );
    } catch (e) {
      alert(e?.message || 'Durum güncellenemedi.');
    }
  };

  const handleDelete = async (personel) => {
    if (!window.confirm(`${personel.name} adlı personeli silmek istiyor musunuz?`)) return;
    try {
      await deleteStaff(personel.id);
      setPersonels((prev) => prev.filter((p) => p.id !== personel.id));
    } catch (e) {
      alert(e?.message || 'Personel silinemedi.');
    }
  };

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col gap-2">
        <h2 className="font-headline-md text-headline-md text-on-background">Personeller</h2>
        <p className="text-body-md text-on-surface-variant">
          İşletmenizde görev alacak mutfak ve garson personellerini buradan
          tanımlayabilir, aktif veya pasif durumlarını yönetebilirsiniz.
        </p>
      </section>

      <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow">
        <h3 className="font-headline-sm text-headline-sm text-on-background mb-md">
          Yeni Personel Ekle
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-md items-end">
          <div className="flex flex-col gap-2">
            <label className="font-label-md text-label-md text-on-surface-variant">Personel İsmi</label>
            <input
              name="name"
              value={form.name}
              onChange={handleChange}
              className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
              placeholder="Örn: Ahmet Yılmaz"
              type="text"
            />
          </div>

          <div className="flex flex-col gap-2">
            <label className="font-label-md text-label-md text-on-surface-variant">E-posta</label>
            <input
              name="email"
              value={form.email}
              onChange={handleChange}
              className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
              placeholder="personel@email.com"
              type="email"
            />
          </div>

          <div className="flex flex-col gap-2">
            <label className="font-label-md text-label-md text-on-surface-variant">Şifre</label>
            <input
              name="password"
              value={form.password}
              onChange={handleChange}
              className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
              placeholder="En az 8 karakter"
              type="password"
            />
          </div>

          <div className="flex flex-col gap-2">
            <label className="font-label-md text-label-md text-on-surface-variant">Rol</label>
            <select
              name="role"
              value={form.role}
              onChange={handleChange}
              className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
            >
              <option value="">Rol seçiniz</option>
              {ROLE_OPTIONS.map((r) => (
                <option key={r.value} value={r.value}>
                  {r.label}
                </option>
              ))}
            </select>
          </div>

          <div className="md:col-span-2 lg:col-span-4 flex justify-end mt-2">
            <button
              type="button"
              onClick={handleAddPersonel}
              disabled={saving}
              className="bg-primary-container text-on-primary-container font-label-md text-label-md py-3 px-8 rounded-lg hover:opacity-90 transition-opacity disabled:opacity-60 flex items-center gap-2"
            >
              {saving && (
                <span className="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>
              )}
              Personel Ekle
            </button>
          </div>
        </div>
      </section>

      <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow">
        <h3 className="font-headline-sm text-headline-sm text-on-background mb-md">Tanımlı Personeller</h3>

        {loading ? (
          <div className="flex items-center justify-center gap-3 py-10 text-on-surface-variant">
            <span className="material-symbols-outlined animate-spin">progress_activity</span>
            Yükleniyor...
          </div>
        ) : error ? (
          <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
            <span className="material-symbols-outlined text-[20px]">error</span>
            {error}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container text-on-surface-variant font-label-md text-label-md border-b border-outline-variant">
                  <th className="py-4 px-4 rounded-tl-lg">İsim</th>
                  <th className="py-4 px-4">E-posta</th>
                  <th className="py-4 px-4">Rol</th>
                  <th className="py-4 px-4">Durum</th>
                  <th className="py-4 px-4 rounded-tr-lg text-right">İşlem</th>
                </tr>
              </thead>
              <tbody className="font-body-sm text-body-sm text-on-background">
                {personels.length === 0 && (
                  <tr>
                    <td colSpan="5" className="py-10 px-4 text-center text-on-surface-variant">
                      Henüz personel eklenmemiş.
                    </td>
                  </tr>
                )}
                {personels.map((personel) => (
                  <tr
                    key={personel.id}
                    className="border-b border-outline-variant hover:bg-surface-container-low transition-colors last:border-b-0"
                  >
                    <td className={`py-4 px-4 font-medium ${!personel.isActive ? 'text-on-surface-variant' : ''}`}>
                      {personel.name}
                    </td>
                    <td className={`py-4 px-4 ${!personel.isActive ? 'text-on-surface-variant' : ''}`}>
                      {personel.email}
                    </td>
                    <td className={`py-4 px-4 ${!personel.isActive ? 'text-on-surface-variant' : ''}`}>
                      {USER_ROLE_LABELS[personel.role] || personel.role}
                    </td>
                    <td className="py-4 px-4">
                      <span
                        className={`inline-flex items-center px-3 py-1 rounded-lg text-[11px] font-bold tracking-wider ${
                          personel.isActive
                            ? 'bg-primary-container text-on-primary-container'
                            : 'bg-surface-container-high text-on-surface-variant'
                        }`}
                      >
                        {personel.isActive ? 'AKTİF' : 'PASİF'}
                      </span>
                    </td>
                    <td className="py-4 px-4 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button
                          type="button"
                          onClick={() => handleToggleStatus(personel)}
                          className="inline-flex items-center cursor-pointer"
                          aria-label="Personel durumunu değiştir"
                        >
                          <span
                            className={`w-10 h-5 rounded-full relative transition-colors ${
                              personel.isActive ? 'bg-primary-container' : 'bg-outline-variant'
                            }`}
                          >
                            <span
                              className={`absolute top-1 w-3 h-3 bg-white rounded-full transition-all ${
                                personel.isActive ? 'right-1' : 'left-1'
                              }`}
                            />
                          </span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDelete(personel)}
                          className="text-on-surface-variant hover:text-error transition-colors"
                          aria-label="Personeli sil"
                        >
                          <span className="material-symbols-outlined text-[20px]">delete</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
