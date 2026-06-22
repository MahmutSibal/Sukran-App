"use client";

import { useEffect, useState } from "react";
import { UserRole } from "@/lib/enums";
import type { RestaurantDetail } from "@/lib/types";
import { useAuth } from "@/context/AuthContext";
import { restaurantService } from "@/services/restaurantService";
import { useAsyncData } from "@/hooks/useAsyncData";
import { Card, PanelHeader } from "@/components/ui/Card";
import { Field, Select } from "@/components/ui/Form";
import { LoadingState } from "@/components/ui/Spinner";
import { Badge } from "@/components/ui/Badge";
import { Icon } from "@/components/icons";

const STORAGE_KEY = "appsukran_active_restaurant";

/**
 * Aktif restoranı çözer. RestaurantOwner kendi restoranına bağlıdır;
 * SuperAdmin için bir seçici gösterir. Çocuklara çözülmüş id'yi verir.
 */
export function RestaurantGate({ children }: { children: (restaurantId: string) => React.ReactNode }) {
  const { identity } = useAuth();
  const [picked, setPicked] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined") setPicked(window.localStorage.getItem(STORAGE_KEY));
  }, []);

  const bound = identity?.restaurantId ?? null;
  const isSuperAdmin = identity?.role === UserRole.SuperAdmin;

  const { data: restaurants, loading } = useAsyncData<RestaurantDetail[]>(
    () => restaurantService.all(),
    [],
    { enabled: isSuperAdmin && !bound },
  );

  const activeId = bound ?? picked ?? null;

  if (activeId) {
    return (
      <>
        {isSuperAdmin && !bound && (
          <RestaurantSwitcher
            restaurants={restaurants ?? []}
            value={activeId}
            onChange={(id) => {
              window.localStorage.setItem(STORAGE_KEY, id);
              setPicked(id);
            }}
          />
        )}
        {children(activeId)}
      </>
    );
  }

  if (loading) return <LoadingState label="Restoranlar yükleniyor…" />;

  // SuperAdmin: henüz seçim yok → seçim kartı.
  return (
    <Card className="mx-auto max-w-lg">
      <PanelHeader title="Restoran seçin" subtitle="Yönetmek istediğiniz mekanı belirleyin" icon={<Icon.Store size={18} />} />
      <Field label="Restoran">
        <Select
          defaultValue=""
          onChange={(e) => {
            if (!e.target.value) return;
            window.localStorage.setItem(STORAGE_KEY, e.target.value);
            setPicked(e.target.value);
          }}
        >
          <option value="" disabled>
            Seçiniz…
          </option>
          {(restaurants ?? []).map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </Select>
      </Field>
    </Card>
  );
}

function RestaurantSwitcher({
  restaurants,
  value,
  onChange,
}: {
  restaurants: RestaurantDetail[];
  value: string;
  onChange: (id: string) => void;
}) {
  const active = restaurants.find((r) => r.id === value);
  return (
    <div className="mb-5 flex items-center justify-between gap-4 rounded-card border border-line bg-ink-900/50 px-4 py-3">
      <div className="flex items-center gap-2 text-sm text-content-muted">
        <Badge tone="gold" dot>
          SuperAdmin
        </Badge>
        <span>{active ? active.name : "Restoran seçili"}</span>
      </div>
      <Select value={value} onChange={(e) => onChange(e.target.value)} className="w-56">
        {restaurants.map((r) => (
          <option key={r.id} value={r.id}>
            {r.name}
          </option>
        ))}
      </Select>
    </div>
  );
}
