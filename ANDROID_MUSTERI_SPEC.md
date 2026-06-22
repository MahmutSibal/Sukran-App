# Şükran App — Native Android (Müşteri) Uygulaması Şartnamesi

> Bu doküman, mevcut .NET backend + Flutter referans uygulamasına **birebir uyumlu**
> native Android (Kotlin + Jetpack Compose) **müşteri** uygulaması üretmek içindir.
> Google AI / Android Studio'ya bu dokümanı verip kod ürettirebilirsin.

---

## 0. Teknoloji Yığını (önerilen)

| Katman | Teknoloji |
|---|---|
| Dil / UI | **Kotlin + Jetpack Compose** (Material 3) |
| Mimari | **MVVM + Clean Architecture** (UI → ViewModel → Repository → Retrofit) |
| Ağ | **Retrofit2 + OkHttp + Moshi/Gson** |
| Realtime | **SignalR** (`com.microsoft.signalr:signalr`) |
| State | **ViewModel + StateFlow** (Flutter'daki Riverpod provider'larının karşılığı) |
| DI | **Hilt** |
| Navigasyon | **Navigation-Compose** |
| QR | **CameraX + ML Kit Barcode Scanning** |
| Konum | **FusedLocationProviderClient** (Google Play Services Location) |
| Güvenli depolama | **EncryptedSharedPreferences** (token + kart no için) |

> NOT: Flutter tarafındaki "controller / provider" kavramı Android'de **ViewModel**'e,
> "repository" aynı isimle **Repository** sınıfına karşılık gelir.

---

## 1. Backend Bağlantı Bilgileri

```
BASE_URL = https://starr-haustorial-robin.ngrok-free.dev
SignalR Hub = {BASE_URL}/hubs/orders
```

- Para birimi: **tüm fiyatlar `long` / kuruş (minor unit)**. Örn `15000` = `150,00 TL`.
  Gösterirken `amount / 100` yapıp `tr_TR` formatla.
- Kimlik doğrulama: **Bearer JWT**. QR oturumu açınca dönen `accessToken` saklanır ve
  korumalı tüm isteklerde `Authorization: Bearer <token>` header'ı eklenir.
- ngrok kullanıyorsan her isteğe `ngrok-skip-browser-warning: true` header'ı ekle.

---

## 2. Kimlik & Oturum Akışı (kritik)

Müşteri **e-posta/şifre ile giriş yapmaz**. Akış tamamen QR tabanlıdır:

1. Müşteri "QR Okut"a basar → kamera açılır (gizlilik için **önceden açılmaz**).
2. QR payload algılanır algılanmaz **arka planda** `POST /api/auth/qr-session` çağrılır.
   Manuel "Masa No / Token gir" alanı **YOKTUR**. Buton da yoktur; otomatik geçer.
3. Başarılıysa dönen `accessToken`, `restaurantId`, `tableNo`, `tableSessionId`
   güvenli depoya yazılır ve **doğrudan Menü ekranına** geçilir.

QR payload iki formatı destekler:
- JSON: `{"restaurantId":"...","tableNo":8,"qrToken":"..."}`
- Düz token string (eksik alanlar demo değerle tamamlanır).

---

## 3. API Controller'ları & Endpoint'ler (parametrelerle)

### 3.1 AuthController — `[AllowAnonymous]`
| Method | Path | Body | Yanıt |
|---|---|---|---|
| POST | `/api/auth/qr-session` | `CreateQrSessionRequest` | `QrSessionResponse` |
| POST | `/api/auth/refresh` | `{ "refreshToken": string }` | `TokenResponse` |
| POST | `/api/auth/logout` | `{ "refreshToken": string }` | 204 |

**CreateQrSessionRequest:**
```json
{ "restaurantId": "string", "tableNo": 8, "qrToken": "string" }
```

### 3.2 RestaurantsController — anonim okunur
| Method | Path | Query/Param | Yanıt |
|---|---|---|---|
| GET | `/api/restaurants/nearby` | `?longitude={d}&latitude={d}` | `List<NearbyRestaurantDto>` |
| GET | `/api/restaurants/{restaurantId}` | — | `RestaurantDetailResponse` |
| GET | `/api/restaurants/by-slug/{slug}` | — | `RestaurantDetailResponse` |
| GET | `/api/restaurants/{restaurantId}/tables/{tableNo}/session` | — | masa oturum bilgisi |

### 3.3 MenuItemsController — okuma herkese açık
| Method | Path | Yanıt |
|---|---|---|
| GET | `/api/menuitems/restaurant/{restaurantId}` | `List<MenuItemResponse>` |
| GET | `/api/menuitems/{menuItemId}` | `MenuItemResponse` |

### 3.4 OrdersController — `[Authorize]` (Bearer gerekli)
| Method | Path | Body | Yanıt |
|---|---|---|---|
| POST | `/api/orders` | `CreateOrderCommand` | `string` (orderId) |
| GET | `/api/orders/restaurant/{restaurantId}` | — | `List<OrderResponse>` |
| GET | `/api/orders/{orderId}` | — | `OrderResponse` |

**CreateOrderCommand (POST gövdesi):**
```json
{
  "restaurantId": "string",
  "tableNo": 8,
  "tableSessionId": "string",
  "qrToken": "string (accessToken kullanılıyor)",
  "items": [
    {
      "menuItemId": "string",
      "name": "string",
      "price": 15000,
      "orderedBy": "Masa 8",
      "status": 1,
      "paymentStatus": 1
    }
  ]
}
```
> `status: 1` = pending, `paymentStatus: 1` = unpaid (enum int değerleri, bkz. §5).

### 3.5 BillsController — `[Authorize]`
| Method | Path | Yanıt |
|---|---|---|
| GET | `/api/bills/{billId}` | `BillResponse` |
| GET | `/api/bills/restaurant/{restaurantId}` | `List<BillResponse>` |

### 3.6 PaymentsController — `[Authorize]` ("Akıllı Ödeme" 3 yöntem)
| Method | Path | Body |
|---|---|---|
| POST | `/api/payments/specific-items` | `PaySpecificItemsRequest` |
| POST | `/api/payments/split-equally` | `SplitEquallyRequest` |
| POST | `/api/payments/custom-amount` | `PayCustomAmountRequest` |

Hepsi `PaymentResultDto` döner. Kart alanları **opsiyonel** (null ise nakit/kasada öde):
```json
// specific-items
{ "billId":"...", "itemIds":["..."], "paidByUserId":"...",
  "customerCardId":null, "cardNumber":null, "cvc":null }

// split-equally
{ "billId":"...", "personCount":2, "paidByUserId":"...",
  "customerCardId":null, "cardNumber":null, "cvc":null }

// custom-amount  (amount = long/kuruş)
{ "billId":"...", "amount":5000, "paidByUserId":"...",
  "customerCardId":null, "cardNumber":null, "cvc":null }
```

### 3.7 CustomerCardsController — `[Authorize(Roles="Customer")]`
| Method | Path | Body | Yanıt |
|---|---|---|---|
| GET | `/api/customercards/me` | — | `List<CustomerCardResponse>` |
| POST | `/api/customercards` | `CreateCustomerCardRequest` | `CustomerCardResponse` |
| POST | `/api/customercards/verify` | `VerifyCustomerCardRequest` | `CustomerCardVerificationResponse` |
| DELETE | `/api/customercards/{customerCardId}` | — | 204 |

```json
// CreateCustomerCardRequest
{ "cardholderName":"AD SOYAD", "cardNumber":"4111...", "expiryMonth":12,
  "expiryYear":2027, "cvv":"123", "isDefault":true }

// VerifyCustomerCardRequest
{ "customerCardId":"...", "cardNumber":"4111..." }
```
> GÜVENLİK: Kart numarası sunucuda **şifreli** saklanır. Tam numara hiçbir yerde
> açıkta tutulmaz. Cihazda tam numara gerekirse **EncryptedSharedPreferences**'a
> kart id ile yaz; ekranda yalnızca `•••• {last4}` göster.

---

## 4. SignalR — Canlı Sipariş Akışı

```
Hub URL: {BASE_URL}/hubs/orders
Auth: accessTokenFactory ile Bearer token gönder
```

Bağlanınca:
1. `connection.start()`
2. `connection.invoke("JoinRestaurantGroup", restaurantId)`
3. Dinlenecek event'ler: **`orderCreated`** ve **`orderUpdated`**
4. Her event geldiğinde → `GET /api/orders/restaurant/{restaurantId}` ile listeyi
   yeniden çek ve UI'ı güncelle (event payload'ına güvenme, tetikleyici olarak kullan).
5. `withAutomaticReconnect()` aç.

---

## 5. Veri Modelleri (DTO) — birebir alanlar

> Enum'lar JSON'da **int** veya **string** gelebilir; her ikisini de parse et.

**Enum int eşlemeleri:**
```
OrderItemStatus:  1=pending, 2=kitchen, 3=preparing, 4=ready, 5=delivered
PaymentStatus:    1=unpaid, 2=processing, 3=paid
OrderSessionStatus: 1=active, 2=closed
```

```kotlin
// QrSessionResponse
data class QrSessionResponse(
    val accessToken: String, val expiresAt: String,
    val restaurantId: String, val tableNo: Int, val tableSessionId: String)

// TokenResponse
data class TokenResponse(
    val accessToken: String, val refreshToken: String,
    val refreshTokenExpiresAt: String)

// NearbyRestaurantDto
data class NearbyRestaurantDto(
    val id: String, val slug: String, val name: String, val address: String,
    val longitude: Double, val latitude: Double, val distanceMeters: Double)

// RestaurantDetailResponse
data class RestaurantDetailResponse(
    val id: String, val slug: String, val name: String, val address: String,
    val longitude: Double, val latitude: Double)

// MenuItemResponse
data class MenuItemResponse(
    val id: String, val restaurantId: String, val category: String,
    val name: String, val imageUrl: String, val ingredients: List<String>,
    val recipe: String?, val averagePreparationTime: Int,
    val price: Long,           // kuruş
    val isAvailable: Boolean)

// OrderItemResponse
data class OrderItemResponse(
    val orderItemId: String, val menuItemId: String, val name: String,
    val price: Long, val orderedBy: String,
    val status: OrderItemStatus, val paymentStatus: PaymentStatus)

// OrderResponse  (BillResponse alanları birebir aynı)
data class OrderResponse(
    val id: String, val restaurantId: String, val tableNo: Int,
    val sessionStatus: OrderSessionStatus, val items: List<OrderItemResponse>,
    val totalAmount: Long, val remainingAmount: Long)

// PaymentResultDto
data class PaymentResultDto(
    val billId: String, val paidAmount: Long,
    val remainingAmount: Long, val status: String)

// CustomerCardResponse
data class CustomerCardResponse(
    val id: String, val cardholderName: String, val brand: String,
    val last4: String, val expiryMonth: Int, val expiryYear: Int,
    val isDefault: Boolean, val isActive: Boolean, val createdAt: String)

// CustomerCardVerificationResponse
data class CustomerCardVerificationResponse(
    val isValid: Boolean, val brand: String, val last4: String, val message: String)
```

---

## 6. Controller (ViewModel) + Repository Katmanı

Android'de her Flutter provider'ı bir **Repository** + ilgili **ViewModel** olarak kur.
Aşağıda gereken sınıflar ve metot imzaları (parametrelerle) verilmiştir.

### 6.1 SessionRepository / SessionViewModel
```kotlin
suspend fun createQrSession(restaurantId: String, tableNo: Int, qrToken: String): QrSessionResponse
suspend fun loadSavedSession(): CustomerSession?   // depodan
suspend fun fetchNearbyRestaurants(longitude: Double, latitude: Double): List<NearbyRestaurantDto>
fun clearSession()
```
`CustomerSession` (cihazda saklanan): `restaurantId, tableNo, tableSessionId, accessToken, expiresAt`.

### 6.2 MenuRepository / MenuViewModel
```kotlin
suspend fun fetchMenuItems(restaurantId: String): List<MenuItemResponse>
suspend fun createOrder(session: CustomerSession, selectedItems: List<MenuItemResponse>): OrderResponse
```

### 6.3 CartViewModel (sepet — state)
```kotlin
val cart: StateFlow<Map<String, Int>>   // menuItemId -> adet
fun increment(menuItemId: String)
fun decrement(menuItemId: String)   // 1'in altına inerse kaldır
fun clear()
// hesaplananlar: toplam tutar, ürün adedi
```

### 6.4 OrderRepository / OrderTrackingViewModel
```kotlin
fun watchOrdersByRestaurant(restaurantId: String, accessToken: String): Flow<List<OrderResponse>>
// SignalR event -> GET /api/orders/restaurant/{id} -> emit
suspend fun fetchOrders(restaurantId: String): List<OrderResponse>
```
> Aktif masa siparişi = `orders.filter { it.tableNo == session.tableNo }`. İlk eleman gösterilir.

### 6.5 PaymentRepository / PaymentViewModel
```kotlin
suspend fun paySpecificItems(billId: String, itemIds: List<String>, paidByUserId: String,
    customerCardId: String? = null, cardNumber: String? = null, cvc: String? = null): PaymentResultDto
suspend fun splitEqually(billId: String, personCount: Int, paidByUserId: String,
    customerCardId: String? = null, cardNumber: String? = null, cvc: String? = null): PaymentResultDto
suspend fun payCustomAmount(billId: String, amount: Long, paidByUserId: String,
    customerCardId: String? = null, cardNumber: String? = null, cvc: String? = null): PaymentResultDto
```

### 6.6 CustomerCardRepository / CardsViewModel
```kotlin
suspend fun fetchMyCards(): List<CustomerCardResponse>
suspend fun createCard(cardholderName: String, cardNumber: String, expiryMonth: Int,
    expiryYear: Int, cvv: String, isDefault: Boolean): CustomerCardResponse
suspend fun verifyCard(customerCardId: String, cardNumber: String): CustomerCardVerificationResponse
suspend fun deleteCard(customerCardId: String)
// yerel: readStoredCardNumber(cardId), storeCardNumber(cardId, number)  -> EncryptedSharedPreferences
```
İstemci tarafı doğrulama gerekenler:
- **Luhn** kart no geçerliliği
- Son kullanma > bugün
- CVV 3-4 hane
- Kart markası tespiti (numaranın ilk hanelerinden: Visa/Mastercard/Amex/Troy)
- 2 haneli yıl → 4 haneye tamamla (`25 -> 2025`)

---

## 7. Ekranlar (navigasyon + içerik)

```
graph: Start → (QR + Konum) → Menü → Sipariş Takibi → Ödeme
Alt navigasyon (Home shell): [Tara] [Keşfet] [Profil]
```

### 7.1 QR & Konum Ekranı  (route: qr)
- Üstte başlık + alt açıklama.
- Orta: kamera kapalıyken **"Kamera kapalı / Gizliliğiniz için..."** paneli + **"QR Okut"** butonu (altın).
  Basınca CameraX + ML Kit ile tarama başlar; gold köşeli + tarama çizgili reticle overlay.
- QR algılanınca otomatik `createQrSession` → başarı → Menü'ye git. Hata → snackbar + tekrar dene.
- Altta **Konum Doğrulama kartı**: lat/lon, hedefe uzaklık (m), progress bar,
  "Menzilde / Yaklaşın" durumu (hedef ~20 m). FusedLocation ile konum al; izin yoksa
  varsayılan İstanbul koordinatı (lat 40.9867, lon 29.0293).

### 7.2 Menü Ekranı  (route: menu)
- SliverAppBar "Dijital Menü" + sağ üstte sipariş takibi ikonu.
- Masa başlık kartı ("Masa 8 • siparişleriniz canlı tutulur").
- Yatay **kategori chip** şeridi ("Tüm Menü" + benzersiz kategoriler).
- 2 sütunlu **ürün grid'i** (kart: görsel + gradient overlay, ad, fiyat, + butonu / adet stepper).
  `isAvailable=false` ise "Tükendi" rozeti, + pasif.
- Sepet doluysa altta **akıllı sepet barı** (X ürün • toplam • "Sipariş Ver" altın buton)
  → bottom sheet'te sepet detayı (adet ±, satır toplamları, genel toplam).
- "Sipariş Ver" → `createOrder` → Sipariş Takibi'ne git, sepeti temizle.

### 7.3 Sipariş Takibi Ekranı  (route: orders)
- Üstte **Sipariş Hero kartı**: Masa no, kalem sayısı, toplam, kalan tutar.
- `remainingAmount > 0` ise: **"Hesap Öde"** (Akıllı Ödeme sheet) + **Kartla Ödeme paneli**
  (varsayılan kart `•••• last4`, "Kayıtlı kartla öde").
- **Canlı Zaman Tüneli**: her order item için durum düğümü (animasyonlu;
  preparing/kitchen'da dönen ikon, ready/delivered'da parlayan tik), 5 aşamalı stage dots,
  durum chip'i. SignalR ile anlık güncellenir.
- Aktif sipariş yoksa boş durum kartı.

### 7.4 Akıllı Ödeme Sheet (3 sekme)
- **Seçili Ürünler** → `paySpecificItems(itemIds=...)`
- **Eşit Böl** → `splitEqually(personCount=...)`
- **Tutar Gir** → `payCustomAmount(amount=...)`
- Her sekmede: kayıtlı kart seç / yeni kart / nakit. Ödeme sonrası listeyi invalidate et.

### 7.5 Profil Ekranı  (route: profile, Home shell sekmesi)
- Profil başlığı (rol "Müşteri", oturum durumu).
- Aktif masa kartı (`restaurantId • Masa {tableNo}`).
- **Kartlarım** bölümü: kart ekleme formu (ad, no, AA, YY/YYYY, CVV, varsayılan switch,
  "sunucuda şifreli saklanır" notu) + kayıtlı kart listesi (Doğrula / Sil menüsü).
- **Çıkış Yap**.

### 7.6 Keşfet Ekranı  (route: discover, Home shell sekmesi)
- Yakındaki restoranlar / yol tarifi (nearby + route servisi). Opsiyonel; MVP'de basit liste.

---

## 8. Tema & Renkler (Material 3 — DARK birincil)

> Marka: **derin zümrüt yeşili + mat altın**. "Sade ama hissi güçlü" premium dark dil.
> Tüm müşteri ekranları dikey yeşil degrade arka plan kullanır.

### 8.1 Dark palet (ana tema)
```kotlin
object SukranDark {
    val BgTop        = Color(0xFF08210F)  // arka plan degrade üst
    val BgBottom     = Color(0xFF103D24)  // arka plan degrade alt
    val Surface      = Color(0xFF143A26)  // kart/konteyner (yeşil füme)
    val SurfaceHigh  = Color(0xFF1C4A31)  // iç içe yüzey / divider
    val InputFill    = Color(0xFF173E29)  // form alanı
    val Accent       = Color(0xFFDDA15E)  // MAT ALTIN — birincil aksiyon
    val AccentBright = Color(0xFFE9C46A)  // parlak altın (vurgu/glow/degrade)
    val TextPrimary  = Color(0xFFF5EFE0)  // sıcak fildişi
    val TextSecondary= Color(0xFFA9BCAD)  // soluk adaçayı
    val Success      = Color(0xFF6FCF97)
    val Danger       = Color(0xFFFF8A80)
    val Hairline     = Color(0x33DDA15E)  // altın @ %20 kenarlık
    val OnAccent     = Color(0xFF1A1206)  // altın buton üzeri koyu yazı
}
```

**Arka plan degradesi (her ekran):** `Brush.verticalGradient(listOf(BgTop, BgBottom))`
**Altın CTA degrade:** `Brush.linearGradient(listOf(AccentBright, Accent))`

### 8.2 Light palet (opsiyonel/yedek)
```kotlin
val Primary   = Color(0xFF103D24)  // marka koyu yeşil
val Accent    = Color(0xFFDDA15E)  // altın
val Background = Color(0xFFF6F3E9) // sıcak ivory
val Surface   = Color(0xFFFFFFFF)
val SoftSage  = Color(0xFFE3EDE2)
val Sand      = Color(0xFFEAE2CE)
```

### 8.3 Geometri & tipografi
```
Modül/kart radius: 28dp  (büyük sheet/dialog: 32dp)
Buton/input radius: 16dp
Chip radius: tam yuvarlak (999)
Ekran kenar boşluğu: 20dp
Kart gölgesi: siyah %40, blur 30, offset (0,18)
Başlıklar: FontWeight 800, hafif negatif letterSpacing
CTA buton yazısı: FontWeight 900
```

### 8.4 Bileşen stilleri
- **AppBar:** transparent zemin, foreground = TextPrimary, elevation 0.
- **Kart:** `Surface` + `Hairline` border + yumuşak gölge, radius 28.
- **Altın buton:** `AccentBright→Accent` gradient zemin, koyu (`OnAccent`) yazı,
  altın glow gölgesi (alpha 0.4, blur 18, offset 0,8).
- **Input:** `InputFill` dolgu, border yok; focus'ta altın 1.2dp border.
- **Chip (seçili):** altın gradient + koyu yazı; (seçilmemiş): `SurfaceHigh` + hairline.
- **Durum renkleri (sipariş):** pending=TextSecondary, kitchen/preparing=Accent,
  ready/delivered=Success.

---

## 9. Önemli Kurallar / Tuzaklar

1. **Para birimi kuruş**: backend `long`. Asla ondalık gönderme; `*100` / `/100`.
2. **QR ekranında manuel giriş YOK**; kamera kullanıcı başlatana kadar **kapalı**.
3. **Bearer token** her korumalı istekte; 401'de `refresh` dene, olmazsa QR'a dön.
4. **Kart numarası** ekranda asla tam gösterilmez; cihazda yalnız Encrypted depo.
5. **SignalR event'i sadece tetikleyici** — gerçek veriyi REST'ten çek.
6. **ngrok** kullanıyorsan `ngrok-skip-browser-warning` header'ı ekle.
7. `paidByUserId` = oturumdaki kullanıcı id'si (yoksa `tableSessionId`).
8. **İzinler (AndroidManifest):** `CAMERA`, `ACCESS_FINE_LOCATION`, `INTERNET`.

---

## 10. Google AI'a Verilecek Kısa Komut (örnek)

> "Aşağıdaki şartnameye göre **Kotlin + Jetpack Compose (Material 3)** ile bir
> **restoran müşteri** Android uygulaması oluştur. MVVM + Hilt + Retrofit + Moshi,
> SignalR ile canlı sipariş takibi, CameraX+ML Kit ile QR, FusedLocation ile konum.
> §8'deki dark tema ve renkleri birebir uygula. §3'teki endpoint'leri ve §5'teki
> DTO'ları aynen kullan. Ekranlar: QR/Konum → Menü → Sipariş Takibi → Ödeme +
> Profil/Kartlarım + Keşfet. [şartnameyi yapıştır]"
