// Personel uç noktaları (/api/staff) — işletme sahibine bağlı çalışanlar.
import { api } from './http';

export const getStaff = () => api.get('/api/staff');

// payload: { name, email, password, role }  (role: UserRole int — Kitchen=8, Waiter=16)
export const createStaff = (payload) => api.post('/api/staff', payload);

export const setStaffActive = (userId, isActive) =>
  api.put(`/api/staff/${userId}/status`, { isActive });

export const deleteStaff = (userId) => api.del(`/api/staff/${userId}`);
