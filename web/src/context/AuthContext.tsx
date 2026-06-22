"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { UserRole } from "@/lib/enums";
import type { AuthIdentity } from "@/lib/types";
import { setAuthRefreshHandler, setAuthTokenProvider } from "@/services/apiClient";
import { authService, identityFromToken } from "@/services/authService";

// Yalnızca refresh token kalıcıdır; access token bellekte (state) tutulur — böylece
// her istekte gönderilen kısa ömürlü token localStorage'da (XSS yüzeyi) durmaz.
const REFRESH_KEY = "appsukran_admin_refresh";

interface AuthContextValue {
  identity: AuthIdentity | null;
  isReady: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<AuthIdentity>;
  logout: () => Promise<void>;
  /** Geliştirme/QA için: ham JWT ile oturum aç. */
  setToken: (token: string) => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function readRefresh(): string | null {
  return typeof window !== "undefined" ? window.localStorage.getItem(REFRESH_KEY) : null;
}

function writeRefresh(token: string | null): void {
  if (typeof window === "undefined") return;
  if (token) window.localStorage.setItem(REFRESH_KEY, token);
  else window.localStorage.removeItem(REFRESH_KEY);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [identity, setIdentity] = useState<AuthIdentity | null>(null);
  const [isReady, setIsReady] = useState(false);
  // Eşzamanlı 401'lerin tek bir refresh çağrısını paylaşması için (single-flight).
  const refreshInFlight = useRef<Promise<string | null> | null>(null);

  // apiClient'ın her istekte güncel token'ı okumasını sağla.
  useEffect(() => {
    setAuthTokenProvider(() => identity?.accessToken ?? null);
  }, [identity]);

  // 401 alındığında çağrılan tek-uçuşlu yenileme. Başarılıysa yeni access token döner.
  const refresh = useCallback(async (): Promise<string | null> => {
    if (!refreshInFlight.current) {
      refreshInFlight.current = (async () => {
        const stored = readRefresh();
        if (!stored) return null;
        try {
          const session = await authService.refresh(stored);
          setIdentity(session.identity);
          writeRefresh(session.refreshToken);
          return session.identity.accessToken;
        } catch {
          setIdentity(null);
          writeRefresh(null);
          return null;
        } finally {
          refreshInFlight.current = null;
        }
      })();
    }
    return refreshInFlight.current;
  }, []);

  useEffect(() => {
    setAuthRefreshHandler(refresh);
    return () => setAuthRefreshHandler(null);
  }, [refresh]);

  // İlk yüklemede: kalıcı refresh token varsa taze bir access token al.
  useEffect(() => {
    if (readRefresh()) {
      refresh().finally(() => setIsReady(true));
    } else {
      setIsReady(true);
    }
  }, [refresh]);

  const login = useCallback(
    async (email: string, password: string) => {
      const session = await authService.login(email, password);
      setIdentity(session.identity);
      writeRefresh(session.refreshToken);
      return session.identity;
    },
    [],
  );

  const setToken = useCallback((token: string) => {
    setIdentity(identityFromToken(token));
  }, []);

  const logout = useCallback(async () => {
    await authService.logout(readRefresh());
    setIdentity(null);
    writeRefresh(null);
    router.replace("/login");
  }, [router]);

  const value = useMemo<AuthContextValue>(
    () => ({
      identity,
      isReady,
      isAuthenticated: !!identity,
      login,
      logout,
      setToken,
    }),
    [identity, isReady, login, logout, setToken],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within <AuthProvider>");
  return ctx;
}

export function roleHome(role: UserRole): string {
  return role === UserRole.SuperAdmin ? "/superadmin" : "/owner/kitchen";
}
