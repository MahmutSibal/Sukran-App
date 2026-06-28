// İşlem geçmişi / denetim kayıtları (/api/auditlogs).
import { api } from './http';

export const getAuditLogs = (limit = 200) =>
  api.get(`/api/auditlogs?limit=${limit}`);
