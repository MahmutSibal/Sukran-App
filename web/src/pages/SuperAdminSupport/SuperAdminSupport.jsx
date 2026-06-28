import { useEffect, useMemo, useState } from 'react';
import './SuperAdminSupport.css';
import {
  getSupportRequests,
  setSupportCalled,
  deleteSupportRequest,
} from '../../api/support.js';

export default function SuperAdminSupport() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');

  const load = async () => {
    setLoading(true);
    try {
      const data = await getSupportRequests();
      setRequests(data || []);
      setError('');
    } catch (e) {
      setError(e?.message || 'Destek talepleri yüklenemedi.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const filteredRequests = useMemo(() => {
    return requests.filter((request) => {
      const matchesSearch =
        request.businessName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        request.content.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesFilter =
        filterType === 'all' ||
        (filterType === 'called' && request.isCalled) ||
        (filterType === 'notCalled' && !request.isCalled);
      return matchesSearch && matchesFilter;
    });
  }, [requests, searchTerm, filterType]);

  const handleToggleCalled = async (request) => {
    try {
      await setSupportCalled(request.id, !request.isCalled);
      setRequests((prev) =>
        prev.map((r) => (r.id === request.id ? { ...r, isCalled: !r.isCalled } : r))
      );
    } catch (e) {
      alert(e?.message || 'Durum güncellenemedi.');
    }
  };

  const handleCloseRequest = async (request) => {
    if (!window.confirm('Bu destek talebini kapatmak istiyor musunuz?')) return;
    try {
      await deleteSupportRequest(request.id);
      setRequests((prev) => prev.filter((r) => r.id !== request.id));
    } catch (e) {
      alert(e?.message || 'Talep kapatılamadı.');
    }
  };

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Destek Talepleri
          </h2>
          <p className="font-body-md text-body-md text-on-surface-variant">
            İşletmelerden gelen destek taleplerini görüntüleyebilir, arandı
            durumunu güncelleyebilir ve tamamlanan talepleri kapatabilirsiniz.
          </p>
        </div>

        <div className="flex flex-col md:flex-row gap-md items-center justify-between bg-surface-container-low p-4 rounded-xl border border-outline-variant">
          <div className="relative w-full md:w-96">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant">
              search
            </span>
            <input
              className="w-full bg-surface-container-lowest border border-outline-variant rounded-full py-2 pl-10 pr-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
              placeholder="İşletme adı veya destek içeriği ara..."
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="flex bg-surface-container rounded-lg p-1">
            {[
              ['all', 'Tümü'],
              ['called', 'Arandı'],
              ['notCalled', 'Aranmadı'],
            ].map(([key, label]) => (
              <button
                key={key}
                type="button"
                onClick={() => setFilterType(key)}
                className={`px-4 py-1.5 rounded-md font-label-sm text-label-sm transition-colors ${
                  filterType === key
                    ? 'bg-primary-container text-on-primary-container'
                    : 'text-on-surface-variant hover:bg-surface-container-high'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
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
        <section className="bg-surface-container-lowest border border-outline-variant rounded-xl ambient-shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container text-on-surface-variant font-label-md text-label-md border-b border-outline-variant">
                  <th className="py-4 px-6">İşletme Adı</th>
                  <th className="py-4 px-6 w-1/3">Destek Talebi İçeriği</th>
                  <th className="py-4 px-6">İletişim Numarası</th>
                  <th className="py-4 px-6">Durum</th>
                  <th className="py-4 px-6 text-right">İşlem</th>
                </tr>
              </thead>
              <tbody className="font-body-sm text-body-sm text-on-background">
                {filteredRequests.map((request, index) => (
                  <tr
                    key={request.id}
                    className={`hover:bg-surface-container-low transition-colors ${
                      index !== filteredRequests.length - 1 ? 'border-b border-outline-variant' : ''
                    }`}
                  >
                    <td className="py-4 px-6 font-medium">{request.businessName}</td>
                    <td className="py-4 px-6 text-on-surface-variant leading-relaxed">{request.content}</td>
                    <td className="py-4 px-6">{request.phone}</td>
                    <td className="py-4 px-6">
                      <span
                        className={`inline-flex items-center px-3 py-1 rounded-full text-[11px] font-bold tracking-wider ${
                          request.isCalled
                            ? 'bg-primary-container text-on-primary-container'
                            : 'bg-secondary-container text-on-secondary-container'
                        }`}
                      >
                        {request.isCalled ? 'ARANDI' : 'ARANMADI'}
                      </span>
                    </td>
                    <td className="py-4 px-6 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button
                          type="button"
                          onClick={() => handleToggleCalled(request)}
                          className={`material-symbols-outlined transition-colors ${
                            request.isCalled
                              ? 'text-primary-container'
                              : 'text-on-surface-variant hover:text-primary-container'
                          }`}
                          title={request.isCalled ? 'Aranmadı olarak işaretle' : 'Arandı olarak işaretle'}
                        >
                          {request.isCalled ? 'toggle_on' : 'toggle_off'}
                        </button>
                        <button
                          type="button"
                          onClick={() => handleCloseRequest(request)}
                          className="bg-primary-container text-on-primary-container px-3 py-1.5 rounded-lg font-label-sm text-label-sm hover:opacity-90 transition-opacity"
                        >
                          Talebi Kapat
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filteredRequests.length === 0 && (
                  <tr>
                    <td colSpan="5" className="py-10 px-6 text-center text-on-surface-variant">
                      Destek talebi bulunamadı.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}
