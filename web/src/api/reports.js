// Rapor/Dashboard uç noktaları (/api/reports).
import { api } from './http';

export const getDashboardSummary = () => api.get('/api/reports/dashboard');

// date: "yyyy-MM-dd" (opsiyonel)
export const getDailyReport = (date) =>
  api.get(`/api/reports/daily${date ? `?date=${encodeURIComponent(date)}` : ''}`);
