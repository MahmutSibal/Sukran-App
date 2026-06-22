"use client";

import { UserRole } from "@/lib/enums";
import type { AppUser } from "@/lib/types";
import { userService } from "@/services/userService";
import { useAsyncData } from "@/hooks/useAsyncData";
import { PageContainer } from "@/components/layout/PageContainer";
import { RestaurantForm } from "@/components/superadmin/RestaurantForm";
import { UserManagement } from "@/components/superadmin/UserManagement";

export default function ManagementPage() {
  // Tek kaynak: kullanıcı listesi hem formda (sahip seçimi) hem tabloda kullanılır.
  const { data: users, loading, error, reload } = useAsyncData<AppUser[]>(() => userService.list(), []);

  return (
    <PageContainer
      title="Restoran &amp; Kullanıcı Yönetimi"
      subtitle="Önce kullanıcı oluşturun, sonra restoran sahibi olarak atayın"
      allow={[UserRole.SuperAdmin]}
    >
      <div className="grid gap-6 xl:grid-cols-5">
        <div className="xl:col-span-2">
          <RestaurantForm users={users} onChanged={reload} />
        </div>
        <div className="xl:col-span-3">
          <UserManagement users={users} loading={loading} error={error} reload={reload} />
        </div>
      </div>
    </PageContainer>
  );
}
