import { useMemo, useState } from 'react';
import './KitchenPanel.css';
import { useAuth } from '../../auth/AuthContext.jsx';
import { useRestaurantOrders } from '../../hooks/useRestaurantOrders.js';
import { updateOrderItemStatus } from '../../api/orders.js';
import { isActiveOrder } from '../../api/orderHelpers.js';
import { formatPrice, OrderItemStatus } from '../../api/config.js';

// Bir siparişin tüm kalemlerini hedef duruma getirir.
async function setAllItems(order, status) {
  await Promise.all(
    order.items.map((item) =>
      updateOrderItemStatus(order.id, item.orderItemId, status)
    )
  );
}

export default function KitchenPanel() {
  const { restaurantId } = useAuth();
  const { orders, loading, error, live, reload } = useRestaurantOrders(restaurantId);
  const [searchTerm, setSearchTerm] = useState('');
  const [busyId, setBusyId] = useState(null);

  const activeOrders = useMemo(
    () =>
      orders
        .filter(isActiveOrder)
        .filter((o) =>
          o.tableName.toLowerCase().includes(searchTerm.toLowerCase())
        ),
    [orders, searchTerm]
  );

  const newCount = activeOrders.filter(
    (o) => o.derivedStatus <= OrderItemStatus.Kitchen
  ).length;
  const readyCount = activeOrders.filter(
    (o) => o.derivedStatus === OrderItemStatus.Ready
  ).length;

  const runAction = async (order, status) => {
    setBusyId(order.id);
    try {
      await setAllItems(order, status);
      await reload();
    } catch (err) {
      alert(err?.message || 'Sipariş durumu güncellenemedi.');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-md">
        <div>
          <div className="flex items-center gap-3">
            <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
              Mutfak Aktif Siparişleri
            </h2>
            {live && (
              <span className="inline-flex items-center gap-1 text-label-sm text-primary-container">
                <span className="w-2 h-2 rounded-full bg-primary-container animate-pulse" />
                Canlı
              </span>
            )}
          </div>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Mutfağa düşen siparişleri takip edebilir, hazırlama durumunu
            güncelleyebilir ve servise hazır olarak işaretleyebilirsiniz.
          </p>
        </div>

        <div className="grid grid-cols-3 gap-sm w-full lg:w-auto">
          <Stat label="Aktif" value={activeOrders.length} />
          <Stat label="Yeni" value={newCount} />
          <Stat label="Hazır" value={readyCount} />
        </div>
      </section>

      <section className="relative w-full">
        <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant">
          search
        </span>
        <input
          className="w-full bg-surface-container-lowest border border-outline-variant rounded-lg py-3 pl-10 pr-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all shadow-sm"
          placeholder="Masa adına göre ara..."
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </section>

      {loading && (
        <div className="flex items-center justify-center gap-3 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined animate-spin">progress_activity</span>
          Siparişler yükleniyor...
        </div>
      )}

      {!loading && error && (
        <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
          <span className="material-symbols-outlined text-[20px]">error</span>
          {error}
        </div>
      )}

      {!loading && !error && (
        <section className="flex flex-col gap-md">
          {activeOrders.length > 0 ? (
            activeOrders.map((order) => (
              <KitchenOrderCard
                key={order.id}
                order={order}
                busy={busyId === order.id}
                onAction={runAction}
              />
            ))
          ) : (
            <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-lg ambient-shadow text-center">
              <span className="material-symbols-outlined text-[48px] text-on-surface-variant opacity-50">
                room_service
              </span>
              <p className="font-headline-sm text-headline-sm text-on-background mt-2">
                Aktif sipariş bulunmuyor
              </p>
              <p className="text-body-sm text-on-surface-variant">
                Yeni siparişler mutfağa düştüğünde burada listelenecek.
              </p>
            </div>
          )}
        </section>
      )}
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

function KitchenOrderCard({ order, busy, onAction }) {
  const status = order.derivedStatus;
  const isReady = status === OrderItemStatus.Ready;
  const statusLabel = isReady
    ? 'Servise Hazır'
    : status === OrderItemStatus.Preparing
    ? 'Hazırlanıyor'
    : 'Mutfakta';

  return (
    <div
      className={`bg-surface-container-lowest border rounded-xl p-md ambient-shadow flex flex-col gap-md ${
        isReady ? 'border-primary-container' : 'border-outline-variant'
      }`}
    >
      <div className="flex flex-col md:flex-row md:justify-between md:items-start gap-md">
        <div>
          <h3 className="font-headline-md text-headline-md text-on-background">
            {order.tableName}
          </h3>
          <p className="text-body-sm text-on-surface-variant mt-1">
            Mutfak sipariş detayı
          </p>
        </div>

        <span
          className={`inline-flex items-center px-3 py-1 rounded-full text-label-sm font-bold ${
            isReady
              ? 'bg-primary-container text-on-primary-container'
              : 'bg-surface-container-high text-on-surface-variant'
          }`}
        >
          {statusLabel}
        </span>
      </div>

      <div className="flex flex-col gap-2">
        <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-wider">
          Hazırlanacak Ürünler
        </p>
        <ul className="font-body-md text-on-background flex flex-col gap-1">
          {order.grouped.map((item) => (
            <li
              key={`${order.id}-${item.name}`}
              className="flex items-center justify-between gap-md"
            >
              <span>{item.name}</span>
              <span className="font-bold text-primary-container">x{item.quantity}</span>
            </li>
          ))}
        </ul>
      </div>

      <div className="flex flex-col md:flex-row md:justify-between md:items-center gap-md pt-2 border-t border-outline-variant">
        <p className="font-headline-sm text-headline-sm text-on-background">
          Toplam Tutar :{' '}
          <span className="text-primary-container">{formatPrice(order.total)}</span>
        </p>

        <div className="flex flex-wrap gap-sm">
          {status <= OrderItemStatus.Kitchen && (
            <button
              type="button"
              disabled={busy}
              onClick={() => onAction(order, OrderItemStatus.Preparing)}
              className="px-5 py-2 border border-outline-variant rounded-lg font-label-md text-label-md hover:bg-surface-container-low transition-colors disabled:opacity-50"
            >
              Hazırlamaya Başla
            </button>
          )}

          {status < OrderItemStatus.Ready && (
            <button
              type="button"
              disabled={busy}
              onClick={() => onAction(order, OrderItemStatus.Ready)}
              className="bg-primary-container text-on-primary-container px-5 py-2 rounded-lg font-label-md text-label-md hover:opacity-90 transition-opacity disabled:opacity-50"
            >
              Servise Hazır
            </button>
          )}

          {status === OrderItemStatus.Ready && (
            <button
              type="button"
              disabled={busy}
              onClick={() => onAction(order, OrderItemStatus.Delivered)}
              className="bg-primary-container text-on-primary-container px-5 py-2 rounded-lg font-label-md text-label-md hover:opacity-90 transition-opacity disabled:opacity-50"
            >
              Teslim Edildi
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
