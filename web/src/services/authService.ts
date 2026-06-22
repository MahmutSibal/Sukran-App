import { UserRole } from "@/lib/enums";
import type { AuthIdentity, TokenResponse } from "@/lib/types";
import { api } from "./apiClient";

/** base64url JWT payload çözücü (yalnızca rol/kimlik okumak için). */
function decodeJwt(token: string): Record<string, unknown> | null {
  try {
    const payload = token.split(".")[1];
    if (!payload) return null;
    const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(normalized.length + ((4 - (normalized.length % 4)) % 4), "=");
    const json = decodeURIComponent(
      atob(padded)
        .split("")
        .map((c) => "%" + c.charCodeAt(0).toString(16).padStart(2, "0"))
        .join(""),
    );
    return JSON.parse(json);
  } catch {
    return null;
  }
}

const ROLE_CLAIM_KEYS = [
  "role",
  "roles",
  "http://schemas.microsoft.com/ws/2008/06/identity/claims/role",
];
const ID_CLAIM_KEYS = ["sub", "nameid", "userId", "uid", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"];
const NAME_CLAIM_KEYS = ["name", "unique_name", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"];
const EMAIL_CLAIM_KEYS = ["email", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"];
const RESTAURANT_CLAIM_KEYS = ["restaurantId", "restaurant_id", "tenantId"];

function pick(claims: Record<string, unknown>, keys: string[]): string | null {
  for (const key of keys) {
    const value = claims[key];
    if (value !== undefined && value !== null && value !== "") {
      return Array.isArray(value) ? String(value[0]) : String(value);
    }
  }
  return null;
}

function normaliseRole(raw: string | null): UserRole {
  if (!raw) return UserRole.RestaurantOwner;
  const numeric = Number(raw);
  if (!Number.isNaN(numeric) && UserRole[numeric] !== undefined) return numeric as UserRole;
  switch (raw.toLowerCase()) {
    case "superadmin":
      return UserRole.SuperAdmin;
    case "restaurantowner":
      return UserRole.RestaurantOwner;
    case "waitercashier":
    case "waiter":
    case "cashier":
      return UserRole.WaiterCashier;
    default:
      return UserRole.Customer;
  }
}

export function identityFromToken(accessToken: string): AuthIdentity {
  const claims = decodeJwt(accessToken) ?? {};
  return {
    userId: pick(claims, ID_CLAIM_KEYS) ?? "",
    name: pick(claims, NAME_CLAIM_KEYS) ?? "Yönetici",
    email: pick(claims, EMAIL_CLAIM_KEYS) ?? "",
    role: normaliseRole(pick(claims, ROLE_CLAIM_KEYS)),
    restaurantId: pick(claims, RESTAURANT_CLAIM_KEYS),
    accessToken,
  };
}

export interface Session {
  identity: AuthIdentity;
  refreshToken: string;
}

export const authService = {
  async login(email: string, password: string): Promise<Session> {
    const res = await api.post<TokenResponse>("/api/auth/login", { email, password }, { token: null });
    return { identity: identityFromToken(res.accessToken), refreshToken: res.refreshToken };
  },

  /** Refresh token ile yeni access token alır (cookie cross-site gitmediği için gövdede gönderilir). */
  async refresh(refreshToken: string): Promise<Session> {
    const res = await api.post<TokenResponse>("/api/auth/refresh", { refreshToken }, { token: null });
    return { identity: identityFromToken(res.accessToken), refreshToken: res.refreshToken };
  },

  async logout(refreshToken: string | null): Promise<void> {
    try {
      await api.post("/api/auth/logout", { refreshToken: refreshToken ?? "" }, { token: null });
    } catch {
      // Sunucu reddetse bile yerel oturum temizlenir.
    }
  },
};
