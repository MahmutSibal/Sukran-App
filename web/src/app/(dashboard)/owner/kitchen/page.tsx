"use client";

import { UserRole } from "@/lib/enums";
import { PageContainer } from "@/components/layout/PageContainer";
import { RestaurantGate } from "@/components/owner/RestaurantGate";
import { KitchenBoard } from "@/components/kitchen/KitchenBoard";

export default function KitchenPage() {
  return (
    <PageContainer
      title="Canlı Mutfak &amp; Sipariş Yönetimi"
      subtitle="SignalR ile anlık güncellenen sipariş akışı"
      allow={[UserRole.SuperAdmin, UserRole.RestaurantOwner, UserRole.WaiterCashier]}
    >
      <RestaurantGate>{(restaurantId) => <KitchenBoard restaurantId={restaurantId} />}</RestaurantGate>
    </PageContainer>
  );
}
