import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createUser, updateUserRole } from '../../api/users.js';
import { createRestaurant } from '../../api/restaurants.js';
import { UserRole } from '../../api/config.js';
import MapLocationPicker from '../../components/MapLocationPicker.jsx';

// Slug'ı isimden türetir (backend de normalize eder; burası önizleme içindir).
function slugify(raw) {
  return (raw || '')
    .toLowerCase()
    .trim()
    .replace(/ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/ş/g, 's')
    .replace(/ı/g, 'i')
    .replace(/ö/g, 'o')
    .replace(/ç/g, 'c')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

const initialForm = {
  ownerName: '',
  ownerEmail: '',
  ownerPassword: '',
  restaurantName: '',
  slug: '',
  slugTouched: false,
  address: '',
  latitude: '',
  longitude: '',
};

export default function SuperAdminCreateRestaurant() {
  const navigate = useNavigate();
  const [form, setForm] = useState(initialForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(null);

  const effectiveSlug = useMemo(
    () => (form.slugTouched ? form.slug : slugify(form.restaurantName)),
    [form.slug, form.slugTouched, form.restaurantName]
  );

  const update = (key, value) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const validate = () => {
    if (!form.ownerName.trim()) return 'Sahip ad soyad zorunludur.';
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(form.ownerEmail.trim()))
      return 'Geçerli bir e-posta girin.';
    if (form.ownerPassword.length < 8)
      return 'Şifre en az 8 karakter olmalıdır.';
    if (!form.restaurantName.trim()) return 'Restoran adı zorunludur.';
    if (!effectiveSlug) return 'Slug oluşturulamadı, restoran adını kontrol edin.';
    if (!form.address.trim()) return 'Adres zorunludur.';
    const lat = Number(form.latitude);
    const lng = Number(form.longitude);
    if (Number.isNaN(lat) || lat < -90 || lat > 90)
      return 'Enlem -90 ile 90 arasında bir sayı olmalıdır.';
    if (Number.isNaN(lng) || lng < -180 || lng > 180)
      return 'Boylam -180 ile 180 arasında bir sayı olmalıdır.';
    return '';
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    const validationError = validate();
    if (validationError) {
      setError(validationError);
      return;
    }

    setSubmitting(true);
    try {
      // 1) Restoran sahibini oluştur (henüz restoransız).
      const { userId: ownerId } = await createUser({
        name: form.ownerName.trim(),
        email: form.ownerEmail.trim(),
        password: form.ownerPassword,
        role: UserRole.RestaurantOwner,
      });

      // 2) Restoranı bu sahiple oluştur.
      const { restaurantId } = await createRestaurant({
        name: form.restaurantName.trim(),
        slug: effectiveSlug,
        ownerId,
        longitude: Number(form.longitude),
        latitude: Number(form.latitude),
        address: form.address.trim(),
      });

      // 3) Sahibin kapsamını (restaurantId) oluşturulan restorana bağla.
      await updateUserRole(ownerId, {
        role: UserRole.RestaurantOwner,
        restaurantId,
      });

      setSuccess({
        restaurantId,
        restaurantName: form.restaurantName.trim(),
        ownerEmail: form.ownerEmail.trim(),
      });
      setForm(initialForm);
    } catch (err) {
      setError(
        err?.status === 409
          ? 'Bu e-posta ile zaten bir kullanıcı var.'
          : err?.message || 'Restoran oluşturulamadı. Lütfen tekrar deneyin.'
      );
    } finally {
      setSubmitting(false);
    }
  };

  if (success) {
    return (
      <div className="max-w-[720px] mx-auto flex flex-col gap-lg">
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-lg flex flex-col items-center gap-md text-center ambient-shadow">
          <span
            className="material-symbols-outlined text-[56px] text-primary"
            style={{ fontVariationSettings: "'FILL' 1" }}
          >
            check_circle
          </span>
          <h2 className="font-headline-sm text-headline-sm text-on-background">
            Restoran oluşturuldu
          </h2>
          <p className="font-body-md text-body-md text-on-surface-variant">
            <strong>{success.restaurantName}</strong> oluşturuldu ve sahibi{' '}
            <strong>{success.ownerEmail}</strong> olarak atandı. Sahip kendi
            panelinden personellerini dilediği sayıda ekleyebilir.
          </p>
          <div className="flex flex-wrap gap-3 justify-center mt-2">
            <button
              type="button"
              onClick={() =>
                navigate(`/super-admin/restaurants/${success.restaurantId}`)
              }
              className="bg-primary-container text-on-primary-container font-label-md text-label-md px-5 py-3 rounded-lg hover:opacity-90 transition-opacity"
            >
              Restoranı Görüntüle
            </button>
            <button
              type="button"
              onClick={() => setSuccess(null)}
              className="border border-outline-variant text-on-background font-label-md text-label-md px-5 py-3 rounded-lg hover:bg-surface-container-high transition-colors"
            >
              Yeni Restoran Ekle
            </button>
            <button
              type="button"
              onClick={() => navigate('/super-admin/restaurants')}
              className="text-on-surface-variant font-label-md text-label-md px-5 py-3 rounded-lg hover:bg-surface-container-high transition-colors"
            >
              Listeye Dön
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-[720px] mx-auto flex flex-col gap-lg">
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => navigate('/super-admin/restaurants')}
          className="w-10 h-10 rounded-lg border border-outline-variant flex items-center justify-center hover:bg-surface-container-high transition-colors"
          aria-label="Geri dön"
        >
          <span className="material-symbols-outlined">arrow_back</span>
        </button>
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background">
            Yeni Restoran ve Sahip
          </h2>
          <p className="font-body-md text-body-md text-on-surface-variant">
            Önce restoran sahibinin hesabını oluştur, ardından restoranı bu
            sahibe ata.
          </p>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
          <span className="material-symbols-outlined text-[20px]">error</span>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex flex-col gap-lg">
        {/* Restoran Sahibi */}
        <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md flex flex-col gap-md ambient-shadow">
          <div className="flex items-center gap-2 text-on-background">
            <span className="material-symbols-outlined text-primary">person</span>
            <h3 className="font-headline-sm text-headline-sm">Restoran Sahibi</h3>
          </div>

          <Field label="Ad Soyad">
            <input
              type="text"
              value={form.ownerName}
              onChange={(e) => update('ownerName', e.target.value)}
              placeholder="Örn. Ahmet Yılmaz"
              className={inputClass}
            />
          </Field>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-md">
            <Field label="E-posta">
              <input
                type="email"
                value={form.ownerEmail}
                onChange={(e) => update('ownerEmail', e.target.value)}
                placeholder="sahip@isletme.com"
                autoComplete="off"
                className={inputClass}
              />
            </Field>
            <Field label="Şifre (en az 8 karakter)">
              <input
                type="text"
                value={form.ownerPassword}
                onChange={(e) => update('ownerPassword', e.target.value)}
                placeholder="Geçici şifre"
                autoComplete="new-password"
                className={inputClass}
              />
            </Field>
          </div>
        </section>

        {/* Restoran Bilgileri */}
        <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md flex flex-col gap-md ambient-shadow">
          <div className="flex items-center gap-2 text-on-background">
            <span className="material-symbols-outlined text-primary">storefront</span>
            <h3 className="font-headline-sm text-headline-sm">Restoran Bilgileri</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-md">
            <Field label="Restoran Adı">
              <input
                type="text"
                value={form.restaurantName}
                onChange={(e) => update('restaurantName', e.target.value)}
                placeholder="Örn. Şükran Restoran"
                className={inputClass}
              />
            </Field>
            <Field label="Slug (URL)">
              <input
                type="text"
                value={effectiveSlug}
                onChange={(e) =>
                  setForm((prev) => ({
                    ...prev,
                    slug: e.target.value,
                    slugTouched: true,
                  }))
                }
                placeholder="sukran-restoran"
                className={inputClass}
              />
            </Field>
          </div>

          <Field label="Konum (haritadan seç veya restoran adı ara)">
            <MapLocationPicker
              latitude={form.latitude}
              longitude={form.longitude}
              onChange={({ latitude, longitude, address }) =>
                setForm((prev) => ({
                  ...prev,
                  latitude,
                  longitude,
                  // Adres boşsa ya da otomatik dolduysa harita sonucuyla güncelle.
                  address: address ? address : prev.address,
                }))
              }
            />
          </Field>

          <Field label="Adres">
            <input
              type="text"
              value={form.address}
              onChange={(e) => update('address', e.target.value)}
              placeholder="Haritadan seçince otomatik dolar; gerekirse düzenle"
              className={inputClass}
            />
          </Field>
        </section>

        <div className="flex justify-end gap-3">
          <button
            type="button"
            onClick={() => navigate('/super-admin/restaurants')}
            className="border border-outline-variant text-on-background font-label-md text-label-md px-5 py-3 rounded-lg hover:bg-surface-container-high transition-colors"
          >
            İptal
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="bg-primary-container text-on-primary-container font-label-md text-label-md px-6 py-3 rounded-lg hover:opacity-90 transition-opacity flex items-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {submitting ? (
              <>
                <span className="material-symbols-outlined animate-spin text-[20px]">
                  progress_activity
                </span>
                Oluşturuluyor...
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-[20px]">add_business</span>
                Restoranı Oluştur
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}

const inputClass =
  'w-full bg-surface-container-low border border-outline-variant rounded-lg py-3 px-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all';

function Field({ label, children }) {
  return (
    <label className="flex flex-col gap-1">
      <span className="font-label-sm text-label-sm text-on-surface-variant">
        {label}
      </span>
      {children}
    </label>
  );
}
