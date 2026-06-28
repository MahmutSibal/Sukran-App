// Destek talepleri (/api/support-requests).
import { api } from './http';

export const getSupportRequests = () => api.get('/api/support-requests');

// payload: { businessName, content, phone, restaurantId? }
export const createSupportRequest = (payload) =>
  api.post('/api/support-requests', payload);

export const setSupportCalled = (id, isCalled) =>
  api.put(`/api/support-requests/${id}/called`, { isCalled });

export const deleteSupportRequest = (id) =>
  api.del(`/api/support-requests/${id}`);
