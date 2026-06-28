import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext.jsx';
import {
  getMenuItem,
  createMenuItem,
  updateMenuItem,
} from '../../api/menuItems.js';
import { toMinorAmount } from '../../api/config.js';
import '../AddProduct/AddProduct.css';

const CATEGORY_OPTIONS = [
  'Kahveler',
  'Tatlılar',
  'Kruvasanlar',
  'Soğuk İçecekler',
  'Sıcak İçecekler',
];

export default function AddProduct() {
  const navigate = useNavigate();
  const { productId } = useParams();
  const { restaurantId } = useAuth();
  const fileInputRef = useRef(null);

  const isEditMode = Boolean(productId);

  const [form, setForm] = useState({
    category: '',
    name: '',
    desc: '',
    price: '',
    stock: '',
    statusType: 'active',
    image: '',
    averagePreparationTime: 0,
    ingredients: [],
  });
  const [preview, setPreview] = useState('');
  const [loading, setLoading] = useState(isEditMode);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  // Düzenleme modunda ürünü backend'den yükle
  useEffect(() => {
    if (!isEditMode) return;
    let active = true;
    setLoading(true);
    getMenuItem(productId)
      .then((item) => {
        if (!active || !item) return;
        setForm({
          category: item.category || '',
          name: item.name || '',
          desc: item.recipe || (item.ingredients || []).join(', '),
          price: item.price != null ? String(item.price / 100) : '',
          stock: '',
          statusType: item.isAvailable ? 'active' : 'soldout',
          image: item.imageUrl || '',
          averagePreparationTime: item.averagePreparationTime || 0,
          ingredients: item.ingredients || [],
        });
        setPreview(item.imageUrl || '');
      })
      .catch((err) => active && setError(err?.message || 'Ürün yüklenemedi.'))
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, [isEditMode, productId]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleImageSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    // Sadece önizleme; kalıcı değer "Görsel URL" alanından gelir.
    setPreview(URL.createObjectURL(file));
  };

  const handleCancel = () => {
    navigate('/admin/products');
  };

  const handleSave = async () => {
    setError('');
    if (!form.category || !form.name.trim() || !form.desc.trim() || !form.price) {
      setError('Lütfen kategori, ad, açıklama ve fiyat alanlarını doldurun.');
      return;
    }
    if (!form.image.trim()) {
      setError('Lütfen geçerli bir görsel URL girin (yüklenen dosya kaydedilmez).');
      return;
    }
    if (!restaurantId) {
      setError('Hesabınıza bağlı bir restoran bulunamadı.');
      return;
    }

    const payload = {
      category: form.category,
      name: form.name.trim(),
      imageUrl: form.image.trim(),
      ingredients: form.ingredients || [],
      recipe: form.desc.trim(),
      averagePreparationTime: Number(form.averagePreparationTime) || 0,
      price: toMinorAmount(form.price),
      isAvailable: form.statusType === 'active',
    };

    setSaving(true);
    try {
      if (isEditMode) {
        await updateMenuItem(productId, payload);
      } else {
        await createMenuItem({ restaurantId, ...payload });
      }
      navigate('/admin/products');
    } catch (err) {
      setError(err?.message || 'Ürün kaydedilemedi.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-3 py-24 text-on-surface-variant">
        <span className="material-symbols-outlined animate-spin">progress_activity</span>
        Ürün yükleniyor...
      </div>
    );
  }

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section>
        <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
          Ürün Yönetimi
        </h2>
        <p className="font-body-lg text-body-lg text-on-surface-variant">
          Yeni ürün ekleyin veya mevcut ürün bilgilerini güncelleyin.
        </p>
      </section>

      {error && (
        <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
          <span className="material-symbols-outlined text-[20px]">error</span>
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg">
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col items-center justify-center gap-md h-[400px] lg:h-full">
          <div className="w-24 h-24 rounded-full bg-surface-container flex items-center justify-center text-on-surface-variant overflow-hidden">
            {preview || form.image ? (
              <img
                src={preview || form.image}
                alt="Ürün görseli"
                className="w-full h-full object-cover"
              />
            ) : (
              <span className="material-symbols-outlined text-[48px]">add_a_photo</span>
            )}
          </div>

          <div className="text-center">
            <p className="font-headline-sm text-headline-sm text-on-background mb-1">
              Ürün Görseli
            </p>
            <p className="font-body-sm text-body-sm text-on-surface-variant">
              Görsel adresini (URL) aşağıya girin
            </p>
          </div>

          <div className="w-full max-w-[320px]">
            <input
              name="image"
              value={form.image}
              onChange={handleChange}
              className="admin-input"
              placeholder="https://.../gorsel.jpg"
              type="url"
            />
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/png,image/jpeg,image/webp"
            className="hidden"
            onChange={handleImageSelect}
          />

          <button
            type="button"
            onClick={() => fileInputRef.current.click()}
            className="text-on-surface-variant text-label-sm underline"
          >
            Dosya seç (yalnızca önizleme)
          </button>
        </div>

        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col gap-md">
          <h3 className="font-headline-sm text-headline-sm text-on-background border-l-4 border-secondary-container pl-3">
            Ürün Bilgileri
          </h3>

          <div className="flex flex-col gap-6">
            <Field label="Kategori">
              <select
                name="category"
                value={form.category}
                onChange={handleChange}
                className="admin-input"
              >
                <option value="">Ürün kategorisi seçin</option>
                {CATEGORY_OPTIONS.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
                {form.category && !CATEGORY_OPTIONS.includes(form.category) && (
                  <option value={form.category}>{form.category}</option>
                )}
              </select>
            </Field>

            <Field label="Ürün Adı">
              <input
                name="name"
                value={form.name}
                onChange={handleChange}
                className="admin-input"
                placeholder="Örn: Izgara Köfte"
                type="text"
              />
            </Field>

            <Field label="Açıklama">
              <textarea
                name="desc"
                value={form.desc}
                onChange={handleChange}
                className="admin-input resize-none"
                placeholder="Ürün içeriği ve detayları..."
                rows="3"
              />
            </Field>

            <div className="grid grid-cols-2 gap-4">
              <Field label="Fiyat (₺)">
                <input
                  name="price"
                  value={form.price}
                  onChange={handleChange}
                  className="admin-input"
                  placeholder="0.00"
                  type="number"
                />
              </Field>

              <Field label="Hazırlık Süresi (dk)">
                <input
                  name="averagePreparationTime"
                  value={form.averagePreparationTime}
                  onChange={handleChange}
                  className="admin-input"
                  placeholder="0"
                  type="number"
                />
              </Field>
            </div>

            <div className="flex flex-col gap-2">
              <label className="font-label-md text-label-md text-on-surface-variant">
                Ürün Durumu
              </label>

              <div className="flex bg-surface-container-low p-1 rounded-lg w-fit">
                <button
                  type="button"
                  onClick={() => setForm((p) => ({ ...p, statusType: 'active' }))}
                  className={`px-6 py-2 rounded-md font-label-md text-label-md ${
                    form.statusType === 'active'
                      ? 'bg-primary-container text-on-primary-container'
                      : 'text-on-surface-variant hover:bg-surface-container-high transition-colors'
                  }`}
                >
                  Aktif
                </button>

                <button
                  type="button"
                  onClick={() => setForm((p) => ({ ...p, statusType: 'soldout' }))}
                  className={`px-6 py-2 rounded-md font-label-md text-label-md ${
                    form.statusType === 'soldout'
                      ? 'bg-primary-container text-on-primary-container'
                      : 'text-on-surface-variant hover:bg-surface-container-high transition-colors'
                  }`}
                >
                  Pasif
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="flex justify-end gap-md pt-md">
        <button
          type="button"
          onClick={handleCancel}
          className="px-8 py-3 rounded-lg border border-outline-variant text-on-surface-variant font-label-md text-label-md hover:bg-surface-container-high transition-colors"
        >
          Vazgeç
        </button>

        <button
          type="button"
          onClick={handleSave}
          disabled={saving}
          className="px-8 py-3 rounded-lg bg-primary-container text-on-primary-container font-label-md text-label-md hover:opacity-90 transition-opacity flex items-center gap-2 disabled:opacity-60"
        >
          {saving && (
            <span className="material-symbols-outlined animate-spin text-[20px]">
              progress_activity
            </span>
          )}
          {isEditMode ? 'Ürünü Güncelle' : 'Ürünü Kaydet'}
        </button>
      </div>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div className="flex flex-col gap-1">
      <label className="font-label-md text-label-md text-on-surface-variant">
        {label}
      </label>
      {children}
    </div>
  );
}
