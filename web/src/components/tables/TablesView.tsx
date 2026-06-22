"use client";

import { useMemo, useState } from "react";
import { OrderSessionStatus, PaymentStatus } from "@/lib/enums";
import { formatMinorAsTry } from "@/lib/format";
import type { Bill } from "@/lib/types";
import { billService } from "@/services/orderService";
import { restaurantService } from "@/services/restaurantService";
import { useAsyncData } from "@/hooks/useAsyncData";
import { useOrdersHub } from "@/hooks/useOrdersHub";
import { useDisclosure } from "@/hooks/useDisclosure";
import { useToast } from "@/context/ToastContext";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Drawer } from "@/components/ui/Drawer";
import { PaymentStatusBadge, SessionStatusBadge } from "@/components/ui/StatusBadge";
import { EmptyState, ErrorState, LoadingState } from "@/components/ui/Spinner";
import { Icon } from "@/components/icons";
import { cn } from "@/lib/cn";

export function TablesView({ restaurantId }: { restaurantId: string }) {
  const toast = useToast();
  const { data: bills, loading, error, reload } = useAsyncData<Bill[]>(
    () => billService.byRestaurant(restaurantId),
    [restaurantId],
  );
  useOrdersHub(restaurantId, reload);

  const drawer = useDisclosure();
  const [activeBill, setActiveBill] = useState<Bill | null>(null);
  const [closing, setClosing] = useState(false);

  // En güncel hali listeden eşle (SignalR tazelemesi sonrası drawer da güncellensin).
  const liveBill = useMemo(
    () => (activeBill ? (bills ?? []).find((b) => b.id === activeBill.id) ?? activeBill : null),
    [bills, activeBill],
  );

  function openTable(bill: Bill) {
    setActiveBill(bill);
    drawer.open();
  }

  async function closeSession(bill: Bill) {
    setClosing(true);
    try {
      await restaurantService.closeTableSession(restaurantId, bill.tableNo);
      toast.success(`Masa ${bill.tableNo} oturumu kapatıldı.`);
      drawer.close();
      reload();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Oturum kapatılamadı.");
    } finally {
      setClosing(false);
    }
  }

  if (loading && !bills) return <LoadingState label="Masalar yükleniyor…" />;
  if (error && !bills) return <ErrorState message={error} onRetry={reload} />;

  const list = (bills ?? []).slice().sort((a, b) => a.tableNo - b.tableNo);

  return (
    <>
      {list.length === 0 ? (
        <EmptyState icon={<Icon.Table size={28} />} title="Açık masa bulunmuyor" description="Masa oturumu açıldığında burada görünür." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {list.map((bill) => (
            <TableCard key={bill.id} bill={bill} onClick={() => openTable(bill)} />
          ))}
        </div>
      )}

      <Drawer
        open={drawer.isOpen}
        onClose={drawer.close}
        title={liveBill ? `Masa ${liveBill.tableNo}` : "Masa"}
        subtitle={liveBill ? `Adisyon · ${liveBill.items.length} kalem` : undefined}
        footer={
          liveBill &&
          liveBill.sessionStatus === OrderSessionStatus.Active && (
            <Button variant="coral" className="w-full" loading={closing} onClick={() => closeSession(liveBill)}>
              Oturumu Kapat
            </Button>
          )
        }
      >
        {liveBill && <BillDetail bill={liveBill} />}
      </Drawer>
    </>
  );
}

function TableCard({ bill, onClick }: { bill: Bill; onClick: () => void }) {
  const active = bill.sessionStatus === OrderSessionStatus.Active;
  const paidRatio =
    bill.totalAmount > 0 ? 1 - bill.remainingAmount / bill.totalAmount : bill.remainingAmount === 0 ? 1 : 0;

  return (
    <button
      onClick={onClick}
      className={cn(
        "surface-card group text-left transition-all hover:-translate-y-0.5 hover:border-gold/40",
        active && "ring-1 ring-sage/20",
      )}
    >
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-2.5">
          <span
            className={cn(
              "grid h-11 w-11 place-items-center rounded-xl text-base font-bold",
              active ? "bg-sage/15 text-sage" : "bg-white/5 text-content-muted",
            )}
          >
            {bill.tableNo}
          </span>
          <div>
            <p className="text-sm font-semibold text-content">Masa {bill.tableNo}</p>
            <SessionStatusBadge status={bill.sessionStatus} />
          </div>
        </div>
        <Icon.ArrowRight size={18} className="text-content-faint transition-colors group-hover:text-gold" />
      </div>

      <div className="mt-4 space-y-1.5">
        <div className="flex justify-between text-xs">
          <span className="text-content-muted">Toplam</span>
          <span className="font-semibold text-content">{formatMinorAsTry(bill.totalAmount)}</span>
        </div>
        <div className="flex justify-between text-xs">
          <span className="text-content-muted">Kalan</span>
          <span className={cn("font-semibold", bill.remainingAmount > 0 ? "text-coral" : "text-sage")}>
            {formatMinorAsTry(bill.remainingAmount)}
          </span>
        </div>
        <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-ink-700">
          <div
            className="h-full rounded-full bg-sage transition-all"
            style={{ width: `${Math.round(Math.min(1, Math.max(0, paidRatio)) * 100)}%` }}
          />
        </div>
      </div>
    </button>
  );
}

function BillDetail({ bill }: { bill: Bill }) {
  const paidCount = bill.items.filter((i) => i.paymentStatus === PaymentStatus.Paid).length;

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-2 gap-3">
        <SummaryTile label="Toplam Hesap" value={formatMinorAsTry(bill.totalAmount)} tone="neutral" />
        <SummaryTile label="Kalan Bakiye" value={formatMinorAsTry(bill.remainingAmount)} tone={bill.remainingAmount > 0 ? "coral" : "sage"} />
      </div>

      <div className="flex items-center justify-between">
        <h4 className="text-sm font-semibold text-content">Adisyon Detayı</h4>
        <Badge tone="sage">{paidCount}/{bill.items.length} ödendi</Badge>
      </div>

      <ul className="space-y-2">
        {bill.items.map((item) => (
          <li
            key={item.orderItemId}
            className="flex items-center justify-between gap-3 rounded-card border border-line bg-ink-900/50 px-3.5 py-3"
          >
            <div className="min-w-0">
              <p className="truncate text-sm font-medium text-content">{item.name}</p>
              <p className="text-xs text-content-faint">{item.orderedBy || "Müşteri"}</p>
            </div>
            <div className="flex shrink-0 items-center gap-3">
              <span className="text-sm font-semibold text-content">{formatMinorAsTry(item.price)}</span>
              <PaymentStatusBadge status={item.paymentStatus} />
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

function SummaryTile({ label, value, tone }: { label: string; value: string; tone: "neutral" | "sage" | "coral" }) {
  return (
    <div
      className={cn(
        "rounded-card border px-4 py-3",
        tone === "coral" && "border-coral/30 bg-coral/10",
        tone === "sage" && "border-sage/30 bg-sage/10",
        tone === "neutral" && "border-line bg-ink-900/50",
      )}
    >
      <p className="text-xs text-content-muted">{label}</p>
      <p
        className={cn(
          "mt-1 text-lg font-bold",
          tone === "coral" && "text-coral",
          tone === "sage" && "text-sage",
          tone === "neutral" && "text-content",
        )}
      >
        {value}
      </p>
    </div>
  );
}
