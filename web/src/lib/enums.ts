/**
 * Backend enum eşlemeleri (BACKEND_API_DOKUMANI.md ile birebir).
 * İstemci taraf güvenliği için her zaman SAYISAL enum gönderilir.
 */

export enum UserRole {
  SuperAdmin = 1,
  RestaurantOwner = 2,
  WaiterCashier = 3,
  Customer = 4,
}

export enum OrderItemStatus {
  Pending = 1,
  Kitchen = 2,
  Preparing = 3,
  Ready = 4,
  Delivered = 5,
}

export enum PaymentStatus {
  Unpaid = 1,
  Processing = 2,
  Paid = 3,
}

export enum OrderSessionStatus {
  Active = 1,
  Closed = 2,
}

export const USER_ROLE_LABEL: Record<UserRole, string> = {
  [UserRole.SuperAdmin]: "SuperAdmin",
  [UserRole.RestaurantOwner]: "Restoran Sahibi",
  [UserRole.WaiterCashier]: "Garson / Kasa",
  [UserRole.Customer]: "Müşteri",
};

export const ORDER_ITEM_STATUS_LABEL: Record<OrderItemStatus, string> = {
  [OrderItemStatus.Pending]: "Bekliyor",
  [OrderItemStatus.Kitchen]: "Mutfakta",
  [OrderItemStatus.Preparing]: "Hazırlanıyor",
  [OrderItemStatus.Ready]: "Hazır",
  [OrderItemStatus.Delivered]: "Teslim Edildi",
};

export const PAYMENT_STATUS_LABEL: Record<PaymentStatus, string> = {
  [PaymentStatus.Unpaid]: "Ödenmedi",
  [PaymentStatus.Processing]: "İşleniyor",
  [PaymentStatus.Paid]: "Ödendi",
};

export const SESSION_STATUS_LABEL: Record<OrderSessionStatus, string> = {
  [OrderSessionStatus.Active]: "Aktif",
  [OrderSessionStatus.Closed]: "Kapalı",
};

/**
 * Backend enum'ları yanıtlarda sayısal döner; yine de string ("Pending") gelirse
 * bozulmamak için gelen değeri ilgili sayısal enum'a normalize eder.
 */
function coerceEnum<T extends number>(value: unknown, names: Record<string, T>, fallback: T): T {
  if (typeof value === "number") return (value as T) ?? fallback;
  if (typeof value === "string") {
    const numeric = Number(value);
    if (!Number.isNaN(numeric)) return numeric as T;
    const match = names[value.toLowerCase()];
    if (match !== undefined) return match;
  }
  return fallback;
}

export const toOrderItemStatus = (v: unknown): OrderItemStatus =>
  coerceEnum(v, {
    pending: OrderItemStatus.Pending,
    kitchen: OrderItemStatus.Kitchen,
    preparing: OrderItemStatus.Preparing,
    ready: OrderItemStatus.Ready,
    delivered: OrderItemStatus.Delivered,
  }, OrderItemStatus.Pending);

export const toPaymentStatus = (v: unknown): PaymentStatus =>
  coerceEnum(v, {
    unpaid: PaymentStatus.Unpaid,
    processing: PaymentStatus.Processing,
    paid: PaymentStatus.Paid,
  }, PaymentStatus.Unpaid);

export const toOrderSessionStatus = (v: unknown): OrderSessionStatus =>
  coerceEnum(v, {
    active: OrderSessionStatus.Active,
    closed: OrderSessionStatus.Closed,
  }, OrderSessionStatus.Active);

/** Bir kalemin bir sonraki mutfak aşaması (durum ilerletme aksiyonu için). */
export function nextItemStatus(status: OrderItemStatus): OrderItemStatus | null {
  switch (status) {
    case OrderItemStatus.Pending:
      return OrderItemStatus.Kitchen;
    case OrderItemStatus.Kitchen:
      return OrderItemStatus.Preparing;
    case OrderItemStatus.Preparing:
      return OrderItemStatus.Ready;
    case OrderItemStatus.Ready:
      return OrderItemStatus.Delivered;
    default:
      return null;
  }
}
