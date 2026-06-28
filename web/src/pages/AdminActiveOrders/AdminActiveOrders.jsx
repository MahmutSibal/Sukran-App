import { useMemo, useState } from 'react';
import './AdminActiveOrders.css';
import { useAuth } from '../../auth/AuthContext.jsx';
import { useRestaurantOrders } from '../../hooks/useRestaurantOrders.js';
import { updateOrderStatus } from '../../api/orders.js';
import { isActiveOrder } from '../../api/orderHelpers.js';
import {
  formatPrice,
  OrderItemStatus,
  OrderSessionStatus,
  ORDER_ITEM_STATUS_LABELS,
} from '../../api/config.js';

export default function AdminActiveOrders() {
  const { restaurantId } = useAuth();
  const { orders, loading, error, live, reload } = useRestaurantOrders(restaurantId);
  const [searchTerm, setSearchTerm] = useState('');

  const activeOrders = useMemo(
    () =>
      orders
        .filter(isActiveOrder)
        .filter((o) =>
          o.tableName.toLowerCase().includes(searchTerm.toLowerCase())
        ),
    [orders, searchTerm]
  );

  const handleDelivered = async (orderId) => {
    try {
      await updateOrderStatus(orderId, OrderSessionStatus.Closed);
      reload();
    } catch (err) {
      alert(err?.message || 'Sipariş güncellenemedi.');
    }
  };

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col gap-md">
        <div className="flex items-center gap-3">
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Aktif Siparişler
          </h2>
          {live && (
            <span className="inline-flex items-center gap-1 text-label-sm text-primary-container">
              <span className="w-2 h-2 rounded-full bg-primary-container animate-pulse" />
              Canlı
            </span>
          )}
        </div>
        <p className="font-body-lg text-body-lg text-on-surface-variant">
          Hazırlanmayı bekleyen siparişleri buradan takip edebilir ve teslim
          edildi olarak işaretleyebilirsiniz.
        </p>

        <div className="relative w-full">
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
        </div>
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

      {!loading && !error && activeOrders.length === 0 && (
        <div className="flex flex-col items-center justify-center gap-2 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined text-[40px]">receipt_long</span>
          <p className="font-body-lg text-body-lg">Aktif sipariş bulunmuyor.</p>
        </div>
      )}

      {!loading && !error && activeOrders.length > 0 && (
        <section className="flex flex-col gap-md">
          {activeOrders.map((order) => (
            <OrderCard key={order.id} order={order} onDelivered={handleDelivered} />
          ))}
        </section>
      )}
    </div>
  );
}

function OrderCard({ order, onDelivered }) {
  const statusLabel =
    ORDER_ITEM_STATUS_LABELS[order.derivedStatus] || 'Hazırlanıyor';
  const allDelivered = order.derivedStatus === OrderItemStatus.Delivered;

  return (
    <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col gap-md">
      <div className="flex justify-between items-center">
        <h3 className="font-headline-md text-headline-md text-on-background">
          {order.tableName}
        </h3>

        <span className="inline-flex items-center px-3 py-1 rounded-full bg-primary-container text-on-primary-container text-label-sm font-bold">
          {statusLabel}
        </span>
      </div>

      <div className="flex flex-col gap-2">
        <p className="font-label-md text-label-md text-on-surface-variant uppercase tracking-wider">
          Siparişler
        </p>

        <ul className="font-body-md text-on-background flex flex-col gap-1">
          {order.grouped.map((item) => (
            <li key={`${order.id}-${item.name}`} className="flex justify-between">
              <span>
                {item.name} x{item.quantity}
              </span>
              <span>{formatPrice(item.total)}</span>
            </li>
          ))}
        </ul>
      </div>

      <div className="flex justify-between items-center pt-2 border-t border-outline-variant">
        <p className="font-headline-sm text-headline-sm text-on-background">
          Toplam Tutar :{' '}
          <span className="text-primary-container">{formatPrice(order.total)}</span>
        </p>

        <button
          type="button"
          onClick={() => onDelivered(order.id)}
          disabled={allDelivered}
          className="bg-primary-container text-on-primary-container px-6 py-2 rounded-lg font-label-md hover:opacity-90 transition-opacity disabled:opacity-50"
        >
          Teslim Edildi
        </button>
      </div>
    </div>
  );
}
