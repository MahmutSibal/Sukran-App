import {
  ORDER_ITEM_STATUS_LABEL,
  OrderItemStatus,
  OrderSessionStatus,
  PAYMENT_STATUS_LABEL,
  PaymentStatus,
  SESSION_STATUS_LABEL,
} from "@/lib/enums";
import { Badge } from "./Badge";

const itemTone: Record<OrderItemStatus, "neutral" | "gold" | "sage"> = {
  [OrderItemStatus.Pending]: "neutral",
  [OrderItemStatus.Kitchen]: "gold",
  [OrderItemStatus.Preparing]: "gold",
  [OrderItemStatus.Ready]: "sage",
  [OrderItemStatus.Delivered]: "sage",
};

export function ItemStatusBadge({ status }: { status: OrderItemStatus }) {
  return (
    <Badge tone={itemTone[status]} dot>
      {ORDER_ITEM_STATUS_LABEL[status]}
    </Badge>
  );
}

export function PaymentStatusBadge({ status }: { status: PaymentStatus }) {
  const tone = status === PaymentStatus.Paid ? "sage" : status === PaymentStatus.Processing ? "gold" : "coral";
  return <Badge tone={tone}>{PAYMENT_STATUS_LABEL[status]}</Badge>;
}

export function SessionStatusBadge({ status }: { status: OrderSessionStatus }) {
  return (
    <Badge tone={status === OrderSessionStatus.Active ? "sage" : "neutral"} dot>
      {SESSION_STATUS_LABEL[status]}
    </Badge>
  );
}
