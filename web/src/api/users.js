// Kullanıcı yönetimi uç noktaları (/api/users) — yalnızca SuperAdmin.
import { api } from './http';

export const getUsers = () => api.get('/api/users');

// payload: { name, email, password, role, restaurantId? }
export const createUser = (payload) => api.post('/api/users', payload);

// payload: { role, restaurantId? }
export const updateUserRole = (userId, payload) =>
  api.put(`/api/users/${userId}/role`, payload);

export const resetUserPassword = (userId, newPassword) =>
  api.put(`/api/users/${userId}/reset-password`, { newPassword });

export const deleteUser = (userId) => api.del(`/api/users/${userId}`);
