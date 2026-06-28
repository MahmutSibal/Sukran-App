import './ProductManagement.css';
import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext.jsx';
import { getMenuItems, deleteMenuItem, updateMenuItem } from '../../api/menuItems.js';
import { formatPrice } from '../../api/config.js';

// Backend MenuItemResponse -> UI ürün modeli
function mapMenuItem(item) {
  return {
    id: item.id,
    name: item.name,
    desc: item.recipe || (item.ingredients || []).join(', '),
    price: formatPrice(item.price),
    status: item.isAvailable ? 'AKTİF' : 'PASİF',
    statusType: item.isAvailable ? 'active' : 'passive',
    isAvailable: item.isAvailable,
    image: item.imageUrl,
    category: item.category,
    raw: item,
  };
}

const FEATURED_LABELS = [
  'Şefin Önerisi',
  'Haftanın Favorisi',
  'En Çok Satan',
  'Yeni Ürün',
];

export default function ProductManagement() {
  const navigate = useNavigate();
  const { restaurantId } = useAuth();
  const [searchTerm, setSearchTerm] = useState('');
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  // Öne çıkarma backend'de saklanmıyor; oturum içi görsel durum
  const [featured, setFeatured] = useState({});

  const loadItems = async () => {
    if (!restaurantId) {
      setError('Hesabınıza bağlı bir restoran bulunamadı.');
      setLoading(false);
      return;
    }
    setLoading(true);
    setError('');
    try {
      const data = await getMenuItems(restaurantId);
      setItems((data || []).map(mapMenuItem));
    } catch (err) {
      setError(err?.message || 'Ürünler yüklenemedi.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadItems();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [restaurantId]);

  const filteredProducts = useMemo(
    () =>
      items.filter((p) =>
        p.name.toLowerCase().includes(searchTerm.toLowerCase())
      ),
    [items, searchTerm]
  );

  const handleDelete = async (productId) => {
    if (!window.confirm('Bu ürünü silmek istediğinize emin misiniz?')) return;
    try {
      await deleteMenuItem(productId);
      setItems((prev) => prev.filter((p) => p.id !== productId));
    } catch (err) {
      alert(err?.message || 'Ürün silinemedi.');
    }
  };

  const handleEdit = (productId) => {
    navigate(`/admin/products/edit/${productId}`);
  };

  // Aktif/Pasif durumunu backend'de günceller
  const handleToggleAvailable = async (product) => {
    const item = product.raw;
    const next = !product.isAvailable;
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
      setItems((prev) =>
        prev.map((p) =>
          p.id === item.id
            ? mapMenuItem({ ...item, isAvailable: next })
            : p
        )
      );
    } catch (err) {
      alert(err?.message || 'Durum güncellenemedi.');
    }
  };

  const handleToggleFeatured = (productId) => {
    setFeatured((prev) => ({
      ...prev,
      [productId]: { ...prev[productId], on: !prev[productId]?.on },
    }));
  };

  const handleChangeFeaturedLabel = (productId, value) => {
    setFeatured((prev) => ({
      ...prev,
      [productId]: { ...prev[productId], label: value },
    }));
  };

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col md:flex-row md:items-center md:justify-between gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Ürünler
          </h2>

          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Ürünlerinizi görüntüleyin, arayın ve yeni ürün ekleyin.
          </p>
        </div>

        <button
          type="button"
          onClick={() => navigate('/admin/products/add')}
          className="bg-primary-container text-on-primary-container px-6 py-3 rounded-lg font-label-md text-label-md hover:opacity-90 transition-opacity flex items-center gap-2"
        >
          <span className="material-symbols-outlined">add</span>
          Yeni Ürün Ekle
        </button>
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
          Ürünler yükleniyor...
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
          <p className="font-body-lg text-body-lg">Henüz ürün eklenmemiş.</p>
        </div>
      )}

      {!loading && !error && filteredProducts.length > 0 && (
        <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-lg">
          {filteredProducts.map((product) => (
            <ProductCard
              key={product.id}
              product={product}
              featured={featured[product.id]}
              onDelete={handleDelete}
              onEdit={handleEdit}
              onToggleAvailable={handleToggleAvailable}
              onToggleFeatured={handleToggleFeatured}
              onChangeFeaturedLabel={handleChangeFeaturedLabel}
            />
          ))}
        </section>
      )}
    </div>
  );
}

function ProductCard({
  product,
  featured,
  onDelete,
  onEdit,
  onToggleAvailable,
  onToggleFeatured,
  onChangeFeaturedLabel,
}) {
  const isFeatured = Boolean(featured?.on);
  const featuredLabel = featured?.label || FEATURED_LABELS[0];

  return (
    <div className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden ambient-shadow hover:shadow-md transition-all group">
      <div className="p-4 pb-3 border-b border-outline-variant bg-surface-container-low">
        <div className="flex items-center justify-between gap-3">
          <div className="flex flex-col gap-1">
            <span className="font-label-sm text-label-sm text-on-surface-variant">
              Öne Çıkar
            </span>

            <select
              value={featuredLabel}
              onChange={(e) => onChangeFeaturedLabel(product.id, e.target.value)}
              className="bg-surface-container-lowest border border-outline-variant rounded-lg px-3 py-2 text-label-sm text-on-background focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none"
            >
              {FEATURED_LABELS.map((label) => (
                <option key={label}>{label}</option>
              ))}
            </select>
          </div>

          <button
            type="button"
            onClick={() => onToggleFeatured(product.id)}
            className="flex items-center gap-2"
            aria-label="Ürünü öne çıkar veya kaldır"
          >
            <span
              className={`text-label-sm font-bold ${
                isFeatured ? 'text-primary-container' : 'text-on-surface-variant'
              }`}
            >
              {isFeatured ? 'Açık' : 'Kapalı'}
            </span>

            <span
              className={`w-11 h-6 rounded-full relative transition-colors ${
                isFeatured ? 'bg-primary-container' : 'bg-surface-container-high'
              }`}
            >
              <span
                className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-all ${
                  isFeatured ? 'right-1' : 'left-1'
                }`}
              />
            </span>
          </button>
        </div>
      </div>

      <div className="h-48 overflow-hidden relative">
        <img
          alt={product.name}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          src={product.image}
        />

        {isFeatured && (
          <span className="absolute top-3 left-3 bg-secondary-container text-on-secondary-container px-3 py-1 rounded-full text-[11px] font-bold tracking-wider ambient-shadow">
            {featuredLabel}
          </span>
        )}
      </div>

      <div className="p-4">
        <div className="flex justify-between items-start mb-2 gap-3">
          <h4 className="font-bold text-body-lg text-on-background">
            {product.name}
          </h4>

          <button
            type="button"
            onClick={() => onToggleAvailable(product)}
            className={`product-status product-status-${product.statusType} cursor-pointer`}
            title="Aktif/Pasif değiştir"
          >
            {product.status}
          </button>
        </div>

        <p className="text-body-sm text-on-surface-variant mb-4 line-clamp-2">
          {product.desc}
        </p>

        <div className="flex justify-between items-center">
          <div>
            <p className="text-headline-sm font-bold text-primary-container">
              {product.price}
            </p>

            <p className="text-label-sm text-on-surface-variant">
              {product.category}
            </p>
          </div>

          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => onEdit(product.id)}
              className="p-2 rounded-lg hover:bg-surface-container-high text-on-surface-variant transition-colors"
            >
              <span className="material-symbols-outlined text-[20px]">edit</span>
            </button>

            <button
              type="button"
              onClick={() => onDelete(product.id)}
              className="p-2 rounded-lg hover:bg-error-container hover:text-error text-on-surface-variant transition-colors"
            >
              <span className="material-symbols-outlined text-[20px]">delete</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
