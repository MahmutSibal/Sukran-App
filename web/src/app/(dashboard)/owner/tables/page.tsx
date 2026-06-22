"use client";

import { UserRole } from "@/lib/enums";
import { PageContainer } from "@/components/layout/PageContainer";
import { RestaurantGate } from "@/components/owner/RestaurantGate";
import { TablesView } from "@/components/tables/TablesView";

export default function TablesPage() {
  return (
    <PageContainer
      title="Masa Oturumları &amp; Hesaplar"
      subtitle="Canlı oturum durumu, bakiye ve adisyon takibi"
      allow={[UserRole.SuperAdmin, UserRole.RestaurantOwner, UserRole.WaiterCashier]}
    >
      <RestaurantGate>{(restaurantId) => <TablesView restaurantId={restaurantId} />}</RestaurantGate>
    </PageContainer>
  );
}
