import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext.jsx';
import { getDashboardSummary } from '../api/reports.js';
import { getRestaurant } from '../api/restaurants.js';
import { formatPrice } from '../api/config.js';

// İşletme sahibi (Admin/Mutfak) panelleri için AI asistanına verilecek GERÇEK
// veri özetini üretir. Tek dashboard çağrısı ciro/sipariş/ürün/masa/personel
// sayılarını verir; böylece asistan uydurmak yerine doğru sayıları söyler.
export function useOwnerAssistantContext() {
  const { restaurantId } = useAuth();
  const [context, setContext] = useState('');

  useEffect(() => {
    if (!restaurantId) return;
    let active = true;
    Promise.all([
      getDashboardSummary().catch(() => null),
      getRestaurant(restaurantId).catch(() => null),
    ]).then(([summary, restaurant]) => {
      if (!active) return;
      const lines = [];
      if (restaurant?.name) lines.push(`Restoran: ${restaurant.name}`);
      if (summary) {
        lines.push(`Bugünkü ciro: ${formatPrice(summary.dailyRevenue)}`);
        lines.push(`Bugünkü sipariş sayısı: ${summary.dailyOrderCount}`);
        lines.push(`Aktif (açık) sipariş sayısı: ${summary.activeOrders}`);
        lines.push(`Ortalama sepet: ${formatPrice(summary.averageBasket)}`);
        lines.push(`Menüdeki ürün sayısı: ${summary.productCount}`);
        lines.push(`Masa sayısı: ${summary.tableCount}`);
        lines.push(`Personel sayısı: ${summary.staffCount}`);
      }
      setContext(lines.join('\n'));
    });
    return () => {
      active = false;
    };
  }, [restaurantId]);

  return context;
}
