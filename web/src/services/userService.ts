import type { UserRole } from "@/lib/enums";
import type { AppUser, CreateUserInput } from "@/lib/types";
import { api } from "./apiClient";

export const userService = {
  /** Tüm kullanıcıları getir (SuperAdminOnly). */
  list() {
    return api.get<AppUser[]>("/api/users");
  },

  /** Yeni kullanıcı oluştur — oluşan kullanıcının id'sini döndürür. */
  async create(input: CreateUserInput): Promise<string> {
    const res = await api.post<{ userId: string }>("/api/users", input);
    return res.userId;
  },

  /** Kullanıcı rolünü güncelle. */
  updateRole(userId: string, role: UserRole, restaurantId?: string | null) {
    return api.put<void>(`/api/users/${userId}/role`, {
      role,
      ...(restaurantId ? { restaurantId } : {}),
    });
  },

  /** Şifre değiştir / sıfırla. */
  resetPassword(userId: string, newPassword: string) {
    return api.put<void>(`/api/users/${userId}/reset-password`, { newPassword });
  },

  /** Kullanıcı sil. */
  remove(userId: string) {
    return api.delete<void>(`/api/users/${userId}`);
  },
};
