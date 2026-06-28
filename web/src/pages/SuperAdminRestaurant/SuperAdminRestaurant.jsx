import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './SuperAdminRestaurant.css';
import { getAllRestaurants } from '../../api/restaurants.js';
import { getReviewsByRestaurant } from '../../api/reviews.js';

export default function SuperAdminRestaurant() {
  const [searchTerm, setSearchTerm] = useState('');
  const [restaurants, setRestaurants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    let active = true;
    getAllRestaurants()
      .then(async (list) => {
        const withStats = await Promise.all(
          (list || []).map(async (r) => {
            const reviews = await getReviewsByRestaurant(r.id).catch(() => []);
            const count = reviews.length;
            const avg = count
              ? reviews.reduce((a, x) => a + (x.rating || 0), 0) / count
              : 0;
            return { ...r, reviewCount: count, rating: avg };
          })
        );
        if (active) setRestaurants(withStats);
      })
      .catch((e) => active && setError(e?.message || 'Restoranlar yüklenemedi.'))
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, []);

  const filteredRestaurants = useMemo(
    () =>
      restaurants.filter((r) =>
        r.name.toLowerCase().includes(searchTerm.toLowerCase())
      ),
    [restaurants, searchTerm]
  );

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col gap-md">
        <div className="flex flex-wrap items-start justify-between gap-md">
          <div>
            <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
              Restoranlar
            </h2>
            <p className="font-body-md text-body-md text-on-surface-variant">
              Platforma kayıtlı restoranları, puanlarını ve yorum sayılarını
              buradan inceleyebilirsiniz.
            </p>
          </div>
          <button
            type="button"
            onClick={() => navigate('/super-admin/restaurants/new')}
            className="bg-primary-container text-on-primary-container font-label-md text-label-md px-5 py-3 rounded-lg hover:opacity-90 transition-opacity flex items-center gap-2 whitespace-nowrap"
          >
            <span className="material-symbols-outlined text-[20px]">add_business</span>
            Yeni Restoran
          </button>
        </div>

        <div className="relative max-w-md">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant">
            search
          </span>
          <input
            className="w-full bg-surface-container-lowest border border-outline-variant rounded-lg py-3 pl-10 pr-4 text-body-sm focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all shadow-sm"
            placeholder="Restoran ara..."
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

      {!loading && !error && filteredRestaurants.length === 0 && (
        <div className="flex flex-col items-center justify-center gap-2 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined text-[40px]">storefront</span>
          <p className="font-body-lg text-body-lg">Restoran bulunamadı.</p>
        </div>
      )}

      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-md">
        {filteredRestaurants.map((restaurant) => (
          <div
            key={restaurant.id}
            className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col gap-md hover:border-primary-container transition-colors"
          >
            <div className="flex justify-between items-start gap-md">
              <span className="px-3 py-1 rounded-full text-[11px] font-bold tracking-wider bg-primary-container text-on-primary-container">
                AKTİF
              </span>
              <div className="flex items-center gap-1 text-secondary">
                <span
                  className="material-symbols-outlined text-[18px]"
                  style={{ fontVariationSettings: "'FILL' 1" }}
                >
                  stars
                </span>
                <span className="font-label-md text-label-md">
                  {restaurant.rating ? restaurant.rating.toFixed(1) : '—'}
                </span>
              </div>
            </div>

            <div>
              <h3 className="font-headline-sm text-headline-sm text-on-background mb-1">
                {restaurant.name}
              </h3>
              <div className="flex items-center gap-2 text-on-surface-variant">
                <span className="material-symbols-outlined text-[18px]">location_on</span>
                <span className="font-body-sm text-body-sm font-medium">
                  {restaurant.address || '—'}
                </span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 py-3 border-y border-outline-variant">
              <div className="flex flex-col">
                <span className="text-[11px] text-on-surface-variant uppercase tracking-tight">
                  Yorum
                </span>
                <span className="font-label-md text-label-md">
                  {restaurant.reviewCount}
                </span>
              </div>
              <div className="flex flex-col">
                <span className="text-[11px] text-on-surface-variant uppercase tracking-tight">
                  Puan
                </span>
                <span className="font-label-md text-label-md">
                  {restaurant.rating ? `${restaurant.rating.toFixed(1)} / 5` : '—'}
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={() => navigate(`/super-admin/restaurants/${restaurant.id}`)}
              className="w-full bg-primary-container text-on-primary-container font-label-md text-label-md py-3 rounded-lg hover:opacity-90 transition-opacity"
            >
              Detayları Gör
            </button>
          </div>
        ))}
      </section>
    </div>
  );
}
