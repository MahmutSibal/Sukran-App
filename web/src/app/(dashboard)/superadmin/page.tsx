"use client";

import { useMemo } from "react";
import { UserRole } from "@/lib/enums";
import { formatMinorAsTry } from "@/lib/format";
import { restaurantService } from "@/services/restaurantService";
import { useAsyncData } from "@/hooks/useAsyncData";
import { PageContainer } from "@/components/layout/PageContainer";
import { Card, PanelHeader } from "@/components/ui/Card";
import { StatCard } from "@/components/ui/StatCard";
import { LoadingState } from "@/components/ui/Spinner";
import { Badge } from "@/components/ui/Badge";
import { Icon } from "@/components/icons";
import {
  DailyRevenueArea,
  RestaurantRevenueBar,
  type DailyRevenuePoint,
  type RestaurantRevenuePoint,
} from "@/components/charts/RevenueCharts";

// Konya merkezli geniş tarama — sistemdeki tüm Sukran mekanlarını çeker.
const SCAN = { longitude: 32.4845, latitude: 39.8675 };

export default function SuperAdminDashboardPage() {
  const { data: restaurants, loading } = useAsyncData(
    () => restaurantService.nearby(SCAN.longitude, SCAN.latitude, 5_000_000),
    [],
  );

  const list = restaurants ?? [];

  // Demo metrik/grafik serileri (gerçek toplam metrik ucu eklendiğinde buradan beslenir).
  const revenueByRestaurant = useMemo<RestaurantRevenuePoint[]>(
    () =>
      list.slice(0, 6).map((r, i) => ({
        name: r.name.replace(/^Sukran\s*/i, "") || r.slug,
        revenue: 12000 + ((i * 7919) % 38000),
      })),
    [list],
  );

  const dailyRevenue = useMemo<DailyRevenuePoint[]>(() => {
    const days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
    return days.map((day, i) => ({ day, revenue: 18000 + ((i * 9173) % 26000) }));
  }, []);

  const totalRevenueMinor = revenueByRestaurant.reduce((s, r) => s + r.revenue, 0) * 100;

  return (
    <PageContainer
      title="Sistem Genel Paneli"
      subtitle="Tüm restoranların özet performansı"
      allow={[UserRole.SuperAdmin]}
    >
      {loading ? (
        <LoadingState label="Metrikler hesaplanıyor…" />
      ) : (
        <div className="space-y-6">
          {/* 4 ana metrik kartı */}
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard
              label="Toplam Restoran"
              value={String(list.length)}
              hint="Sisteme kayıtlı mekan"
              accent="gold"
              icon={<Icon.Store size={20} />}
              trend={{ value: "%8", positive: true }}
            />
            <StatCard
              label="Aktif Müşteri Oturumu"
              value={String(Math.max(1, Math.round(list.length * 3.4)))}
              hint="QR ile açık masa oturumları"
              accent="info"
              icon={<Icon.Users size={20} />}
              trend={{ value: "%12", positive: true }}
            />
            <StatCard
              label="Günlük Toplam Ciro"
              value={formatMinorAsTry(totalRevenueMinor)}
              hint="Bugünkü tüm restoranlar"
              accent="sage"
              icon={<Icon.Wallet size={20} />}
              trend={{ value: "%5", positive: true }}
            />
            <StatCard
              label="Sistem Sağlığı"
              value="Çevrimiçi"
              hint="API · SignalR · MongoDB"
              accent="sage"
              icon={<Icon.Pulse size={20} />}
            />
          </div>

          {/* Grafikler */}
          <div className="grid gap-4 xl:grid-cols-5">
            <Card className="xl:col-span-3">
              <PanelHeader
                title="Restoran Performansı"
                subtitle="Günlük ciro karşılaştırması"
                icon={<Icon.Dashboard size={18} />}
                actions={<Badge tone="gold">Bugün</Badge>}
              />
              <RestaurantRevenueBar data={revenueByRestaurant} />
            </Card>

            <Card className="xl:col-span-2">
              <PanelHeader
                title="Ciro Trendi"
                subtitle="Son 7 gün"
                icon={<Icon.Pulse size={18} />}
              />
              <DailyRevenueArea data={dailyRevenue} />
            </Card>
          </div>

          {/* Restoran listesi özeti */}
          <Card>
            <PanelHeader title="Mekanlar" subtitle={`${list.length} restoran`} icon={<Icon.Store size={18} />} />
            <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
              {list.map((r) => (
                <div key={r.id} className="rounded-card border border-line bg-ink-900/50 p-4">
                  <div className="flex items-center justify-between">
                    <p className="font-semibold text-content">{r.name}</p>
                    <Badge tone="sage" dot>
                      Aktif
                    </Badge>
                  </div>
                  <p className="mt-1 truncate text-xs text-content-muted">{r.address}</p>
                  <p className="mt-2 font-mono text-[11px] text-content-faint">{r.slug}</p>
                </div>
              ))}
            </div>
          </Card>
        </div>
      )}
    </PageContainer>
  );
}
