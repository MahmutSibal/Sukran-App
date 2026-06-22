"use client";

import { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import { formatMinorAsTry, minorToTryInput, parseTryToMinor } from "@/lib/format";
import type { MenuItem, MenuItemInput } from "@/lib/types";
import { menuService } from "@/services/menuService";
import { useAsyncData } from "@/hooks/useAsyncData";
import { useDisclosure } from "@/hooks/useDisclosure";
import { useToast } from "@/context/ToastContext";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { ChipsInput, Field, Switch, TextArea, TextInput } from "@/components/ui/Form";
import { EmptyState, ErrorState, LoadingState } from "@/components/ui/Spinner";
import { Icon } from "@/components/icons";
import { cn } from "@/lib/cn";

const EMPTY_INPUT: MenuItemInput = {
  name: "",
  category: "",
  imageUrl: "",
  ingredients: [],
  recipe: null,
  averagePreparationTime: 0,
  price: 0,
  isAvailable: true,
};

export function MenuManager({ restaurantId }: { restaurantId: string }) {
  const toast = useToast();
  const { data: items, loading, error, reload } = useAsyncData<MenuItem[]>(
    () => menuService.byRestaurant(restaurantId),
    [restaurantId],
  );

  const modal = useDisclosure();
  const [editing, setEditing] = useState<MenuItem | null>(null);
  const [filter, setFilter] = useState("Tümü");

  const categories = useMemo(() => {
    const set = new Set((items ?? []).map((i) => i.category).filter(Boolean));
    return ["Tümü", ...Array.from(set).sort()];
  }, [items]);

  const visible = (items ?? []).filter((i) => filter === "Tümü" || i.category === filter);

  function openCreate() {
    setEditing(null);
    modal.open();
  }
  function openEdit(item: MenuItem) {
    setEditing(item);
    modal.open();
  }

  async function remove(item: MenuItem) {
    if (!window.confirm(`"${item.name}" silinsin mi?`)) return;
    try {
      await menuService.remove(item.id);
      toast.success("Ürün silindi.");
      reload();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Silinemedi.");
    }
  }

  if (loading && !items) return <LoadingState label="Menü yükleniyor…" />;
  if (error && !items) return <ErrorState message={error} onRetry={reload} />;

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap gap-2">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setFilter(cat)}
              className={cn(
                "rounded-full border px-3.5 py-1.5 text-sm font-medium transition-colors",
                filter === cat
                  ? "border-transparent btn-gold"
                  : "border-line text-content-muted hover:bg-white/5 hover:text-content",
              )}
            >
              {cat}
            </button>
          ))}
        </div>
        <Button icon={<Icon.Plus size={18} />} onClick={openCreate}>
          Yeni Ürün
        </Button>
      </div>

      {visible.length === 0 ? (
        <EmptyState
          icon={<Icon.Menu size={28} />}
          title="Bu kategoride ürün yok"
          description="Sağ üstten yeni ürün ekleyebilirsiniz."
        />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {visible.map((item) => (
            <MenuCard key={item.id} item={item} onEdit={() => openEdit(item)} onDelete={() => remove(item)} />
          ))}
        </div>
      )}

      <MenuFormModal
        open={modal.isOpen}
        onClose={modal.close}
        restaurantId={restaurantId}
        editing={editing}
        onSaved={() => {
          modal.close();
          reload();
        }}
      />
    </div>
  );
}

function MenuCard({ item, onEdit, onDelete }: { item: MenuItem; onEdit: () => void; onDelete: () => void }) {
  return (
    <article className="surface-card group overflow-hidden p-0">
      <div className="relative aspect-[4/3] bg-ink-900">
        {item.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <Image
            src={item.imageUrl}
            alt={item.name}
            fill
            sizes="(max-width:768px) 100vw, 25vw"
            className="object-cover transition-transform duration-300 group-hover:scale-105"
            unoptimized
          />
        ) : (
          <div className="grid h-full place-items-center text-content-faint">
            <Icon.Menu size={28} />
          </div>
        )}
        <div className="absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-black/70 to-transparent" />
        <div className="absolute left-3 top-3">
          {item.isAvailable ? <Badge tone="sage" dot>Satışta</Badge> : <Badge tone="coral">Tükendi</Badge>}
        </div>
      </div>

      <div className="p-4">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <p className="truncate font-semibold text-content">{item.name}</p>
            <p className="text-xs text-content-faint">{item.category}</p>
          </div>
          <span className="shrink-0 font-bold text-gold">{formatMinorAsTry(item.price)}</span>
        </div>

        {item.ingredients.length > 0 && (
          <div className="mt-2.5 flex flex-wrap gap-1">
            {item.ingredients.slice(0, 3).map((ing) => (
              <span key={ing} className="rounded-md bg-white/5 px-1.5 py-0.5 text-[11px] text-content-muted">
                {ing}
              </span>
            ))}
            {item.ingredients.length > 3 && (
              <span className="text-[11px] text-content-faint">+{item.ingredients.length - 3}</span>
            )}
          </div>
        )}

        <div className="mt-3 flex items-center justify-between">
          <span className="inline-flex items-center gap-1 text-xs text-content-muted">
            <Icon.Clock size={14} /> {item.averagePreparationTime} dk
          </span>
          <div className="flex gap-1">
            <button
              onClick={onEdit}
              className="focus-ring grid h-8 w-8 place-items-center rounded-lg text-content-muted hover:bg-white/5 hover:text-gold"
              aria-label="Düzenle"
            >
              <Icon.Pencil size={16} />
            </button>
            <button
              onClick={onDelete}
              className="focus-ring grid h-8 w-8 place-items-center rounded-lg text-content-muted hover:bg-coral/10 hover:text-coral"
              aria-label="Sil"
            >
              <Icon.Trash size={16} />
            </button>
          </div>
        </div>
      </div>
    </article>
  );
}

function MenuFormModal({
  open,
  onClose,
  restaurantId,
  editing,
  onSaved,
}: {
  open: boolean;
  onClose: () => void;
  restaurantId: string;
  editing: MenuItem | null;
  onSaved: () => void;
}) {
  const toast = useToast();
  const [form, setForm] = useState<MenuItemInput>(EMPTY_INPUT);
  const [priceText, setPriceText] = useState("0,00");
  const [saving, setSaving] = useState(false);

  // Modal açıldığında düzenlenen ürünü forma yükle (yoksa boş).
  useEffect(() => {
    if (!open) return;
    if (editing) {
      setForm({
        name: editing.name,
        category: editing.category,
        imageUrl: editing.imageUrl,
        ingredients: editing.ingredients,
        recipe: editing.recipe,
        averagePreparationTime: editing.averagePreparationTime,
        price: editing.price,
        isAvailable: editing.isAvailable,
      });
      setPriceText(minorToTryInput(editing.price));
    } else {
      setForm(EMPTY_INPUT);
      setPriceText("");
    }
  }, [open, editing]);

  function update<K extends keyof MenuItemInput>(key: K, value: MenuItemInput[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function save() {
    const priceMinor = parseTryToMinor(priceText);
    if (!form.name.trim() || !form.category.trim()) {
      toast.error("Ürün adı ve kategori zorunlu.");
      return;
    }
    if (priceMinor === null) {
      toast.error("Geçerli bir fiyat girin.");
      return;
    }
    const payload: MenuItemInput = {
      ...form,
      price: priceMinor,
      recipe: form.recipe?.trim() ? form.recipe : null,
    };

    setSaving(true);
    try {
      if (editing) {
        await menuService.update(editing.id, payload);
        toast.success("Ürün güncellendi.");
      } else {
        await menuService.create(restaurantId, payload);
        toast.success("Ürün eklendi.");
      }
      onSaved();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Kaydedilemedi.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      size="lg"
      title={editing ? "Ürünü Düzenle" : "Yeni Ürün"}
      description={editing ? "PUT /api/menuitems/{id}" : "POST /api/menuitems"}
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Vazgeç
          </Button>
          <Button loading={saving} onClick={save} icon={<Icon.Check size={18} />}>
            {editing ? "Güncelle" : "Kaydet"}
          </Button>
        </>
      }
    >
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="Ürün adı" required>
          <TextInput value={form.name} onChange={(e) => update("name", e.target.value)} placeholder="Menemen" />
        </Field>
        <Field label="Kategori" required>
          <TextInput value={form.category} onChange={(e) => update("category", e.target.value)} placeholder="Kahvaltılık" />
        </Field>

        <Field label="Görsel URL" className="md:col-span-2">
          <TextInput
            value={form.imageUrl}
            onChange={(e) => update("imageUrl", e.target.value)}
            placeholder="https://…"
          />
        </Field>

        <Field label="İçindekiler" hint="Yaz ve Enter'a bas" className="md:col-span-2">
          <ChipsInput values={form.ingredients} onChange={(next) => update("ingredients", next)} />
        </Field>

        <Field label="Hazırlama süresi (dk)">
          <TextInput
            type="number"
            min={0}
            value={form.averagePreparationTime}
            onChange={(e) => update("averagePreparationTime", Math.max(0, Number(e.target.value)))}
          />
        </Field>
        <Field label="Fiyat (₺)" required hint="Kuruş olarak gönderilir">
          <TextInput value={priceText} onChange={(e) => setPriceText(e.target.value)} placeholder="175,00" inputMode="decimal" />
        </Field>

        <Field label="Tarif / açıklama" className="md:col-span-2">
          <TextArea
            value={form.recipe ?? ""}
            onChange={(e) => update("recipe", e.target.value)}
            placeholder="Sıcak tavada, bol domatesli…"
          />
        </Field>

        <div className="md:col-span-2">
          <div className="flex items-center justify-between rounded-card border border-line bg-ink-900/50 px-4 py-3">
            <div>
              <p className="text-sm font-medium text-content">Satışta mı?</p>
              <p className="text-xs text-content-faint">Kapalıyken müşteri menüsünde &quot;Tükendi&quot; görünür.</p>
            </div>
            <Switch checked={form.isAvailable} onChange={(next) => update("isAvailable", next)} />
          </div>
        </div>
      </div>
    </Modal>
  );
}
