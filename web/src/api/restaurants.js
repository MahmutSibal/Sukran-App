// Restoran uç noktaları (/api/restaurants).
import { api } from './http';

export const getAllRestaurants = () => api.get('/api/restaurants');

export const getRestaurant = (restaurantId) =>
  api.get(`/api/restaurants/${restaurantId}`);

export const getRestaurantBySlug = (slug) =>
  api.get(`/api/restaurants/by-slug/${slug}`);

// payload: { name, slug, ownerId, longitude, latitude, address }
export const createRestaurant = (payload) =>
  api.post('/api/restaurants', payload);

// payload: { name, address, longitude, latitude }
export const updateRestaurant = (restaurantId, payload) =>
  api.put(`/api/restaurants/${restaurantId}`, payload);

// --- Masalar ---
export const getTables = (restaurantId) =>
  api.get(`/api/restaurants/${restaurantId}/tables`);

// tableNo verilmezse backend sıradaki numarayı atar
export const addTable = (restaurantId, tableNo = null) =>
  api.post(`/api/restaurants/${restaurantId}/tables`, { tableNo });

export const removeTable = (restaurantId, tableNo) =>
  api.del(`/api/restaurants/${restaurantId}/tables/${tableNo}`);

// --- Masa oturumları ---
export const openTableSession = (restaurantId, tableNo) =>
  api.post(`/api/restaurants/${restaurantId}/tables/${tableNo}/session/open`);

export const closeTableSession = (restaurantId, tableNo) =>
  api.post(`/api/restaurants/${restaurantId}/tables/${tableNo}/session/close`);
