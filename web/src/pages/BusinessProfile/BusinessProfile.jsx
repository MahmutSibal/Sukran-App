import { useEffect, useMemo, useState } from 'react';
import './BusinessProfile.css';
import { useAuth } from '../../auth/AuthContext.jsx';
import { getRestaurant, updateRestaurant } from '../../api/restaurants.js';
import { getReviewsByRestaurant } from '../../api/reviews.js';

function renderStars(count) {
  return Array.from({ length: 5 }).map((_, index) => (
    <span
      key={index}
      className="material-symbols-outlined"
      style={{ fontVariationSettings: index < count ? "'FILL' 1" : "'FILL' 0" }}
    >
      star
    </span>
  ));
}

function timeAgo(dateStr) {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  const diffMs = Date.now() - date.getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 60) return `${Math.max(mins, 1)} dakika önce`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} saat önce`;
  const days = Math.floor(hours / 24);
  if (days === 1) return 'Dün';
  return `${days} gün önce`;
}

export default function BusinessProfile() {
  const { restaurantId } = useAuth();
  const [businessInfo, setBusinessInfo] = useState({
    name: '',
    address: '',
    mapsUrl: '',
    locationDescription: '',
  });
  const [restaurant, setRestaurant] = useState(null);
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);

  useEffect(() => {
    if (!restaurantId) {
      setLoading(false);
      return;
    }
    let active = true;
    setLoading(true);
    Promise.all([
      getRestaurant(restaurantId).catch(() => null),
      getReviewsByRestaurant(restaurantId).catch(() => []),
    ]).then(([r, rv]) => {
      if (!active) return;
      if (r) {
        setRestaurant(r);
        setBusinessInfo((prev) => ({
          ...prev,
          name: r.name || '',
          address: r.address || '',
        }));
      }
      setReviews(rv || []);
      setLoading(false);
    });
    return () => {
      active = false;
    };
  }, [restaurantId]);

  const { average, count } = useMemo(() => {
    if (!reviews.length) return { average: 0, count: 0 };
    const sum = reviews.reduce((acc, r) => acc + (r.rating || 0), 0);
    return { average: sum / reviews.length, count: reviews.length };
  }, [reviews]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setBusinessInfo((prev) => ({ ...prev, [name]: value }));
  };

  const handleUpdateBusiness = async () => {
    setMessage(null);
    if (!businessInfo.name.trim() || !businessInfo.address.trim()) {
      setMessage({ type: 'error', text: 'Lütfen işletme adı ve adresini doldurun.' });
      return;
    }
    setSaving(true);
    try {
      await updateRestaurant(restaurantId, {
        name: businessInfo.name.trim(),
        address: businessInfo.address.trim(),
        longitude: restaurant?.longitude ?? 0,
        latitude: restaurant?.latitude ?? 0,
      });
      setMessage({ type: 'success', text: 'İşletme bilgileri güncellendi.' });
    } catch (err) {
      setMessage({
        type: 'error',
        text: err?.message || 'İşletme bilgileri güncellenemedi.',
      });
    } finally {
      setSaving(false);
    }
  };

  const handleOpenMap = () => {
    const address = businessInfo.address;
    const mapsUrl = businessInfo.mapsUrl;
    if (!address.trim() && !mapsUrl.trim()) {
      setMessage({ type: 'error', text: 'Haritada açmak için adres girin.' });
      return;
    }
    const targetUrl = mapsUrl.trim()
      ? mapsUrl.trim()
      : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
          address.trim()
        )}`;
    window.open(targetUrl, '_blank', 'noopener,noreferrer');
  };

  const summaryCards = [
    { icon: 'verified', label: 'İşletme Rozeti', value: 'İşletme', variant: 'secondary' },
    {
      icon: 'star',
      label: 'Ortalama Puan',
      value: count ? `${average.toFixed(1)} ★` : '—',
      variant: 'default',
    },
    {
      icon: 'forum',
      label: 'Toplam Yorum',
      value: `${count} Yorum`,
      variant: 'default',
    },
    { icon: 'location_on', label: 'Harita Durumu', value: 'Aktif', variant: 'primary' },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-3 py-24 text-on-surface-variant">
        <span className="material-symbols-outlined animate-spin">progress_activity</span>
        Yükleniyor...
      </div>
    );
  }

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col gap-2">
        <h2 className="font-headline-lg text-headline-lg text-on-background">
          İşletme Profili
        </h2>
        <p className="font-body-lg text-body-lg text-on-surface-variant">
          İşletme bilgilerinizi, adresinizi, harita bağlantınızı ve müşteri
          yorumlarınızı buradan yönetebilirsiniz.
        </p>
      </section>

      {message && (
        <div
          className={`flex items-center gap-2 rounded-lg px-4 py-3 text-body-sm ${
            message.type === 'error'
              ? 'bg-error-container text-error'
              : 'bg-primary-container text-on-primary-container'
          }`}
        >
          <span className="material-symbols-outlined text-[20px]">
            {message.type === 'error' ? 'error' : 'check_circle'}
          </span>
          {message.text}
        </div>
      )}

      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-md">
        {summaryCards.map((card) => (
          <div
            key={card.label}
            className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex items-center gap-4"
          >
            <div
              className={`w-12 h-12 rounded-full flex items-center justify-center ${
                card.variant === 'secondary'
                  ? 'bg-secondary-container text-on-secondary-container'
                  : card.variant === 'primary'
                  ? 'bg-primary-container text-white'
                  : 'bg-surface-container text-primary-container'
              }`}
            >
              <span className="material-symbols-outlined">{card.icon}</span>
            </div>
            <div>
              <p className="text-label-sm text-on-surface-variant">{card.label}</p>
              <p className="font-bold text-on-background">{card.value}</p>
            </div>
          </div>
        ))}
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg">
        <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow">
          <h3 className="font-headline-sm text-headline-sm text-on-background mb-md">
            İşletme Bilgileri
          </h3>
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-1">
              <label className="text-label-sm text-on-surface-variant">İşletme Adı</label>
              <input
                name="name"
                value={businessInfo.name}
                onChange={handleChange}
                className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
                placeholder="Örn: Şükran App Restaurant"
                type="text"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-label-sm text-on-surface-variant">İşletme Adresi</label>
              <input
                name="address"
                value={businessInfo.address}
                onChange={handleChange}
                className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
                placeholder="İşletme adresinizi girin"
                type="text"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-label-sm text-on-surface-variant">
                Google Haritalar Linki
              </label>
              <input
                name="mapsUrl"
                value={businessInfo.mapsUrl}
                onChange={handleChange}
                className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
                placeholder="Google Maps bağlantısını ekleyin"
                type="text"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-label-sm text-on-surface-variant">
                Konum Açıklaması
              </label>
              <textarea
                name="locationDescription"
                value={businessInfo.locationDescription}
                onChange={handleChange}
                className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-2 px-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none h-24 resize-none"
                placeholder="Örn: Ana cadde üzerinde, otopark karşısı"
              />
            </div>
            <button
              type="button"
              onClick={handleUpdateBusiness}
              disabled={saving}
              className="mt-2 bg-primary-container text-on-primary-container font-label-md text-label-md py-3 rounded-lg hover:opacity-90 transition-opacity disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {saving && (
                <span className="material-symbols-outlined animate-spin text-[20px]">
                  progress_activity
                </span>
              )}
              Bilgileri Güncelle
            </button>
          </div>
        </section>

        <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col">
          <h3 className="font-headline-sm text-headline-sm text-on-background mb-md">
            Harita Önizleme
          </h3>
          <div className="flex-1 bg-surface-container-low rounded-lg border border-outline-variant border-dashed flex flex-col items-center justify-center p-lg text-center gap-3 min-h-[260px]">
            <span className="material-symbols-outlined text-[48px] text-on-surface-variant opacity-40">
              map
            </span>
            <div>
              <p className="font-bold text-on-background">
                {businessInfo.name || 'Harita Önizlemesi'}
              </p>
              <p className="text-body-sm text-on-surface-variant max-w-[300px] mx-auto">
                {businessInfo.address ||
                  'Google Haritalar bağlantısı eklendiğinde işletme konumu burada görüntülenecek.'}
              </p>
              {businessInfo.locationDescription && (
                <p className="text-label-sm text-on-surface-variant max-w-[300px] mx-auto mt-2">
                  {businessInfo.locationDescription}
                </p>
              )}
            </div>
          </div>
          <button
            type="button"
            onClick={handleOpenMap}
            className="mt-md border border-primary-container text-primary-container font-label-md text-label-md py-3 rounded-lg hover:bg-surface-container-low transition-colors"
          >
            Haritada Aç
          </button>
        </section>
      </div>

      <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-md mb-lg">
          <div>
            <h3 className="font-headline-sm text-headline-sm text-on-background mb-1">
              Müşteri Yorumları
            </h3>
            <div className="flex items-center gap-2 flex-wrap">
              <span className="font-bold text-headline-sm">
                {count ? `${average.toFixed(1)} / 5` : '—'}
              </span>
              <div className="flex text-secondary-container">
                {renderStars(Math.round(average))}
              </div>
              <span className="text-label-sm text-on-surface-variant">
                Ortalama Puan
              </span>
            </div>
          </div>
        </div>

        {reviews.length === 0 ? (
          <p className="text-body-md text-on-surface-variant py-6 text-center">
            Henüz yorum bulunmuyor.
          </p>
        ) : (
          <div className="flex flex-col gap-4">
            {reviews.map((review) => (
              <div
                key={review.id}
                className="p-4 border border-outline-variant rounded-lg flex flex-col gap-2"
              >
                <div className="flex justify-between items-start gap-md">
                  <div className="flex flex-col">
                    <span className="font-bold text-on-background">
                      {review.userName}
                    </span>
                    <div className="flex text-secondary-container text-[16px]">
                      {renderStars(review.rating)}
                    </div>
                  </div>
                  <span className="px-3 py-1 rounded-lg text-[11px] font-bold tracking-wider bg-primary-container text-on-primary-container">
                    YAYINLANDI
                  </span>
                </div>
                <p className="text-body-md text-on-background">"{review.comment}"</p>
                <p className="text-label-sm text-on-surface-variant">
                  {timeAgo(review.createdAt)}
                </p>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
