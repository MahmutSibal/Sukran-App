import { useEffect, useMemo, useState } from 'react';
import { useParams } from 'react-router-dom';
import {
  startQrSession,
  getRestaurantPublic,
  getMenu,
  placeOrder,
} from '../../api/customer.js';
import {
  formatPrice,
  OrderItemStatus,
  PaymentStatus,
} from '../../api/config.js';

// QR ile açılan müşteri menü & sipariş sayfası.
// URL: /t/:restaurantId/:tableNo/:qrToken
export default function CustomerTable() {
  const { restaurantId, tableNo, qrToken } = useParams();

  const [phase, setPhase] = useState('loading'); // loading | ready | error
  const [errorMsg, setErrorMsg] = useState('');
  const [session, setSession] = useState(null); // { accessToken, tableSessionId }
  const [restaurant, setRestaurant] = useState(null);
  const [menu, setMenu] = useState([]);
  const [cart, setCart] = useState({}); // menuItemId -> qty
  const [placing, setPlacing] = useState(false);
  const [placedCount, setPlacedCount] = useState(0);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const s = await startQrSession({ restaurantId, tableNo, qrToken });
        if (!active) return;
        setSession(s);
        // Restoran + menü paralel (anonim).
        const [r, m] = await Promise.all([
          getRestaurantPublic(restaurantId).catch(() => null),
          getMenu(restaurantId).catch(() => []),
        ]);
        if (!active) return;
        setRestaurant(r);
        setMenu((m || []).filter((item) => item.isAvailable));
        setPhase('ready');
      } catch (e) {
        if (!active) return;
        setErrorMsg(
          e?.status === 400 || /session/i.test(e?.message || '')
            ? 'Bu masa şu an kapalı veya QR kodu geçersiz. Lütfen garsondan masayı açmasını isteyin.'
            : e?.message || 'Bağlantı kurulamadı.'
        );
        setPhase('error');
      }
    })();
    return () => {
      active = false;
    };
  }, [restaurantId, tableNo, qrToken]);

  const categories = useMemo(() => {
    const map = new Map();
    for (const item of menu) {
      const key = item.category || 'Diğer';
      if (!map.has(key)) map.set(key, []);
      map.get(key).push(item);
    }
    return Array.from(map.entries());
  }, [menu]);

  const cartLines = useMemo(
    () =>
      Object.entries(cart)
        .filter(([, qty]) => qty > 0)
        .map(([id, qty]) => ({
          item: menu.find((m) => m.id === id),
          qty,
        }))
        .filter((l) => l.item),
    [cart, menu]
  );

  const total = cartLines.reduce((sum, l) => sum + l.item.price * l.qty, 0);
  const itemCount = cartLines.reduce((sum, l) => sum + l.qty, 0);

  const inc = (id) => setCart((c) => ({ ...c, [id]: (c[id] || 0) + 1 }));
  const dec = (id) =>
    setCart((c) => ({ ...c, [id]: Math.max(0, (c[id] || 0) - 1) }));

  const submitOrder = async () => {
    if (itemCount === 0 || placing || !session) return;
    setPlacing(true);
    try {
      // Her adet ayrı bir sipariş kalemi (backend modeli adet tutmaz).
      const items = cartLines.flatMap((line) =>
        Array.from({ length: line.qty }, () => ({
          menuItemId: line.item.id,
          name: line.item.name,
          price: line.item.price,
          orderedBy: `Masa ${tableNo}`,
          status: OrderItemStatus.Pending,
          paymentStatus: PaymentStatus.Unpaid,
        }))
      );

      await placeOrder(
        {
          restaurantId,
          tableNo: Number(tableNo),
          tableSessionId: session.tableSessionId,
          qrToken,
          items,
        },
        session.accessToken
      );

      setPlacedCount((n) => n + itemCount);
      setCart({});
    } catch (e) {
      alert(e?.message || 'Sipariş gönderilemedi. Lütfen tekrar deneyin.');
    } finally {
      setPlacing(false);
    }
  };

  if (phase === 'loading') {
    return (
      <Centered>
        <span className="material-symbols-outlined animate-spin text-[40px] text-primary-container">
          progress_activity
        </span>
        <p className="text-body-md text-on-surface-variant">Masa açılıyor...</p>
      </Centered>
    );
  }

  if (phase === 'error') {
    return (
      <Centered>
        <span className="material-symbols-outlined text-[48px] text-error">
          error
        </span>
        <p className="text-body-lg text-on-background text-center max-w-[320px]">
          {errorMsg}
        </p>
      </Centered>
    );
  }

  return (
    <div className="min-h-screen bg-background text-on-background pb-28">
      {/* Başlık */}
      <header className="sticky top-0 z-10 bg-surface-container-lowest border-b border-outline-variant px-4 py-4">
        <div className="max-w-[640px] mx-auto flex items-center gap-3">
          <span className="material-symbols-outlined text-primary-container text-[32px]">
            restaurant
          </span>
          <div>
            <h1 className="font-headline-sm text-headline-sm leading-tight">
              {restaurant?.name || 'Menü'}
            </h1>
            <p className="text-label-sm text-on-surface-variant">
              Masa {tableNo}
            </p>
          </div>
        </div>
      </header>

      {placedCount > 0 && (
        <div className="max-w-[640px] mx-auto px-4 pt-4">
          <div className="flex items-center gap-2 bg-primary-container text-on-primary-container rounded-lg px-4 py-3 text-body-sm">
            <span className="material-symbols-outlined text-[20px]">check_circle</span>
            {placedCount} ürünlük siparişiniz mutfağa iletildi. Afiyet olsun!
          </div>
        </div>
      )}

      {/* Menü */}
      <main className="max-w-[640px] mx-auto px-4 py-4 flex flex-col gap-6">
        {categories.length === 0 && (
          <p className="text-center text-on-surface-variant py-12">
            Bu restoranda henüz menü ürünü yok.
          </p>
        )}

        {categories.map(([category, items]) => (
          <section key={category} className="flex flex-col gap-3">
            <h2 className="font-headline-sm text-headline-sm text-on-background">
              {category}
            </h2>
            <div className="flex flex-col gap-2">
              {items.map((item) => (
                <div
                  key={item.id}
                  className="bg-surface-container-lowest border border-outline-variant rounded-xl p-3 flex items-center gap-3"
                >
                  {item.imageUrl ? (
                    <img
                      src={item.imageUrl}
                      alt={item.name}
                      className="w-16 h-16 rounded-lg object-cover flex-shrink-0"
                    />
                  ) : (
                    <div className="w-16 h-16 rounded-lg bg-surface-container-high flex items-center justify-center flex-shrink-0">
                      <span className="material-symbols-outlined text-on-surface-variant">
                        lunch_dining
                      </span>
                    </div>
                  )}

                  <div className="flex-1 min-w-0">
                    <h3 className="font-label-md text-label-md truncate">
                      {item.name}
                    </h3>
                    <p className="text-body-sm text-primary-container font-bold">
                      {formatPrice(item.price)}
                    </p>
                  </div>

                  {cart[item.id] > 0 ? (
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => dec(item.id)}
                        className="w-9 h-9 rounded-full border border-outline-variant flex items-center justify-center hover:bg-surface-container-high"
                        aria-label="Azalt"
                      >
                        <span className="material-symbols-outlined text-[20px]">remove</span>
                      </button>
                      <span className="w-6 text-center font-label-md">
                        {cart[item.id]}
                      </span>
                      <button
                        type="button"
                        onClick={() => inc(item.id)}
                        className="w-9 h-9 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center hover:opacity-90"
                        aria-label="Artır"
                      >
                        <span className="material-symbols-outlined text-[20px]">add</span>
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => inc(item.id)}
                      className="px-4 h-9 rounded-full bg-primary-container text-on-primary-container text-label-md flex items-center gap-1 hover:opacity-90"
                    >
                      <span className="material-symbols-outlined text-[18px]">add</span>
                      Ekle
                    </button>
                  )}
                </div>
              ))}
            </div>
          </section>
        ))}
      </main>

      {/* Sepet / Sipariş çubuğu */}
      {itemCount > 0 && (
        <div className="fixed bottom-0 left-0 right-0 z-20 bg-surface-container-lowest border-t border-outline-variant px-4 py-3">
          <div className="max-w-[640px] mx-auto">
            <button
              type="button"
              onClick={submitOrder}
              disabled={placing}
              className="w-full bg-primary-container text-on-primary-container rounded-xl py-4 flex items-center justify-between px-5 hover:opacity-90 transition-opacity disabled:opacity-60"
            >
              <span className="flex items-center gap-2 font-label-md text-label-md">
                <span className="material-symbols-outlined">
                  {placing ? 'progress_activity' : 'shopping_cart'}
                </span>
                <span className={placing ? 'animate-pulse' : ''}>
                  {placing ? 'Gönderiliyor...' : `${itemCount} ürün — Sipariş Ver`}
                </span>
              </span>
              <span className="font-headline-sm text-headline-sm">
                {formatPrice(total)}
              </span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function Centered({ children }) {
  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center gap-3 px-4">
      {children}
    </div>
  );
}
