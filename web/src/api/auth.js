// Kimlik doğrulama uç noktaları.
import { api, apiFetch } from './http';
import { tokenStore } from './tokenStore';

// Giriş yapar, token'ları saklar ve profil bilgisini döndürür.
export async function login(email, password) {
  const tokens = await apiFetch('/api/auth/login', {
    method: 'POST',
    body: { email, password },
    auth: false,
  });
  tokenStore.setTokens(tokens);
  const profile = await getProfile();
  tokenStore.setUser(profile);
  return profile;
}

export function getProfile() {
  return api.get('/api/profile/me');
}

export function updateProfile(name) {
  return api.put('/api/profile/me', { name });
}

export async function logout() {
  const refreshToken = tokenStore.getRefresh();
  try {
    await apiFetch('/api/auth/logout', {
      method: 'POST',
      body: { refreshToken: refreshToken || '' },
      auth: false,
    });
  } catch {
    // sunucu hatası olsa bile yerelde temizliyoruz
  }
  tokenStore.clear();
}
