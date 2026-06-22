"use client";

import { useMemo, useState } from "react";
import {
  ORDER_ITEM_STATUS_LABEL,
  OrderItemStatus,
  nextItemStatus,
} from "@/lib/enums";
import { formatMinorAsTry } from "@/lib/format";
import type { Order, OrderItem } from "@/lib/types";
import { orderService } from "@/services/orderService";
import { useAsyncData } from "@/hooks/useAsyncData";
import { useOrdersHub } from "@/hooks/useOrdersHub";
import { useToast } from "@/context/ToastContext";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { ItemStatusBadge } from "@/components/ui/StatusBadge";
import { ErrorState, LoadingState } from "@/components/ui/Spinner";
import { Icon } from "@/components/icons";
import { cn } from "@/lib/cn";

interface Ticket {
  order: Order;
  item: OrderItem;
}

const COLUMNS: { key: string; title: string; statuses: OrderItemStatus[]; accent: string }[] = [
  { key: "pending", title: "Bekleyen Siparişler", statuses: [OrderItemStatus.Pending], accent: "text-content-muted" },
  {
    key: "cooking",
    title: "Mutfakta / Hazırlanıyor",
    statuses: [OrderItemStatus.Kitchen, OrderItemStatus.Preparing],
    accent: "text-gold",
  },
  { key: "ready", title: "Hazır", statuses: [OrderItemStatus.Ready], accent: "text-sage" },
];

export function KitchenBoard({ restaurantId }: { restaurantId: string }) {
  const toast = useToast();
  const { data: orders, loading, error, reload, setData } = useAsyncData<Order[]>(
    () => orderService.byRestaurant(restaurantId),
    [restaurantId],
  );

  // SignalR: herhangi bir olayda listeyi tazele.
  const { status: hubStatus } = useOrdersHub(restaurantId, reload);
  const [busyItem, setBusyItem] = useState<string | null>(null);

  const tickets = useMemo<Ticket[]>(() => {
    const list = orders ?? [];
    return list.flatMap((order) => order.items.map((item) => ({ order, item })));
  }, [orders]);

  async function advance(ticket: Ticket) {
    const next = nextItemStatus(ticket.item.status);
    if (next === null) return;
    setBusyItem(ticket.item.orderItemId);

    // İyimser güncelleme — backend onayı ve SignalR yayını arkadan gelir.
    setData((prev) =>
      (prev ?? []).map((o) =>
        o.id !== ticket.order.id
          ? o
          : {
              ...o,
              items: o.items.map((it) =>
                it.orderItemId === ticket.item.orderItemId ? { ...it, status: next } : it,
              ),
            },
      ),
    );

    try {
      await orderService.updateItemStatus(ticket.order.id, ticket.item.orderItemId, next);
      toast.success(`"${ticket.item.name}" → ${ORDER_ITEM_STATUS_LABEL[next]}`);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Durum güncellenemedi.");
      reload();
    } finally {
      setBusyItem(null);
    }
  }

  if (loading && !orders) return <LoadingState label="Siparişler yükleniyor…" />;
  if (error && !orders) return <ErrorState message={error} onRetry={reload} />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <HubIndicator status={hubStatus} />
        <Button size="sm" variant="outline" onClick={reload} icon={<Icon.Pulse size={16} />}>
          Yenile
        </Button>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        {COLUMNS.map((col) => {
          const colTickets = tickets.filter((t) => col.statuses.includes(t.item.status));
          return (
            <section key={col.key} className="flex flex-col rounded-panel border border-line bg-ink-900/40">
              <header className="flex items-center justify-between border-b border-line px-4 py-3">
                <h3 className={cn("text-sm font-semibold", col.accent)}>{col.title}</h3>
                <Badge tone="neutral">{colTickets.length}</Badge>
              </header>
              <div className="flex max-h-[calc(100vh-18rem)] flex-1 flex-col gap-3 overflow-y-auto p-3">
                {colTickets.length === 0 ? (
                  <p className="py-10 text-center text-xs text-content-faint">Bu kolonda sipariş yok</p>
                ) : (
                  colTickets.map((ticket) => (
                    <TicketCard
                      key={`${ticket.order.id}-${ticket.item.orderItemId}`}
                      ticket={ticket}
                      busy={busyItem === ticket.item.orderItemId}
                      onAdvance={() => advance(ticket)}
                    />
                  ))
                )}
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}

function TicketCard({ ticket, busy, onAdvance }: { ticket: Ticket; busy: boolean; onAdvance: () => void }) {
  const { order, item } = ticket;
  const next = nextItemStatus(item.status);

  return (
    <article className="animate-pop-in rounded-card border border-line bg-ink-800 p-3.5 shadow-card">
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2">
          <span className="grid h-8 w-8 place-items-center rounded-lg bg-gold/15 text-xs font-bold text-gold">
            {order.tableNo}
          </span>
          <div>
            <p className="text-sm font-semibold leading-tight text-content">Masa {order.tableNo}</p>
            <p className="text-[11px] text-content-faint">{item.orderedBy || "Müşteri"}</p>
          </div>
        </div>
        <ItemStatusBadge status={item.status} />
      </div>

      <p className="mt-3 text-sm font-medium text-content">{item.name}</p>
      <p className="text-xs text-content-muted">{formatMinorAsTry(item.price)}</p>

      <Button
        size="sm"
        variant={item.status === OrderItemStatus.Ready ? "sage" : "gold"}
        loading={busy}
        onClick={onAdvance}
        className="mt-3 w-full"
        icon={<Icon.ArrowRight size={16} />}
      >
        {next !== null ? ORDER_ITEM_STATUS_LABEL[next] : ""}
      </Button>
    </article>
  );
}

function HubIndicator({ status }: { status: string }) {
  if (status === "connected") {
    return (
      <Badge tone="sage" dot>
        Canlı bağlantı aktif
      </Badge>
    );
  }
  if (status === "connecting") return <Badge tone="gold" dot>Bağlanıyor…</Badge>;
  if (status === "error") return <Badge tone="coral" dot>Bağlantı yok (manuel yenileyin)</Badge>;
  return <Badge tone="neutral">Hazır</Badge>;
}
