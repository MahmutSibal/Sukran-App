// Merkezi API yapılandırması ve backend ile paylaşılan enum'lar.
// NOT: Backend enum'ları SAYISAL (int) serialize/deserialize eder (bkz. Program.cs).

// Varsayılan olarak boş (aynı origin): istekler Vite proxy'si üzerinden backend'e
// gider. Böylece localhost ve ngrok tüneli (HTTPS) için tek yapılandırma yeter,
// mixed-content/CORS sorunu yaşanmaz. Gerekirse VITE_API_BASE_URL ile ezilebilir.
export const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || ''
).replace(/\/$/, '');

export const HUB_URL = `${API_BASE_URL}/hubs/orders`;

// Ollama yerel LLM ayarları (sohbet baloncuğu için).
// İstekler Vite proxy'si ile /ollama -> http://localhost:11434 adresine yönlenir.
export const OLLAMA_BASE_URL = (
  import.meta.env.VITE_OLLAMA_BASE_URL || '/ollama'
).replace(/\/$/, '');
export const OLLAMA_MODEL = import.meta.env.VITE_OLLAMA_MODEL || 'qwen3.5:9b';

// --- Domain enum'ları (AppSukran.Domain.Enums ile birebir) ---
export const UserRole = {
  SuperAdmin: 1,
  RestaurantOwner: 2,
  Customer: 4,
  Kitchen: 8,
  Waiter: 16,
};

export const ComplaintStatus = {
  New: 1,
  Investigating: 2,
  Responded: 3,
};

export const COMPLAINT_STATUS_LABELS = {
  [ComplaintStatus.New]: 'YENİ',
  [ComplaintStatus.Investigating]: 'İNCELENİYOR',
  [ComplaintStatus.Responded]: 'GERİ DÖNÜŞ YAPILDI',
};

export const OrderSessionStatus = {
  Active: 1,
  Closed: 2,
};

export const OrderItemStatus = {
  Pending: 1,
  Kitchen: 2,
  Preparing: 3,
  Ready: 4,
  Delivered: 5,
};

export const PaymentStatus = {
  Unpaid: 1,
  Processing: 2,
  Paid: 3,
};

export const RestaurantTableStatus = {
  Available: 1,
  Reserved: 2,
  Occupied: 3,
  Closed: 4,
};

// --- UI etiketleri ---
export const ORDER_ITEM_STATUS_LABELS = {
  [OrderItemStatus.Pending]: 'Beklemede',
  [OrderItemStatus.Kitchen]: 'Mutfakta',
  [OrderItemStatus.Preparing]: 'Hazırlanıyor',
  [OrderItemStatus.Ready]: 'Servise Hazır',
  [OrderItemStatus.Delivered]: 'Teslim Edildi',
};

export const USER_ROLE_LABELS = {
  [UserRole.SuperAdmin]: 'Süper Admin',
  [UserRole.RestaurantOwner]: 'İşletme Sahibi',
  [UserRole.Customer]: 'Müşteri',
  [UserRole.Kitchen]: 'Mutfak',
  [UserRole.Waiter]: 'Garson',
};

// Para birimi: backend tutarları "kuruş" cinsinden long olarak tutar.
export function formatPrice(amountInMinor) {
  const value = Number(amountInMinor || 0) / 100;
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    minimumFractionDigits: value % 1 === 0 ? 0 : 2,
  }).format(value);
}

// Kullanıcının girdiği TL'yi backend'in beklediği minor (kuruş) değere çevirir.
export function toMinorAmount(lira) {
  return Math.round(Number(lira || 0) * 100);
}
