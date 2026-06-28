// Sipariş DTO'larını UI için dönüştüren yardımcılar.
import { OrderItemStatus, OrderSessionStatus } from './config';

// Aynı isimli kalemleri adet ve toplam fiyatla gruplar.
export function groupItems(items = []) {
  const map = new Map();
  for (const it of items) {
    const entry = map.get(it.name) || {
      name: it.name,
      quantity: 0,
      unitPrice: it.price,
      total: 0,
    };
    entry.quantity += 1;
    entry.total += it.price || 0;
    map.set(it.name, entry);
  }
  return [...map.values()];
}

// Siparişin genel durumunu kalem durumlarından türetir.
export function deriveOrderStatus(items = []) {
  if (items.length === 0) return OrderItemStatus.Pending;
  const statuses = items.map((i) => i.status);
  // En "geri"deki kalem siparişin genel durumunu belirler
  return Math.min(...statuses);
}

export function mapOrder(o) {
  const items = o.items || [];
  return {
    id: o.id,
    restaurantId: o.restaurantId,
    tableNo: o.tableNo,
    tableName: `Masa ${o.tableNo}`,
    sessionStatus: o.sessionStatus,
    items,
    grouped: groupItems(items),
    derivedStatus: deriveOrderStatus(items),
    total: o.totalAmount,
    remaining: o.remainingAmount,
  };
}

export const isActiveOrder = (o) =>
  o.sessionStatus === OrderSessionStatus.Active;
