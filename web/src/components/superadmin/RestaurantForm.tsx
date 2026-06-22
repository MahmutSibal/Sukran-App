"use client";

import { useState } from "react";
import { USER_ROLE_LABEL, UserRole } from "@/lib/enums";
import type { AppUser, CreateRestaurantInput } from "@/lib/types";
import { restaurantService } from "@/services/restaurantService";
import { userService } from "@/services/userService";
import { useToast } from "@/context/ToastContext";
import { Card, PanelHeader } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Field, Select, TextArea, TextInput } from "@/components/ui/Form";
import { Icon } from "@/components/icons";

const EMPTY: CreateRestaurantInput = {
  name: "",
  slug: "",
  ownerId: "",
  address: "",
  longitude: 0,
  latitude: 0,
};

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/ı/g, "i")
    .replace(/ş/g, "s")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function RestaurantForm({
  users,
  onChanged,
}: {
  users: AppUser[] | null;
  onChanged?: () => void;
}) {
  const toast = useToast();
  const [form, setForm] = useState<CreateRestaurantInput>(EMPTY);
  const [ownerId, setOwnerId] = useState("");
  const [slugTouched, setSlugTouched] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // SuperAdmin dışındaki kullanıcılar sahip olabilir.
  const ownerOptions = (users ?? []).filter((u) => u.role !== UserRole.SuperAdmin);

  function update<K extends keyof CreateRestaurantInput>(key: K, value: CreateRestaurantInput[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name) {
      toast.error("Restoran adı zorunlu.");
      return;
    }
    if (!ownerId) {
      toast.error("Sahip için bir kullanıcı seçin (önce kullanıcı oluşturun).");
      return;
    }
    setSubmitting(true);
    try {
      const slug = form.slug || slugify(form.name);
      // ownerId, oluşturulan kullanıcılardan seçilen kişidir.
      const res = await restaurantService.create({ ...form, slug, ownerId });

      // Seçilen kullanıcıyı bu restoranın sahibi (RestaurantOwner) olarak bağla.
      try {
        await userService.updateRole(ownerId, UserRole.RestaurantOwner, res.restaurantId);
      } catch {
        toast.error("Restoran oluştu ancak sahip rolü atanamadı, manuel atayın.");
      }

      toast.success(`Restoran oluşturuldu (${res.restaurantId}).`);
      onChanged?.();
      setForm(EMPTY);
      setOwnerId("");
      setSlugTouched(false);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Restoran oluşturulamadı.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Card>
      <PanelHeader title="Yeni Restoran" subtitle="POST /api/restaurants" icon={<Icon.Store size={18} />} />
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Restoran adı" required>
            <TextInput
              value={form.name}
              onChange={(e) => {
                update("name", e.target.value);
                if (!slugTouched) update("slug", slugify(e.target.value));
              }}
              placeholder="Sukran Kadıköy"
            />
          </Field>
          <Field label="URL slug" hint="Boş bırakılırsa addan üretilir">
            <TextInput
              value={form.slug}
              onChange={(e) => {
                setSlugTouched(true);
                update("slug", slugify(e.target.value));
              }}
              placeholder="sukran-kadikoy"
            />
          </Field>
        </div>

        {/* İşletme sahibi: oluşturulan kullanıcılardan seçilir, ID elle girilmez. */}
        <Field
          label="İşletme sahibi"
          required
          hint={ownerOptions.length === 0 ? "Önce bir kullanıcı oluşturun." : undefined}
        >
          {ownerOptions.length === 0 ? (
            <div className="flex items-center gap-2 rounded-xl border border-dashed border-line bg-ink-900/50 px-3.5 py-2.5 text-sm text-content-faint">
              <Icon.Users size={16} /> Atanabilecek kullanıcı yok
            </div>
          ) : (
            <Select value={ownerId} onChange={(e) => setOwnerId(e.target.value)}>
              <option value="" disabled>
                Sahip seçin…
              </option>
              {ownerOptions.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.name || u.email || u.id} — {USER_ROLE_LABEL[u.role]}
                </option>
              ))}
            </Select>
          )}
        </Field>

        <Field label="Adres" required>
          <TextArea
            value={form.address}
            onChange={(e) => update("address", e.target.value)}
            placeholder="Moda Caddesi No:18, Kadıköy / İstanbul"
          />
        </Field>

        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Enlem (Latitude)" required>
            <TextInput
              type="number"
              step="any"
              value={Number.isFinite(form.latitude) ? form.latitude : ""}
              onChange={(e) => update("latitude", Number(e.target.value))}
              placeholder="40.9867"
            />
          </Field>
          <Field label="Boylam (Longitude)" required>
            <TextInput
              type="number"
              step="any"
              value={Number.isFinite(form.longitude) ? form.longitude : ""}
              onChange={(e) => update("longitude", Number(e.target.value))}
              placeholder="29.0293"
            />
          </Field>
        </div>

        <div className="flex justify-end pt-1">
          <Button type="submit" loading={submitting} icon={<Icon.Plus size={18} />}>
            Restoran Oluştur
          </Button>
        </div>
      </form>
    </Card>
  );
}
