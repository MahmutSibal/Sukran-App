"use client";

import { UserRole } from "@/lib/enums";
import { PageContainer } from "@/components/layout/PageContainer";
import { RestaurantGate } from "@/components/owner/RestaurantGate";
import { MenuManager } from "@/components/menu/MenuManager";

export default function MenuPage() {
  return (
    <PageContainer
      title="Menü Yönetimi"
      subtitle="Ürün ekleyin, düzenleyin, satış durumunu yönetin"
      allow={[UserRole.SuperAdmin, UserRole.RestaurantOwner]}
    >
      <RestaurantGate>{(restaurantId) => <MenuManager restaurantId={restaurantId} />}</RestaurantGate>
    </PageContainer>
  );
}
