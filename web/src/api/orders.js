// Sipariş uç noktaları (/api/orders).
import { api } from './http';

export const getOrdersByRestaurant = (restaurantId) =>
  api.get(`/api/orders/restaurant/${restaurantId}`);

export const getOrder = (orderId) => api.get(`/api/orders/${orderId}`);

export const createOrder = (payload) => api.post('/api/orders', payload);

// sessionStatus: OrderSessionStatus (int)
export const updateOrderStatus = (orderId, sessionStatus) =>
  api.put(`/api/orders/${orderId}/status`, { sessionStatus });

// status: OrderItemStatus (int)
export const updateOrderItemStatus = (orderId, orderItemId, status) =>
  api.put(`/api/orders/${orderId}/items/${orderItemId}/status`, { status });

export const deleteOrder = (orderId) => api.del(`/api/orders/${orderId}`);
