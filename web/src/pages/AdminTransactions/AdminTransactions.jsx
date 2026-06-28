import './AdminTransactions.css';
import { useEffect, useMemo, useState } from 'react';
import { getAuditLogs } from '../../api/auditLogs.js';
import { USER_ROLE_LABELS } from '../../api/config.js';

function formatDate(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('tr-TR');
}
function formatTime(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
}

export default function AdminTransactions() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    let active = true;
    setLoading(true);
    getAuditLogs(200)
      .then((data) => active && setLogs(data || []))
      .catch((e) => active && setError(e?.message || 'Kayıtlar yüklenemedi.'))
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, []);

  const filtered = useMemo(() => {
    const q = searchTerm.toLowerCase();
    return logs.filter(
      (l) =>
        (l.action || '').toLowerCase().includes(q) ||
        (l.details || '').toLowerCase().includes(q) ||
        (l.actorName || '').toLowerCase().includes(q) ||
        (l.entityType || '').toLowerCase().includes(q)
    );
  }, [logs, searchTerm]);

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            İşlem Geçmişi
          </h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            İşletmede gerçekleştirilen yönetim işlemlerini, tarih ve kullanıcı
            bilgileriyle birlikte buradan takip edebilirsiniz.
          </p>
        </div>

        <div className="relative w-full">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant">
            search
          </span>
          <input
            className="w-full bg-surface-container-lowest border border-outline-variant rounded-lg py-3 pl-10 pr-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all"
            placeholder="İşlem ara..."
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </section>

      {loading && (
        <div className="flex items-center justify-center gap-3 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined animate-spin">progress_activity</span>
          Yükleniyor...
        </div>
      )}

      {!loading && error && (
        <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
          <span className="material-symbols-outlined text-[20px]">error</span>
          {error}
        </div>
      )}

      {!loading && !error && (
        <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow">
          <h3 className="font-headline-sm text-headline-sm text-on-background mb-md">
            Sistem İşlem Kayıtları
          </h3>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container text-on-surface-variant font-label-md text-label-md border-b border-outline-variant">
                  <th className="py-4 px-4 rounded-tl-lg">Tarih</th>
                  <th className="py-4 px-4">Saat</th>
                  <th className="py-4 px-4">İşlemi Yapan</th>
                  <th className="py-4 px-4">Rol</th>
                  <th className="py-4 px-4">İşlem</th>
                  <th className="py-4 px-4">Açıklama</th>
                  <th className="py-4 px-4 rounded-tr-lg">İlgili Kayıt</th>
                </tr>
              </thead>
              <tbody className="font-body-sm text-body-sm text-on-background">
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan="7" className="py-10 px-4 text-center text-on-surface-variant">
                      İşlem kaydı bulunamadı.
                    </td>
                  </tr>
                )}
                {filtered.map((log, index) => (
                  <tr
                    key={log.id}
                    className={`hover:bg-surface-container-low transition-colors ${
                      index !== filtered.length - 1 ? 'border-b border-outline-variant' : ''
                    }`}
                  >
                    <td className="py-4 px-4">{formatDate(log.createdAt)}</td>
                    <td className="py-4 px-4">{formatTime(log.createdAt)}</td>
                    <td className="py-4 px-4">{log.actorName || 'Sistem'}</td>
                    <td className="py-4 px-4">
                      <span className="px-2 py-1 rounded-full text-[10px] font-bold bg-surface-container-high text-on-surface-variant">
                        {log.actorRole != null ? USER_ROLE_LABELS[log.actorRole] || log.actorRole : 'SİSTEM'}
                      </span>
                    </td>
                    <td className="py-4 px-4 font-medium text-primary-container">{log.action}</td>
                    <td className="py-4 px-4">{log.details}</td>
                    <td className="py-4 px-4 text-on-surface-variant">
                      {log.entityType}
                      {log.entityId ? ` #${log.entityId.slice(0, 8)}` : ''}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}
