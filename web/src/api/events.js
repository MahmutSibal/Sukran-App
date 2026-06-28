// Etkinlik uç noktaları (/api/events).
import { api } from './http';

export const getEvents = () => api.get('/api/events');

// payload: { title, description, imageUrl, date, time, location, price, isFree, tags[] }
export const createEvent = (payload) => api.post('/api/events', payload);

// payload: create + { isPublished }
export const updateEvent = (eventId, payload) =>
  api.put(`/api/events/${eventId}`, payload);

export const deleteEvent = (eventId) => api.del(`/api/events/${eventId}`);
