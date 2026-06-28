// JWT'li fetch sarmalayıcısı: erişim token'ını ekler, 401'de bir kez yenilemeyi dener.
import { API_BASE_URL } from './config';
import { tokenStore } from './tokenStore';

export class ApiError extends Error {
  constructor(message, status, body) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.body = body;
  }
}

async function parseBody(res) {
  const text = await res.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function rawRequest(path, { method = 'GET', body, token, signal } = {}) {
  const headers = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers['Authorization'] = `Bearer ${token}`;

  return fetch(`${API_BASE_URL}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
    credentials: 'include', // HttpOnly refresh çerezi için
    signal,
  });
}

let refreshPromise = null;

function doRefresh() {
  const refreshToken = tokenStore.getRefresh();
  return rawRequest('/api/auth/refresh', {
    method: 'POST',
    body: { refreshToken: refreshToken || '' },
  })
    .then(async (res) => {
      if (!res.ok) return false;
      const data = await parseBody(res);
      if (data?.accessToken) {
        tokenStore.setTokens(data);
        return true;
      }
      return false;
    })
    .catch(() => false);
}

function tryRefresh() {
  if (!refreshPromise) {
    refreshPromise = doRefresh().finally(() => {
      refreshPromise = null;
    });
  }
  return refreshPromise;
}

function notifyUnauthorized() {
  tokenStore.clear();
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent('sukran:unauthorized'));
  }
}

export async function apiFetch(path, options = {}) {
  const { auth = true, method, body, signal } = options;
  let token = auth ? tokenStore.getAccess() : undefined;

  let res = await rawRequest(path, { method, body, token, signal });

  if (res.status === 401 && auth) {
    const refreshed = await tryRefresh();
    if (refreshed) {
      token = tokenStore.getAccess();
      res = await rawRequest(path, { method, body, token, signal });
    } else {
      notifyUnauthorized();
    }
  }

  if (!res.ok) {
    const errBody = await parseBody(res);
    const message =
      (errBody && (errBody.message || errBody.title || errBody.error)) ||
      (typeof errBody === 'string' && errBody) ||
      `İstek başarısız (HTTP ${res.status})`;
    throw new ApiError(message, res.status, errBody);
  }

  return parseBody(res);
}

export const api = {
  get: (path, opts) => apiFetch(path, { method: 'GET', ...opts }),
  post: (path, body, opts) => apiFetch(path, { method: 'POST', body, ...opts }),
  put: (path, body, opts) => apiFetch(path, { method: 'PUT', body, ...opts }),
  del: (path, opts) => apiFetch(path, { method: 'DELETE', ...opts }),
};
