import { useEffect, useMemo, useState } from 'react';
import './SuperAdminComplaints.css';
import { getComplaints, updateComplaint } from '../../api/complaints.js';
import { ComplaintStatus, COMPLAINT_STATUS_LABELS } from '../../api/config.js';

function getStatusClass(label) {
  if (label === 'YENİ') return 'bg-blue-100 text-blue-800';
  if (label === 'İNCELENİYOR') return 'bg-secondary-container text-on-secondary-container';
  return 'bg-surface-container-high text-on-surface-variant';
}

function formatTime(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleString('tr-TR', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default function SuperAdminComplaints() {
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('Tümü');
  const [selected, setSelected] = useState(null);
  const [responseText, setResponseText] = useState('');
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const data = await getComplaints();
      setComplaints(data || []);
      setError('');
    } catch (e) {
      setError(e?.message || 'Şikayetler yüklenemedi.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  // Görünüm modeli: durum etiketi + sıra numarası
  const decorated = useMemo(
    () =>
      complaints.map((c, idx) => ({
        ...c,
        statusLabel: COMPLAINT_STATUS_LABELS[c.status] || 'YENİ',
        complaintNo: `${complaints.length - idx}. ŞİKAYET`,
      })),
    [complaints]
  );

  const filtered = useMemo(() => {
    return decorated.filter((c) => {
      const matchesSearch =
        c.restaurantName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.content.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesFilter = filterType === 'Tümü' || c.statusLabel === filterType;
      return matchesSearch && matchesFilter;
    });
  }, [decorated, searchTerm, filterType]);

  const openResponseModal = (complaint) => {
    setSelected(complaint);
    setResponseText(complaint.response || '');
  };

  const closeResponseModal = () => {
    setSelected(null);
    setResponseText('');
  };

  const handleSendResponse = async () => {
    if (!responseText.trim()) {
      alert('Lütfen kullanıcıya gönderilecek geri dönüş içeriğini yazın.');
      return;
    }
    setSaving(true);
    try {
      await updateComplaint(selected.id, {
        status: ComplaintStatus.Responded,
        response: responseText.trim(),
      });
      closeResponseModal();
      await load();
    } catch (e) {
      alert(e?.message || 'Geri dönüş gönderilemedi.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
        <section className="flex flex-col gap-2">
          <h2 className="font-headline-lg text-headline-lg text-on-background">
            Müşteri Şikayetleri
          </h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Müşteriler tarafından restoranlar hakkında oluşturulan şikayetleri
            inceleyebilir ve gerekli durumlarda kullanıcıya geri dönüş
            sağlayabilirsiniz.
          </p>
        </section>

        <section className="flex flex-col md:flex-row justify-between items-center gap-md bg-surface-container-lowest p-4 rounded-xl border border-outline-variant ambient-shadow">
          <div className="relative w-full md:w-96">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant">
              search
            </span>
            <input
              className="w-full bg-surface-container-low border border-outline-variant rounded-full py-2 pl-10 pr-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all"
              placeholder="Restoran adı veya şikayet içeriği ara..."
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-2 md:pb-0">
            {['Tümü', 'YENİ', 'İNCELENİYOR', 'GERİ DÖNÜŞ YAPILDI'].map((filter) => (
              <button
                key={filter}
                type="button"
                onClick={() => setFilterType(filter)}
                className={`px-4 py-2 rounded-full text-label-md whitespace-nowrap transition-colors ${
                  filterType === filter
                    ? 'bg-primary-container text-on-primary-container'
                    : 'bg-surface-container-high text-on-surface-variant hover:bg-surface-container-highest'
                }`}
              >
                {filter === 'YENİ'
                  ? 'Yeni'
                  : filter === 'İNCELENİYOR'
                  ? 'İnceleniyor'
                  : filter === 'GERİ DÖNÜŞ YAPILDI'
                  ? 'Geri Dönüş Yapıldı'
                  : 'Tümü'}
              </button>
            ))}
          </div>
        </section>

        <section className="flex flex-col gap-md">
          <h3 className="font-headline-sm text-headline-sm text-on-background border-l-4 border-secondary-container pl-3">
            Gelen Şikayetler
          </h3>

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
            <div className="grid grid-cols-1 gap-4">
              {filtered.map((complaint) => {
                const isCompleted = complaint.status === ComplaintStatus.Responded;
                return (
                  <div
                    key={complaint.id}
                    className={`bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow transition-all ${
                      isCompleted ? 'opacity-80' : 'hover:border-primary-container'
                    }`}
                  >
                    <div className="flex flex-col md:flex-row justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2 flex-wrap">
                          <h4 className="font-headline-sm text-headline-sm text-primary-container">
                            {complaint.restaurantName}
                          </h4>
                          <span className="px-2 py-1 rounded-lg text-[11px] font-bold bg-surface-container-high text-on-surface-variant">
                            {complaint.complaintNo}
                          </span>
                        </div>
                        <p className="text-label-sm text-on-surface-variant mb-2">
                          Kullanıcı: <span className="font-medium">{complaint.userName}</span> •{' '}
                          {formatTime(complaint.createdAt)}
                        </p>
                        <p className="text-body-md text-on-background leading-relaxed">
                          {complaint.content}
                        </p>
                        {complaint.response && (
                          <div className="mt-3 bg-surface-container-low border border-outline-variant rounded-lg p-3">
                            <p className="text-label-sm text-on-surface-variant mb-1">
                              Gönderilen Geri Dönüş:
                            </p>
                            <p className="text-body-sm text-on-background italic">
                              "{complaint.response}"
                            </p>
                          </div>
                        )}
                      </div>

                      <div className="flex flex-col justify-between items-start md:items-end gap-4">
                        <span
                          className={`inline-flex items-center px-3 py-1 rounded-full text-[11px] font-bold tracking-wider ${getStatusClass(
                            complaint.statusLabel
                          )}`}
                        >
                          {complaint.statusLabel}
                        </span>
                        <button
                          type="button"
                          onClick={() => openResponseModal(complaint)}
                          className={
                            isCompleted
                              ? 'bg-surface-container-high text-on-surface-variant px-6 py-2 rounded-lg text-label-md hover:bg-surface-container-highest transition-colors'
                              : 'bg-primary-container text-on-primary-container px-6 py-2 rounded-lg text-label-md hover:opacity-90 transition-opacity'
                          }
                        >
                          {isCompleted ? 'Geri Dönüşü Gör' : 'Geri Dönüş Yap'}
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}

              {filtered.length === 0 && (
                <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-lg ambient-shadow text-center">
                  <p className="text-on-surface-variant">Bu filtreye uygun şikayet bulunamadı.</p>
                </div>
              )}
            </div>
          )}
        </section>
      </div>

      {selected && (
        <div className="fixed inset-0 z-[1000] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-surface-container-lowest border border-outline-variant rounded-xl w-full max-w-[640px] overflow-hidden">
            <div className="p-md border-b border-outline-variant flex justify-between items-start gap-md">
              <div>
                <h3 className="font-headline-sm text-headline-sm text-primary-container">
                  Kullanıcıya Geri Dönüş Yap
                </h3>
                <p className="font-body-sm text-body-sm text-on-surface-variant mt-1">
                  Şikayet sahibi kullanıcıya gönderilecek açıklamayı yazın.
                </p>
              </div>
              <button
                type="button"
                onClick={closeResponseModal}
                className="text-on-surface-variant hover:bg-surface-container-low rounded-full p-1 transition-colors"
                aria-label="Modalı kapat"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <div className="p-md flex flex-col gap-md">
              <div className="bg-surface-container-low border border-outline-variant rounded-xl p-4">
                <h4 className="font-headline-sm text-headline-sm text-primary-container mb-2">
                  {selected.restaurantName}
                </h4>
                <p className="text-label-sm text-on-surface-variant mb-2">
                  Kullanıcı: <span className="font-medium">{selected.userName}</span> •{' '}
                  {formatTime(selected.createdAt)}
                </p>
                <p className="text-body-sm text-on-background leading-relaxed">{selected.content}</p>
              </div>

              <div className="flex flex-col gap-2">
                <label className="font-label-md text-label-md text-on-background">
                  Geri Dönüş İçeriği
                </label>
                <textarea
                  value={responseText}
                  onChange={(e) => setResponseText(e.target.value)}
                  className="w-full min-h-[160px] bg-surface-container-low border border-outline-variant rounded-lg py-3 px-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none resize-none"
                  placeholder="Örn: Merhaba, yaşadığınız deneyim için üzgünüz. Şikayetiniz ilgili işletmeye iletilmiştir."
                  autoFocus
                />
              </div>
            </div>

            <div className="p-md bg-surface-container-low flex flex-col sm:flex-row justify-end gap-3">
              <button
                type="button"
                onClick={closeResponseModal}
                className="px-6 py-2.5 rounded-lg font-label-md text-label-md text-on-surface-variant hover:bg-surface-container-high transition-colors"
              >
                Vazgeç
              </button>
              <button
                type="button"
                onClick={handleSendResponse}
                disabled={saving}
                className="px-6 py-2.5 rounded-lg font-label-md text-label-md bg-primary-container text-white hover:opacity-90 transition-opacity shadow-sm disabled:opacity-60 flex items-center gap-2"
              >
                {saving && <span className="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>}
                Geri Dönüşü Gönder
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
