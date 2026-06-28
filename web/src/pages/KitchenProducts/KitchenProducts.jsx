import './KitchenProducts.css';
import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../../auth/AuthContext.jsx';
import { getMenuItems, updateMenuItem } from '../../api/menuItems.js';
import { formatPrice } from '../../api/config.js';

function mapItem(item) {
  return {
    id: item.id,
    name: item.name,
    desc: item.recipe || (item.ingredients || []).join(', '),
    price: formatPrice(item.price),
    status: item.isAvailable ? 'AKTİF' : 'TÜKENDİ',
    statusType: item.isAvailable ? 'active' : 'soldout',
    category: item.category,
    image: item.imageUrl,
    raw: item,
  };
}

export default function KitchenProducts() {
  const { restaurantId } = useAuth();
  const [productList, setProductList] = useState([]);
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
      .then((data) => active && setProductList((data || []).map(mapItem)))
      .catch((e) => active && setError(e?.message || 'Ürünler yüklenemedi.'))
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, [restaurantId]);

  const filteredProducts = useMemo(
    () =>
      productList.filter((p) =>
        p.name.toLowerCase().includes(searchTerm.toLowerCase())
      ),
    [productList, searchTerm]
  );

  const handleToggleAvailability = async (product) => {
    const item = product.raw;
    const next = !item.isAvailable;
    try {
      await updateMenuItem(item.id, {
        category: item.category,
        name: item.name,
        imageUrl: item.imageUrl,
        ingredients: item.ingredients || [],
        recipe: item.recipe || null,
        averagePreparationTime: item.averagePreparationTime || 0,
        price: item.price,
        isAvailable: next,
      });
      setProductList((prev) =>
        prev.map((p) =>
          p.id === item.id ? mapItem({ ...item, isAvailable: next }) : p
        )
      );
    } catch (err) {
      alert(err?.message || 'Durum güncellenemedi.');
    }
  };

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Mutfak Ürünleri
          </h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Mutfak tarafında ürün durumlarını takip edebilir, ürünleri aktif
            veya tükendi olarak işaretleyebilirsiniz.
          </p>
        </div>

        <div className="grid grid-cols-3 gap-sm w-full lg:w-auto">
          <Stat label="Toplam" value={productList.length} />
          <Stat
            label="Aktif"
            value={productList.filter((p) => p.statusType === 'active').length}
          />
          <Stat
            label="Tükendi"
            value={productList.filter((p) => p.statusType === 'soldout').length}
          />
        </div>
      </section>

      <section className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow">
        <div className="relative">
          <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant">
            search
          </span>
          <input
            className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-3 pl-12 pr-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all"
            placeholder="Ürün ara..."
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

      {!loading && !error && filteredProducts.length === 0 && (
        <div className="flex flex-col items-center justify-center gap-2 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined text-[40px]">inventory_2</span>
          <p className="font-body-lg text-body-lg">Ürün bulunamadı.</p>
        </div>
      )}

      <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-lg">
        {filteredProducts.map((product) => (
          <KitchenProductCard
            key={product.id}
            product={product}
            onToggleAvailability={handleToggleAvailability}
          />
        ))}
      </section>
    </div>
  );
}

function Stat({ label, value }) {
  return (
    <div className="bg-surface-container-lowest border border-outline-variant rounded-xl px-4 py-3 ambient-shadow">
      <p className="text-label-sm text-on-surface-variant">{label}</p>
      <p className="font-headline-sm text-headline-sm text-on-background">{value}</p>
    </div>
  );
}

function KitchenProductCard({ product, onToggleAvailability }) {
  const isSoldOut = product.statusType === 'soldout';

  return (
    <div
      className={`bg-surface-container-lowest border rounded-xl overflow-hidden ambient-shadow hover:shadow-md transition-all group ${
        isSoldOut ? 'border-error-container opacity-90' : 'border-outline-variant'
      }`}
    >
      <div className="h-48 overflow-hidden relative">
        <img
          alt={product.name}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          src={product.image}
        />
        {isSoldOut && (
          <div className="absolute inset-0 bg-black/45 flex items-center justify-center">
            <span className="bg-error text-on-error px-4 py-2 rounded-full text-label-sm font-bold">
              TÜKENDİ
            </span>
          </div>
        )}
      </div>

      <div className="p-4">
        <div className="flex justify-between items-start mb-2 gap-3">
          <div>
            <h4 className="font-bold text-body-lg text-on-background">{product.name}</h4>
            <p className="text-label-sm text-on-surface-variant">{product.category}</p>
          </div>
          <span className={`product-status product-status-${product.statusType}`}>
            {product.status}
          </span>
        </div>

        <p className="text-body-sm text-on-surface-variant mb-4 line-clamp-2">
          {product.desc}
        </p>

        <p className="text-headline-sm font-bold text-primary-container mb-4">
          {product.price}
        </p>

        <button
          type="button"
          onClick={() => onToggleAvailability(product)}
          className={`w-full px-4 py-3 rounded-lg font-label-md text-label-md transition-opacity ${
            isSoldOut
              ? 'bg-primary-container text-on-primary-container hover:opacity-90'
              : 'bg-error-container text-on-error-container hover:opacity-90'
          }`}
        >
          {isSoldOut ? 'Tekrar Aktif Yap' : 'Tükendi Olarak İşaretle'}
        </button>
      </div>
    </div>
  );
}
