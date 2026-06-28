import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import './SuperAdminRestaurantDetail.css';
import { getRestaurant } from '../../api/restaurants.js';
import { getUsers } from '../../api/users.js';
import { getReviewsByRestaurant } from '../../api/reviews.js';
import { USER_ROLE_LABELS, UserRole } from '../../api/config.js';

function renderStars(count) {
  return Array.from({ length: 5 }).map((_, index) => (
    <span
      key={index}
      className="material-symbols-outlined text-[16px]"
      style={{ fontVariationSettings: index < count ? "'FILL' 1" : "'FILL' 0" }}
    >
      star
    </span>
  ));
}

function initialsOf(name = '') {
  return (
    name
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map((p) => p[0]?.toUpperCase())
      .join('.') + '.'
  );
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('tr-TR');
}

export default function SuperAdminRestaurantDetail() {
  const { restaurantId } = useParams();
  const [restaurant, setRestaurant] = useState(null);
  const [owner, setOwner] = useState(null);
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [isSystemActive, setIsSystemActive] = useState(true);

  useEffect(() => {
    let active = true;
    setLoading(true);
    Promise.all([
      getRestaurant(restaurantId).catch(() => null),
      getUsers().catch(() => []),
      getReviewsByRestaurant(restaurantId).catch(() => []),
    ])
      .then(([r, users, rv]) => {
        if (!active) return;
        if (!r) {
          setError('Restoran bulunamadı.');
          return;
        }
        setRestaurant(r);
        setOwner(
          (users || []).find(
            (u) => u.restaurantId === restaurantId && u.role === UserRole.RestaurantOwner
          ) || null
        );
        setReviews(rv || []);
      })
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, [restaurantId]);

  const { average, count } = useMemo(() => {
    if (!reviews.length) return { average: 0, count: 0 };
    const sum = reviews.reduce((a, r) => a + (r.rating || 0), 0);
    return { average: sum / reviews.length, count: reviews.length };
  }, [reviews]);

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-3 py-24 text-on-surface-variant">
        <span className="material-symbols-outlined animate-spin">progress_activity</span>
        Yükleniyor...
      </div>
    );
  }

  if (error || !restaurant) {
    return (
      <div className="max-w-[1400px] mx-auto flex flex-col gap-md">
        <Link
          to="/super-admin/restaurants"
          className="inline-flex items-center gap-2 text-primary-container font-label-md text-label-md hover:underline"
        >
          <span className="material-symbols-outlined text-[20px]">arrow_back</span>
          Restoranlara Geri Dön
        </Link>
        <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
          <span className="material-symbols-outlined text-[20px]">error</span>
          {error || 'Restoran bulunamadı.'}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <div>
        <Link
          to="/super-admin/restaurants"
          className="inline-flex items-center gap-2 text-primary-container font-label-md text-label-md hover:underline mb-md"
        >
          <span className="material-symbols-outlined text-[20px]">arrow_back</span>
          Restoranlara Geri Dön
        </Link>
      </div>

      <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col md:flex-row justify-between gap-md">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-lg bg-primary-container flex items-center justify-center text-white">
              <span className="material-symbols-outlined text-[32px]">restaurant</span>
            </div>
            <div>
              <h2 className="font-headline-md text-headline-md text-on-background">
                {restaurant.name}
              </h2>
              <p className="font-body-sm text-body-sm text-on-surface-variant">
                {restaurant.slug}
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-y-3 gap-x-8">
            <InfoItem icon="location_on" text={restaurant.address || '—'} />
            <InfoItem
              icon="person"
              text={
                owner
                  ? `${USER_ROLE_LABELS[UserRole.RestaurantOwner]}: ${owner.name}`
                  : 'İşletme sahibi atanmamış'
              }
            />
            {owner && <InfoItem icon="mail" text={owner.email} />}
            <InfoItem
              icon="my_location"
              text={`${restaurant.latitude?.toFixed?.(5) ?? '—'}, ${
                restaurant.longitude?.toFixed?.(5) ?? '—'
              }`}
            />
          </div>
        </div>

        <div className="md:w-64 flex flex-col items-center md:items-end justify-center border-t md:border-t-0 md:border-l border-outline-variant pt-md md:pt-0 md:pl-md">
          <p className="font-label-md text-label-md text-on-surface-variant mb-2">
            Sistem Durumu
          </p>
          <div className="flex items-center gap-3 bg-surface-container px-4 py-2 rounded-full">
            <span
              className={`w-3 h-3 rounded-full ${
                isSystemActive ? 'bg-primary' : 'bg-error'
              }`}
            />
            <span
              className={`font-label-md text-label-md ${
                isSystemActive ? 'text-primary' : 'text-error'
              }`}
            >
              {isSystemActive ? 'Sistem Açık' : 'Sistem Kapalı'}
            </span>
            <button
              type="button"
              onClick={() => setIsSystemActive((prev) => !prev)}
              className={`w-10 h-5 rounded-full relative transition-colors ${
                isSystemActive ? 'bg-primary' : 'bg-surface-container-high'
              }`}
            >
              <span
                className={`absolute top-1/2 -translate-y-1/2 w-3 h-3 bg-white rounded-full transition-all ${
                  isSystemActive ? 'right-1' : 'left-1'
                }`}
              />
            </button>
          </div>
        </div>
      </section>

      <section className="flex flex-col gap-md">
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col md:flex-row items-center gap-lg">
          <div className="text-center md:border-r border-outline-variant md:pr-lg">
            <p className="text-[48px] font-bold text-on-background leading-none">
              {count ? average.toFixed(1) : '—'}
            </p>
            <div className="flex justify-center text-secondary-container my-2">
              {renderStars(Math.round(average))}
            </div>
            <p className="font-label-sm text-label-sm text-on-surface-variant">
              5 üzerinden puanlama
            </p>
          </div>

          <div className="flex-1 grid grid-cols-1 sm:grid-cols-2 gap-md w-full">
            <div className="bg-surface-container-low p-4 rounded-lg text-center">
              <p className="font-headline-sm text-headline-sm text-primary">{count}</p>
              <p className="font-label-sm text-label-sm text-on-surface-variant">
                Toplam Yorum
              </p>
            </div>
            <div className="bg-surface-container-low p-4 rounded-lg text-center">
              <p className="font-headline-sm text-headline-sm text-primary">
                {count ? `${average.toFixed(1)} / 5` : '—'}
              </p>
              <p className="font-label-sm text-label-sm text-on-surface-variant">
                Ortalama Puan
              </p>
            </div>
          </div>
        </div>

        {reviews.length === 0 ? (
          <p className="text-body-md text-on-surface-variant py-6 text-center">
            Henüz yorum bulunmuyor.
          </p>
        ) : (
          <div className="flex flex-col gap-sm">
            {reviews.map((comment) => (
              <div
                key={comment.id}
                className="bg-surface-container-lowest border border-outline-variant rounded-xl p-4 ambient-shadow"
              >
                <div className="flex justify-between items-start mb-2 gap-md">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full bg-surface-container flex items-center justify-center font-bold text-primary text-xs">
                      {initialsOf(comment.userName)}
                    </div>
                    <span className="font-label-md text-label-md text-on-background">
                      {comment.userName}
                    </span>
                  </div>
                  <span className="font-label-sm text-label-sm text-on-surface-variant">
                    {formatDate(comment.createdAt)}
                  </span>
                </div>
                <div className="flex text-secondary-container mb-2">
                  {renderStars(comment.rating)}
                </div>
                <p className="font-body-sm text-body-sm text-on-surface-variant">
                  {comment.comment}
                </p>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function InfoItem({ icon, text }) {
  return (
    <div className="flex items-center gap-2 text-on-surface-variant">
      <span className="material-symbols-outlined text-[20px]">{icon}</span>
      <span className="font-body-md text-body-md">{text}</span>
    </div>
  );
}
