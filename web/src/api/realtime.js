// SignalR gerçek zamanlı sipariş bağlantısı (/hubs/orders).
import {
  HubConnectionBuilder,
  HttpTransportType,
  LogLevel,
} from '@microsoft/signalr';
import { HUB_URL } from './config';
import { tokenStore } from './tokenStore';

// Belirli bir restoran için OrderHub bağlantısı kurar.
// handlers: { onOrderCreated?(order), onOrderUpdated?(order) }
// Geriye bağlantıyı kapatan bir fonksiyon döndürür.
export function connectOrderHub(restaurantId, handlers = {}) {
  const connection = new HubConnectionBuilder()
    .withUrl(HUB_URL, {
      accessTokenFactory: () => tokenStore.getAccess() || '',
      transport: HttpTransportType.WebSockets | HttpTransportType.LongPolling,
    })
    .withAutomaticReconnect()
    .configureLogging(LogLevel.Warning)
    .build();

  if (handlers.onOrderCreated) {
    connection.on('orderCreated', handlers.onOrderCreated);
  }
  if (handlers.onOrderUpdated) {
    connection.on('orderUpdated', handlers.onOrderUpdated);
  }

  let stopped = false;

  const joinGroup = async () => {
    try {
      await connection.invoke('JoinRestaurantGroup', restaurantId);
    } catch (err) {
      console.warn('OrderHub gruba katılma hatası:', err);
    }
  };

  const start = async () => {
    try {
      await connection.start();
      if (stopped) return;
      await joinGroup();
    } catch (err) {
      if (!stopped) {
        console.warn('OrderHub bağlantı hatası:', err);
      }
    }
  };

  // Yeniden bağlanınca gruba tekrar katıl
  connection.onreconnected(() => {
    if (!stopped) joinGroup();
  });

  start();

  return () => {
    stopped = true;
    connection.stop().catch(() => {});
  };
}
