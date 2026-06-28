import { useEffect, useMemo, useState } from 'react';
import './AdminEvents.css';
import { getEvents, createEvent, updateEvent, deleteEvent } from '../../api/events.js';
import { formatPrice, toMinorAmount } from '../../api/config.js';

const emptyForm = {
  title: '',
  description: '',
  imageUrl: '',
  date: '',
  time: '',
  location: '',
  price: '',
  tags: '',
  isFree: false,
};

const FALLBACK_IMAGE =
  'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=1200&q=80';

export default function AdminEvents() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const data = await getEvents();
      setEvents(data || []);
      setError('');
    } catch (e) {
      setError(e?.message || 'Etkinlikler yüklenemedi.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const stats = useMemo(() => {
    const published = events.filter((e) => e.isPublished).length;
    return [
      { id: 1, label: 'Toplam Etkinlik', value: events.length },
      { id: 2, label: 'Yayında', value: published },
      { id: 3, label: 'Yayında Değil', value: events.length - published },
    ];
  }, [events]);

  const openCreateModal = () => {
    setEditingId(null);
    setForm(emptyForm);
    setIsModalOpen(true);
  };

  const openEditModal = (event) => {
    setEditingId(event.id);
    setForm({
      title: event.title,
      description: event.description,
      imageUrl: event.imageUrl,
      date: event.date,
      time: event.time,
      location: event.location,
      price: event.isFree ? '' : String(event.price / 100),
      tags: (event.tags || []).join(', '),
      isFree: event.isFree,
    });
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingId(null);
    setForm(emptyForm);
  };

  const handleChange = (e) => {
    const { name, value, checked, type } = e.target;
    setForm((prev) => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
  };

  const handleSubmit = async () => {
    if (!form.title.trim() || !form.description.trim() || !form.date.trim() || !form.time.trim()) {
      alert('Lütfen etkinlik adı, açıklama, tarih ve saat alanlarını doldurun.');
      return;
    }
    const payload = {
      title: form.title.trim(),
      description: form.description.trim(),
      imageUrl: form.imageUrl.trim() || FALLBACK_IMAGE,
      date: form.date.trim(),
      time: form.time.trim(),
      location: form.location.trim() || 'Etkinlik Alanı',
      price: form.isFree ? 0 : toMinorAmount(form.price || 0),
      isFree: form.isFree,
      tags: form.tags.split(',').map((t) => t.trim()).filter(Boolean),
    };
    setSaving(true);
    try {
      if (editingId) {
        const existing = events.find((e) => e.id === editingId);
        await updateEvent(editingId, { ...payload, isPublished: existing?.isPublished ?? true });
      } else {
        await createEvent(payload);
      }
      closeModal();
      await load();
    } catch (e) {
      alert(e?.message || 'Etkinlik kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (event) => {
    if (!confirm('Bu etkinliği silmek istediğinize emin misiniz?')) return;
    try {
      await deleteEvent(event.id);
      setEvents((prev) => prev.filter((e) => e.id !== event.id));
    } catch (e) {
      alert(e?.message || 'Etkinlik silinemedi.');
    }
  };

  const handleTogglePublish = async (event) => {
    try {
      await updateEvent(event.id, {
        title: event.title,
        description: event.description,
        imageUrl: event.imageUrl,
        date: event.date,
        time: event.time,
        location: event.location,
        price: event.price,
        isFree: event.isFree,
        tags: event.tags || [],
        isPublished: !event.isPublished,
      });
      setEvents((prev) =>
        prev.map((e) => (e.id === event.id ? { ...e, isPublished: !e.isPublished } : e))
      );
    } catch (e) {
      alert(e?.message || 'Durum güncellenemedi.');
    }
  };

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col md:flex-row justify-between items-start md:items-center gap-md mb-md">
        <div>
          <h2 className="font-headline-md text-headline-md font-bold text-on-background mb-1">
            Etkinlik Tahtası
          </h2>
          <p className="font-body-md text-body-md text-on-surface-variant">
            İşletmenizde düzenleyeceğiniz etkinlikleri oluşturabilir,
            yayınlayabilir ve müşterilerinize duyurabilirsiniz.
          </p>
        </div>
        <button
          type="button"
          onClick={openCreateModal}
          className="bg-primary-container text-on-primary-container px-6 py-3 rounded-lg font-bold shadow-md hover:opacity-90 transition-opacity flex items-center gap-2"
        >
          <span className="material-symbols-outlined">add</span>
          Yeni Etkinlik Oluştur
        </button>
      </section>

      <section className="grid grid-cols-2 md:grid-cols-3 gap-md mb-lg">
        {stats.map((stat) => (
          <div
            key={stat.id}
            className="bg-surface-container-lowest border border-outline-variant rounded-xl p-4 ambient-shadow"
          >
            <p className="text-label-sm text-on-surface-variant mb-1">{stat.label}</p>
            <p className="text-headline-sm font-bold text-primary">{stat.value}</p>
          </div>
        ))}
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

      {!loading && !error && events.length === 0 && (
        <div className="flex flex-col items-center justify-center gap-2 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined text-[40px]">celebration</span>
          <p className="font-body-lg text-body-lg">Henüz etkinlik oluşturulmamış.</p>
        </div>
      )}

      <section className="flex flex-col gap-lg">
        {events.map((event) => (
          <div
            key={event.id}
            className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden ambient-shadow flex flex-col md:flex-row"
          >
            <div className="md:w-[40%] h-64 md:h-auto relative">
              <img src={event.imageUrl} alt={event.title} className="w-full h-full object-cover" />
            </div>
            <div className="md:w-[60%] p-md flex flex-col">
              <div className="flex flex-wrap items-center gap-2 mb-2">
                <span
                  className={`text-[11px] font-bold px-3 py-1 rounded-full ${
                    event.isPublished
                      ? 'bg-primary-container text-on-primary-container'
                      : 'bg-surface-container-high text-on-surface-variant'
                  }`}
                >
                  {event.isPublished ? 'YAYINDA' : 'YAYINDA DEĞİL'}
                </span>
                <span className="text-label-sm text-on-surface-variant md:ml-auto">{event.date}</span>
              </div>

              <h3 className="font-headline-md text-headline-md font-bold mb-2">{event.title}</h3>
              <p className="text-body-md text-on-surface-variant mb-4">{event.description}</p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-y-2 gap-x-4 mb-6">
                <Info icon="calendar_today" text={event.date} />
                <Info icon="schedule" text={event.time} />
                <Info icon="location_on" text={event.location} />
                <div className="flex items-center gap-2 text-body-sm font-bold text-primary">
                  <span className="material-symbols-outlined text-[18px]">payments</span>
                  {event.isFree ? 'Ücretsiz' : formatPrice(event.price)}
                </div>
              </div>

              <div className="mt-auto flex flex-wrap items-center justify-between gap-md">
                <div className="flex flex-wrap gap-2">
                  {(event.tags || []).map((tag) => (
                    <span
                      key={tag}
                      className="bg-surface-container-high text-on-surface-variant text-[11px] px-2 py-1 rounded"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
                <div className="flex items-center gap-3 flex-wrap">
                  <button
                    type="button"
                    onClick={() => handleDelete(event)}
                    className="text-label-sm font-bold text-error hover:underline"
                  >
                    Sil
                  </button>
                  <button
                    type="button"
                    onClick={() => handleTogglePublish(event)}
                    className="px-4 py-2 border border-outline-variant rounded-lg text-label-sm font-bold hover:bg-surface-container-low transition-colors"
                  >
                    {event.isPublished ? 'Yayından Kaldır' : 'Yayına Al'}
                  </button>
                  <button
                    type="button"
                    onClick={() => openEditModal(event)}
                    className="px-4 py-2 border border-outline-variant rounded-lg text-label-sm font-bold hover:bg-surface-container-low transition-colors"
                  >
                    Düzenle
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </section>

      {isModalOpen && (
        <div className="fixed inset-0 z-[999] bg-black/40 flex items-center justify-center p-4">
          <div className="bg-surface-container-lowest border border-outline-variant rounded-xl w-full max-w-[760px] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-md border-b border-outline-variant">
              <div>
                <h3 className="font-headline-sm text-headline-sm text-on-background">
                  {editingId ? 'Etkinliği Düzenle' : 'Yeni Etkinlik Oluştur'}
                </h3>
                <p className="text-body-sm text-on-surface-variant">
                  Etkinlik bilgilerini doldurarak yayına hazırlayın.
                </p>
              </div>
              <button
                type="button"
                onClick={closeModal}
                className="w-10 h-10 rounded-full hover:bg-surface-container-low flex items-center justify-center text-on-surface-variant"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <div className="p-md grid grid-cols-1 md:grid-cols-2 gap-md">
              <Field label="Görsel URL" full>
                <input name="imageUrl" value={form.imageUrl} onChange={handleChange} className="evt-input" placeholder="https://.../gorsel.jpg" type="url" />
              </Field>
              <Field label="Etkinlik Adı" full>
                <input name="title" value={form.title} onChange={handleChange} className="evt-input" placeholder="Örn: Canlı Müzik Gecesi" type="text" />
              </Field>
              <Field label="Tarih">
                <input name="date" value={form.date} onChange={handleChange} className="evt-input" placeholder="28 Haziran 2026" type="text" />
              </Field>
              <Field label="Saat">
                <input name="time" value={form.time} onChange={handleChange} className="evt-input" type="time" />
              </Field>
              <Field label="Konum">
                <input name="location" value={form.location} onChange={handleChange} className="evt-input" placeholder="Ana Salon" type="text" />
              </Field>
              <Field label="Ücret (₺)">
                <input name="price" value={form.price} onChange={handleChange} disabled={form.isFree} className="evt-input disabled:opacity-50" placeholder="250" type="number" />
              </Field>
              <label className="md:col-span-2 flex items-center gap-2 text-body-sm text-on-surface-variant">
                <input name="isFree" checked={form.isFree} onChange={handleChange} type="checkbox" />
                Bu etkinlik ücretsiz
              </label>
              <Field label="Etiketler (virgülle)" full>
                <input name="tags" value={form.tags} onChange={handleChange} className="evt-input" placeholder="Canlı Müzik, Özel Gün" type="text" />
              </Field>
              <Field label="Açıklama" full>
                <textarea name="description" value={form.description} onChange={handleChange} className="evt-input h-28 resize-none" placeholder="Etkinlik içeriğini açıklayın" />
              </Field>
            </div>

            <div className="p-md border-t border-outline-variant flex justify-end gap-sm">
              <button type="button" onClick={closeModal} className="px-5 py-3 border border-outline-variant rounded-lg font-label-md text-label-md hover:bg-surface-container-low transition-colors">
                Vazgeç
              </button>
              <button
                type="button"
                onClick={handleSubmit}
                disabled={saving}
                className="px-6 py-3 bg-primary-container text-on-primary-container rounded-lg font-label-md text-label-md hover:opacity-90 transition-opacity disabled:opacity-60 flex items-center gap-2"
              >
                {saving && <span className="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>}
                {editingId ? 'Etkinliği Güncelle' : 'Etkinliği Ekle'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function Info({ icon, text }) {
  return (
    <div className="flex items-center gap-2 text-body-sm text-on-surface-variant">
      <span className="material-symbols-outlined text-[18px]">{icon}</span>
      {text}
    </div>
  );
}

function Field({ label, children, full }) {
  return (
    <div className={`flex flex-col gap-1 ${full ? 'md:col-span-2' : ''}`}>
      <label className="text-label-sm text-on-surface-variant">{label}</label>
      {children}
    </div>
  );
}
