// Menü/ürün uç noktaları (/api/menuitems).
import { api } from './http';

export const getMenuItems = (restaurantId) =>
  api.get(`/api/menuitems/restaurant/${restaurantId}`);

export const getMenuItem = (menuItemId) =>
  api.get(`/api/menuitems/${menuItemId}`);

// payload: { restaurantId, category, name, imageUrl, ingredients[], recipe?, averagePreparationTime, price, isAvailable }
export const createMenuItem = (payload) => api.post('/api/menuitems', payload);

// payload: { category, name, imageUrl, ingredients[], recipe?, averagePreparationTime, price, isAvailable }
export const updateMenuItem = (menuItemId, payload) =>
  api.put(`/api/menuitems/${menuItemId}`, payload);

export const deleteMenuItem = (menuItemId) =>
  api.del(`/api/menuitems/${menuItemId}`);
