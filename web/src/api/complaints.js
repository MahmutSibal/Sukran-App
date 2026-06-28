// Şikayet uç noktaları (/api/complaints).
import { api } from './http';

export const getComplaints = () => api.get('/api/complaints');

// payload: { restaurantName, userName, content, restaurantId? }
export const createComplaint = (payload) => api.post('/api/complaints', payload);

// payload: { status (ComplaintStatus int), response }
export const updateComplaint = (id, payload) =>
  api.put(`/api/complaints/${id}`, payload);
