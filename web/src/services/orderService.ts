import {
  OrderItemStatus,
  OrderSessionStatus,
  toOrderItemStatus,
  toOrderSessionStatus,
  toPaymentStatus,
} from "@/lib/enums";
import type { Bill, Order, OrderItem } from "@/lib/types";
import { api } from "./apiClient";

/** Gelen sipariş/hesap enum'larını sayısala normalize eder (string gelse bile). */
function normalizeOrder<T extends Order | Bill>(entity: T): T {
  return {
    ...entity,
    sessionStatus: toOrderSessionStatus(entity.sessionStatus),
    items: (entity.items ?? []).map(
      (item: OrderItem): OrderItem => ({
        ...item,
        status: toOrderItemStatus(item.status),
        paymentStatus: toPaymentStatus(item.paymentStatus),
      }),
    ),
  };
}

export const orderService = {
  async byRestaurant(restaurantId: string) {
    const orders = await api.get<Order[]>(`/api/orders/restaurant/${restaurantId}`);
    return orders.map(normalizeOrder);
  },

  async getById(orderId: string) {
    return normalizeOrder(await api.get<Order>(`/api/orders/${orderId}`));
  },

  /** Kalem durumunu ilerlet — değişiklik SignalR ile herkese yansır. */
  updateItemStatus(orderId: string, orderItemId: string, status: OrderItemStatus) {
    return api.put<void>(`/api/orders/${orderId}/items/${orderItemId}/status`, { status });
  },

  updateSessionStatus(orderId: string, sessionStatus: OrderSessionStatus) {
    return api.put<void>(`/api/orders/${orderId}/status`, { sessionStatus });
  },
};

export const billService = {
  async byRestaurant(restaurantId: string) {
    const bills = await api.get<Bill[]>(`/api/bills/restaurant/${restaurantId}`);
    return bills.map(normalizeOrder);
  },

  async getById(billId: string) {
    return normalizeOrder(await api.get<Bill>(`/api/bills/${billId}`));
  },
};
