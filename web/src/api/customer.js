// Müşteri (QR ile masa) akışı için hafif API katmanı.
// ÖNEMLİ: Panel oturumuyla çakışmaması için paylaşılan tokenStore/http katmanını
// KULLANMAZ; müşteri token'ı çağrıya açıkça verilir. Aynı tarayıcıda hem panel
// hem müşteri açılırsa biri diğerinin oturumunu ezmez.
import { API_BASE_URL } from './config';

async function request(path, { method = 'GET', body, token } = {}) {
  const headers = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  const data = text
    ? (() => {
        try {
          return JSON.parse(text);
        } catch {
          return text;
        }
      })()
    : null;

  if (!res.ok) {
    const message =
      (data && (data.message || data.title || data.error)) ||
      (typeof data === 'string' && data) ||
      `İstek başarısız (HTTP ${res.status})`;
    const err = new Error(message);
    err.status = res.status;
    throw err;
  }
  return data;
}

// QR taranınca masa oturumunu başlatır → müşteri erişim token'ı döner.
export const startQrSession = ({ restaurantId, tableNo, qrToken }) =>
  request('/api/auth/qr-session', {
    method: 'POST',
    body: { restaurantId, tableNo: Number(tableNo), qrToken },
  });

// Restoran bilgisi (ad vb.) — anonim erişilebilir.
export const getRestaurantPublic = (restaurantId) =>
  request(`/api/restaurants/${restaurantId}`);

// Menü — anonim erişilebilir.
export const getMenu = (restaurantId) =>
  request(`/api/menuitems/restaurant/${restaurantId}`);

// Sipariş oluştur — müşteri token'ı gerekir.
export const placeOrder = (payload, token) =>
  request('/api/orders', { method: 'POST', body: payload, token });
