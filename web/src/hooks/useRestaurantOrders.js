// Restoran siparişlerini yükler ve SignalR ile gerçek zamanlı günceller.
import { useCallback, useEffect, useState } from 'react';
import { getOrdersByRestaurant } from '../api/orders';
import { connectOrderHub } from '../api/realtime';
import { mapOrder } from '../api/orderHelpers';

export function useRestaurantOrders(restaurantId) {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [live, setLive] = useState(false);

  const load = useCallback(async () => {
    if (!restaurantId) {
      setLoading(false);
      setError('Hesabınıza bağlı bir restoran bulunamadı.');
      return;
    }
    try {
      const data = await getOrdersByRestaurant(restaurantId);
      setOrders((data || []).map(mapOrder));
      setError('');
    } catch (e) {
      setError(e?.message || 'Siparişler yüklenemedi.');
    } finally {
      setLoading(false);
    }
  }, [restaurantId]);

  useEffect(() => {
    setLoading(true);
    load();
  }, [load]);

  useEffect(() => {
    if (!restaurantId) return undefined;
    const disconnect = connectOrderHub(restaurantId, {
      onOrderCreated: () => {
        setLive(true);
        load();
      },
      onOrderUpdated: () => {
        setLive(true);
        load();
      },
    });
    return disconnect;
  }, [restaurantId, load]);

  return { orders, loading, error, live, reload: load, setOrders };
}
