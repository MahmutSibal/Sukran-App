import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  useCallback,
} from 'react';
import * as authApi from '../api/auth';
import { tokenStore } from '../api/tokenStore';
import { UserRole } from '../api/config';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => tokenStore.getUser());
  const [loading, setLoading] = useState(Boolean(tokenStore.getAccess()));

  // Sayfa yenilemede token varsa profili tazele
  useEffect(() => {
    if (!tokenStore.getAccess()) {
      setLoading(false);
      return;
    }
    let active = true;
    authApi
      .getProfile()
      .then((profile) => {
        if (!active) return;
        tokenStore.setUser(profile);
        setUser(profile);
      })
      .catch(() => {
        if (!active) return;
        tokenStore.clear();
        setUser(null);
      })
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, []);

  // 401 sonrası http katmanından gelen oturum sonu sinyali
  useEffect(() => {
    const handler = () => setUser(null);
    window.addEventListener('sukran:unauthorized', handler);
    return () => window.removeEventListener('sukran:unauthorized', handler);
  }, []);

  const login = useCallback(async (email, password) => {
    const profile = await authApi.login(email, password);
    setUser(profile);
    return profile;
  }, []);

  const logout = useCallback(async () => {
    await authApi.logout();
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({
      user,
      loading,
      login,
      logout,
      isAuthenticated: Boolean(user),
      role: user?.role ?? null,
      restaurantId: user?.restaurantId ?? null,
    }),
    [user, loading, login, logout]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth, AuthProvider içinde kullanılmalı');
  return ctx;
}

// Role göre varsayılan açılış sayfası
export function defaultRouteForRole(role) {
  if (role === UserRole.SuperAdmin) return '/super-admin';
  if (role === UserRole.RestaurantOwner) return '/admin';
  return '/login';
}
