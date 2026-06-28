import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './AdminCategories.css';
import { useAuth } from '../../auth/AuthContext.jsx';
import { getMenuItems } from '../../api/menuItems.js';

const defaultImage =
  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800';

// Kategoriler ayrı bir varlık değil; menü ürünlerinin "category" alanından türetilir.
function deriveCategories(items) {
  const map = new Map();
  for (const item of items) {
    const key = item.category || 'Diğer';
    const entry = map.get(key) || { name: key, count: 0, image: '' };
    entry.count += 1;
    if (!entry.image && item.imageUrl) entry.image = item.imageUrl;
    map.set(key, entry);
  }
  return [...map.values()].sort((a, b) => a.name.localeCompare(b.name, 'tr'));
}

export default function AdminCategories() {
  const { restaurantId } = useAuth();
  const navigate = useNavigate();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    if (!restaurantId) {
      setError('Hesabınıza bağlı bir restoran bulunamadı.');
      setLoading(false);
      return;
    }
    let active = true;
    setLoading(true);
    getMenuItems(restaurantId)
      .then((data) => active && setItems(data || []))
      .catch((e) => active && setError(e?.message || 'Kategoriler yüklenemedi.'))
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, [restaurantId]);

  const categories = useMemo(() => deriveCategories(items), [items]);
  const filteredCategories = useMemo(
    () =>
      categories.filter((c) =>
        c.name.toLowerCase().includes(searchTerm.toLowerCase())
      ),
    [categories, searchTerm]
  );

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col md:flex-row justify-between items-start md:items-center gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Kategoriler
          </h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Menünüzdeki kategoriler ürünlerden otomatik oluşur. Yeni kategori,
            o kategoride bir ürün eklediğinizde oluşturulur.
          </p>
        </div>

        <button
          type="button"
          onClick={() => navigate('/admin/products/add')}
          className="bg-primary-container text-on-primary-container px-6 py-3 rounded-lg font-label-md text-label-md flex items-center gap-2 hover:opacity-90 transition-opacity"
        >
          <span className="material-symbols-outlined">add</span>
          Ürün Ekle
        </button>
      </section>

      <section className="relative w-full">
        <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant">
          search
        </span>
        <input
          className="w-full bg-surface-container-lowest border border-outline-variant rounded-xl py-4 pl-12 pr-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all shadow-sm"
          placeholder="Kategori ara..."
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
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

      {!loading && !error && filteredCategories.length === 0 && (
        <div className="flex flex-col items-center justify-center gap-2 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined text-[40px]">category</span>
          <p className="font-body-lg text-body-lg">Henüz kategori bulunmuyor.</p>
        </div>
      )}

      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-md">
        {filteredCategories.map((category) => (
          <div
            key={category.name}
            className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden ambient-shadow hover:shadow-md transition-all group"
          >
            <div className="h-40 overflow-hidden">
              <img
                alt={category.name}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                src={category.image || defaultImage}
              />
            </div>
            <div className="p-md">
              <h4 className="font-headline-sm text-headline-sm text-on-background mb-1">
                {category.name}
              </h4>
              <p className="font-body-sm text-body-sm text-on-surface-variant mb-md">
                {category.count} ürün
              </p>
              <button
                type="button"
                onClick={() => navigate('/admin/products')}
                className="w-full flex items-center justify-center gap-2 py-2 border border-outline-variant rounded-lg text-label-md font-label-md hover:bg-surface-container-low transition-colors"
              >
                <span className="material-symbols-outlined text-[18px]">inventory_2</span>
                Ürünleri Gör
              </button>
            </div>
          </div>
        ))}
      </section>
    </div>
  );
}
