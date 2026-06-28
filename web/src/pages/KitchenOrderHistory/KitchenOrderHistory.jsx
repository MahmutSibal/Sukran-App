import './KitchenOrderHistory.css';
import { useMemo, useState } from 'react';
import { useAuth } from '../../auth/AuthContext.jsx';
import { useRestaurantOrders } from '../../hooks/useRestaurantOrders.js';
import { formatPrice, OrderSessionStatus } from '../../api/config.js';

export default function KitchenOrderHistory() {
  const { restaurantId } = useAuth();
  const { orders, loading, error } = useRestaurantOrders(restaurantId);
  const [searchTerm, setSearchTerm] = useState('');

  const closedOrders = useMemo(
    () =>
      orders
        .filter((o) => o.sessionStatus === OrderSessionStatus.Closed)
        .filter((o) =>
          o.tableName.toLowerCase().includes(searchTerm.toLowerCase())
        ),
    [orders, searchTerm]
  );

  return (
    <div className="max-w-[1400px] mx-auto flex flex-col gap-lg">
      <section className="flex flex-col gap-md">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-background mb-2">
            Mutfak Sipariş Geçmişi
          </h2>
          <p className="font-body-lg text-body-lg text-on-surface-variant">
            Tamamlanan siparişleri buradan inceleyebilirsiniz.
          </p>
        </div>

        <div className="relative flex-1 w-full">
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
          Yükleniyor...
        </div>
      )}

      {!loading && error && (
        <div className="flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
          <span className="material-symbols-outlined text-[20px]">error</span>
          {error}
        </div>
      )}

      {!loading && !error && closedOrders.length === 0 && (
        <div className="flex flex-col items-center justify-center gap-2 py-16 text-on-surface-variant">
          <span className="material-symbols-outlined text-[40px]">history</span>
          <p className="font-body-lg text-body-lg">Geçmiş sipariş bulunmuyor.</p>
        </div>
      )}

      <section className="flex flex-col gap-md">
        {closedOrders.map((order) => (
          <div
            key={order.id}
            className="bg-surface-container-lowest border border-outline-variant rounded-xl p-md ambient-shadow flex flex-col gap-md"
          >
            <div className="flex justify-between items-center gap-md">
              <h3 className="font-headline-md text-headline-md text-on-background">
                {order.tableName}
              </h3>
              <span className="inline-flex items-center px-3 py-1 rounded-full text-label-sm font-bold bg-primary-container text-on-primary-container">
                Teslim Edildi
              </span>
            </div>

            <ul className="font-body-md text-on-background flex flex-col gap-1">
              {order.grouped.map((item) => (
                <li key={item.name} className="flex justify-between">
                  <span>
                    {item.name} x{item.quantity}
                  </span>
                  <span>{formatPrice(item.total)}</span>
                </li>
              ))}
            </ul>

            <div className="flex justify-between items-center pt-2 border-t border-outline-variant">
              <p className="font-headline-sm text-headline-sm text-on-background">
                Toplam Tutar :{' '}
                <span className="text-primary-container">
                  {formatPrice(order.total)}
                </span>
              </p>
            </div>
          </div>
        ))}
      </section>
    </div>
  );
}
