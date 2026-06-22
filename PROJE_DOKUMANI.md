# Sukran App — Detaylı Teknik Doküman

> Restoran sipariş & ödeme platformu. QR ile masa oturumu açma, gerçek zamanlı sipariş takibi (SignalR), akıllı hesap bölüştürme, çok kiracılı (multi-tenant) yönetim.
> **Tarih:** 2026-06-13 · **Sürüm:** 0.1.0

---

## 1. Genel Bakış

Sukran App üç bağımsız ama entegre katmandan oluşur:

| Katman | Teknoloji | Hedef Kitle | Konum |
|--------|-----------|-------------|-------|
| **Backend API** | .NET (C#), Clean Architecture + CQRS/MediatR, MongoDB, SignalR, JWT | — | `backend/src/` |
| **Mobil Uygulama** | Flutter (Dart), Riverpod, go_router | Müşteri (+ owner/admin web görünümü) | `lib/` |
| **Web Paneli** | Next.js 15 (App Router), React 19, TypeScript, Tailwind | Restoran sahibi, garson/kasiyer, süper admin | `web/` |

### Roller
- **SuperAdmin** — tüm kiracıları (restoranları) ve kullanıcıları yönetir.
- **RestaurantOwner** — kendi restoranının menüsünü, masalarını, mutfağını yönetir.
- **WaiterCashier** — garson/kasiyer (web panelinde mutfak + masa görünümü).
- **Customer** — mobil uygulamadan QR okutur, sipariş verir, öder.

### Uçtan Uca Akış
```
Müşteri (mobil) → QR okut → masa oturumu (JWT) → menü → sipariş
        ↓ (SignalR: orderCreated)
Mutfak (web) → canlı sipariş kartları → durum ilerlet (Pending→...→Delivered)
        ↓ (SignalR: orderUpdated)
Müşteri (mobil) → canlı sipariş durumu → akıllı ödeme (3 seçenek)
        ↓
Backend → POS webhook (HttpPosBridgeService) + AuditLog
```

---

## 2. Backend (.NET — Clean Architecture)

### 2.1 Katman Yapısı
```
backend/src/
├── AppSukran.API            → Controllers, Middleware, Program.cs (Presentation)
├── AppSukran.Application    → CQRS Command/Query + Handler + Validator (MediatR)
├── AppSukran.Domain         → Entities, Enums, AggregateRoot (iş kuralları)
└── AppSukran.Infrastructure → MongoDB, JWT, SignalR, POS entegrasyon, güvenlik
```

**Kullanılan desenler:** CQRS (MediatR), Repository + UnitOfWork, FluentValidation pipeline behavior, Optimistic Concurrency (Version alanı), Hosted Services (index init + seeder).

**Program.cs konfigürasyonu:** MediatR + validator kaydı, JWT auth (HS256), SignalR hub `/hubs/orders`, rate limiting (`orders-write` 30/dk, `payments-write` 20/dk), CORS (localhost:3000/3001), ForwardedHeaders, global exception middleware.

### 2.2 API Endpoint Haritası

#### AuthController — `api/auth` (AllowAnonymous)
| Metot | Path | Açıklama |
|-------|------|----------|
| POST | `/qr-session` | QR ile masa oturumu açar, kısa ömürlü JWT döner (4 saat) |
| POST | `/register` | Kullanıcı kaydı (Customer/Owner) → TokenResponse |
| POST | `/login` | Email + şifre → access + refresh token |
| POST | `/refresh` | Access token yenile (HttpOnly cookie `appsukran_refresh` fallback) |
| POST | `/logout` | Refresh token iptal + cookie temizle |

#### OrdersController — `api/orders` (Authorize, rate-limit: orders-write)
| Metot | Path | Açıklama |
|-------|------|----------|
| GET | `/{orderId}` | Sipariş detayı |
| GET | `/restaurant/{restaurantId}` | Restoranın siparişleri |
| POST | `/` | Sipariş oluştur |
| PUT | `/{orderId}/status` | Oturum durumu (Active/Closed) |
| PUT | `/{orderId}/items/{orderItemId}/status` | Ürün durumu (Pending→...→Delivered) |
| DELETE | `/{orderId}` | Sipariş sil |

#### BillsController — `api/bills` (Authorize, rate-limit: orders-write)
GET `/{billId}`, GET `/restaurant/{restaurantId}`, POST `/`, PUT `/{billId}`, DELETE `/{billId}`, PUT `/{billId}/items/{orderItemId}/status`

#### PaymentsController — `api/payments` (Authorize, rate-limit: payments-write 20/dk)
| Metot | Path | Açıklama |
|-------|------|----------|
| POST | `/specific-items` | Seçili ürünleri öde (ItemIds[]) |
| POST | `/split-equally` | Eşit bölüş (PersonCount) |
| POST | `/custom-amount` | Özel tutar gir |

İsteğe bağlı `CustomerCardId` + `CardNumber` ile kart doğrulaması.

#### MenuItemsController — `api/menuitems`
GET `/{id}` ve GET `/restaurant/{restaurantId}` herkese açık; POST/PUT/DELETE Owner gerektirir (kategori, ad, görsel, malzemeler, tarif, hazırlık süresi, fiyat, stok durumu).

#### RestaurantsController — `api/restaurants`
GET `/nearby?lon=&lat=&maxDistance=` (MongoDB 2dsphere geo-arama), GET `/{id}`, GET `/by-slug/{slug}`, GET `/{id}/tables/{tableNo}/session?token=`, POST `/` (SuperAdmin).

#### RestaurantTablesController — `api/restaurants/{restaurantId}/tables` (SuperAdmin|Owner)
POST `/{tableNo}/session/open`, POST `/{tableNo}/session/close`.

#### CustomerCardsController — `api/customercards` (Customer)
GET `/me`, POST `/`, POST `/verify`, DELETE `/{customerCardId}`. Kart numarası hash'lenerek saklanır (sadece Last4 + hash).

#### UsersController — `api/users` (SuperAdminOnly policy)
GET `/`, POST `/`, PUT `/{userId}/role`, PUT `/{userId}/reset-password`, DELETE `/{userId}`.

#### ⚠️ Temizlenmesi gereken: `ProductsController` (int ID'li legacy), `WeatherForecastController` (şablon kodu).

### 2.3 Domain Modeli

**Entities:** `AggregateRoot` (Id=GUID, CreatedAt, Version) tabanlı. `User`, `RefreshToken`, `Order`, `Bill` (Order'dan türer), `OrderItem`, `MenuItem`, `Restaurant` (+ GeoPoint konum, RestaurantTable listesi, Financials), `RestaurantTable`, `CustomerCard` (hash + last4), `AuditLog`. `Product` legacy (int ID — tutarsız).

**Enums:**
- `UserRole`: SuperAdmin=1, RestaurantOwner=2, Customer=4
- `OrderSessionStatus`: Active, Closed
- `OrderItemStatus`: Pending → Kitchen → Preparing → Ready → Delivered
- `PaymentStatus`: Unpaid, Processing, Paid
- `RestaurantTableStatus`: Available, Reserved, Occupied, Closed

### 2.4 Güvenlik
- **JWT** (`JwtTokenService`): HS256, claim'ler sub/email/role/nameid. QR token özel subject `qr:{restaurantId}:{tableNo}:{sessionId}`, 4 saat ömür. `JWT_SIGNING_KEY` env değişkeniyle override edilebilir.
- **Şifre** (`PasswordHashingService`): PBKDF2-SHA256, 100.000 iterasyon, 16-byte salt, `FixedTimeEquals` (timing-attack dirençli).
- **Kart** (`CardNumberProtectionService`): PBKDF2 hash, Luhn doğrulama, brand tespiti, son kullanma kontrolü; düz metin saklanmaz (PCI yaklaşımı).
- **RefreshToken** (`RefreshTokenService`): 64-byte random → SHA256 hash, 7 gün, rotasyon + iptal takibi.

### 2.5 Persistence (MongoDB)
- `MongoDbContext` (scoped, transaction destekli), `MongoGenericRepository<T>` (optimistic concurrency: Version uyuşmazlığında "Concurrency conflict" hatası), `MongoUnitOfWork`.
- `MongoIndexInitializer` (hosted): unique email, unique refresh-token-hash, 2dsphere konum indeksi, menü/restoran/sipariş bileşik indeksleri.
- `SuperAdminSeeder` (hosted): ayarda Enabled ise süper admin tohumlar (prod'da `false`, dev'de `true`).

### 2.6 Realtime (SignalR)
`OrderHub` (`/hubs/orders`): `JoinRestaurantGroup` / `LeaveRestaurantGroup` ile restoran-bazlı gruplar. `MongoOrderRealtimePublisher`, `orderCreated` / `orderUpdated` event'lerini ilgili restoran grubuna yayınlar.

### 2.7 POS Entegrasyonu
`IPosBridgeService` / `HttpPosBridgeService`: ödeme tamamlanınca `IntegrationSettings.PosWebhookUrl`'e `PosBridgeEvent` POST eder (URL boşsa atlar).

### 2.8 Ödeme Mantığı
- **PaySpecificItems:** İki fazlı transaction — önce ürünleri `Processing`'e çeker, sonra `Paid` yapar, kalan tutarı günceller → POS bildirimi + AuditLog. Kart `PaidByUserId == currentUser` kontrolü var.
- **SplitEqually:** `RemainingAmount / PersonCount` kadar düşer.
- **PayCustomAmount:** Girilen tutarı kalan bakiyeden düşer.

> ⚠️ Üç yöntem de **gerçek bir ödeme gateway'i çağırmıyor** — sadece bill bakiyesini düşürüp POS webhook'una haber veriyor. Finansal açıdan kritik eksik (aşağıda).

---

## 3. Mobil Uygulama (Flutter)

### 3.1 Mimari
`ProviderScope` (Riverpod) → `MaterialApp.router` (go_router) → `AppTheme.dark()`. Feature-based klasör yapısı: `core/` (config, network, realtime, storage, theme, models, demo) + `features/` (auth, customer, discover, landing, menu, orders, payments, session, superadmin, web_panel, waiter).

**Rotalar:** `/` (AuthGate), `/customer`, `/customer/qr`, `/customer/menu`, `/customer/orders`, `/customer/discover`, `/admin`.

**State yönetimi:** AsyncNotifier (auth, tenants), FutureProvider (menü, restoran), StreamProvider (realtime siparişler), StateProvider (sepet, filtreler).

### 3.2 Ekranlar
- **Auth:** `auth_gate_screen` (role göre yönlendirme), `auth_entry_screen` (glassmorphism giriş/kayıt sekmeleri).
- **Customer:** `customer_home_shell` (3 sekme: QR / Keşfet / Profil), `customer_qr_session_screen` (mobile_scanner ile QR → `/api/auth/qr-session`), `customer_menu_screen` (kategori filtre + sepet), `customer_order_status_screen` (SignalR canlı durum), `customer_card_management_section` (kart ekle/sil, secure storage).
- **Discover:** `customer_discover_screen` — flutter_map (OpenStreetMap) + geolocator GPS + `/api/restaurants/nearby` + OSRM rota hesaplama, Google Maps'e yönlendirme.
- **Payments:** `smart_payment_sheet` — 3 sekme (kendi ürünlerim / eşit bölüş / tutar gir) + opsiyonel kart.
- **SuperAdmin:** `superadmin_shell` (responsive sidebar), `admin_dashboard_view` (6 metrik kartı + pending/top5), `admin_tenants_view` (tenant CRUD).
- **Web Panel:** `web_admin_portal_screen` (role router), `restaurant_owner_shell` (masa oturumu aç/kapat).

### 3.3 Backend Entegrasyonu
- `backend_api_client.dart`: `AppConfig.apiBaseUrl` + Bearer token; get/post/put/delete JSON; `ApiException`.
- `backend_dtos.dart`: NearbyRestaurant, RestaurantDetail, TokenResponse, QrSessionResponse, MenuItemResponse, OrderItemResponse, OrderResponse, BillResponse, PaymentResultDto, CustomerCardResponse + enum'lar.
- `app_session_store.dart`: flutter_secure_storage (accessToken, refreshToken, userId, kart numarası) + SharedPreferences (restaurantId, tableNo, sessionId, userRole).
- `order_hub_service.dart`: SignalR `/hubs/orders`, `orderCreated`/`orderUpdated` event'lerinde sipariş listesini yeniden çeker.

### 3.4 Konfigürasyon / Demo Modu
`app_config.dart`: `apiBaseUrl` varsayılanı **`https://starr-haustorial-robin.ngrok-free.dev`** (ngrok tüneli — sabit kodlanmış). `useMockFallback = true` → backend erişilemezse `demo_seed.dart` verisi döner (5 restoran, 6 menü ürünü, 2 sipariş, 2 fatura).

---

## 4. Web Paneli (Next.js)

### 4.1 Stack
Next.js 15.1.6 (App Router) + React 19 + TypeScript 5.7 + Tailwind 3.4 + Recharts + `@microsoft/signalr`.

### 4.2 Sayfalar
- `app/page.tsx` — role göre yönlendirme (SuperAdmin→`/superadmin`, Owner/Waiter→`/owner/kitchen`).
- `app/login/page.tsx` — email+şifre auth.
- `(dashboard)/owner/kitchen` — **Canlı mutfak**: 3 kanban sütunu (Bekleyen / Mutfakta-Hazırlanıyor / Hazır), SignalR ile anlık güncelleme, optimistic UI, durum ilerletme butonu.
- `(dashboard)/owner/menu` — **Menü yönetimi**: grid + kategori filtresi, modal CRUD form (malzeme chip input, fiyat kuruş↔TL dönüşümü, stok switch).
- `(dashboard)/owner/tables` — **Masalar**: masa kartları + ödeme progress bar, drawer'da adisyon detayı, oturum kapatma, SignalR canlı bakiye.
- `(dashboard)/superadmin` — **Dashboard**: 4 metrik kartı + gelir grafikleri (⚠️ veriler sahte/hesaplanmış), mekan listesi.
- `(dashboard)/superadmin/management` — **Restoran + Kullanıcı yönetimi**: RestaurantForm (oluştur + owner ata) + UserManagement (CRUD, rol değiştir, şifre sıfırla).

### 4.3 Servis & Auth Katmanı
- `apiClient.ts`: `NEXT_PUBLIC_API_BASE_URL` ?? ngrok fallback; Bearer token provider closure; `ngrok-skip-browser-warning` header.
- `authService.ts`: client-side JWT **decode** (imza doğrulaması yok), role normalizasyonu.
- `AuthContext.tsx`: JWT'yi **localStorage**'da saklar (`appsukran_admin_token`). Refresh token döner ama **kullanılmıyor**.
- `signalrService.ts` + `useOrdersHub`: otomatik reconnect [0,2s,5s,10s], grup join/leave, 6 event tipi dinler.
- `PageContainer` + `navItemsForRole` + `RestaurantGate`: rol bazlı sayfa koruması ve restoran seçimi.

---

## 5. Güçlü Yönler

1. **Temiz, katmanlı mimari** — Backend Clean Architecture + CQRS; mobil ve web feature-based, ayrım net.
2. **Gerçek zamanlı deneyim** — SignalR ile mutfak ↔ müşteri ↔ masa senkronizasyonu, otomatik reconnect.
3. **Sağlam güvenlik temelleri (backend)** — PBKDF2 şifre, kart hash + Luhn, refresh token rotasyonu, optimistic concurrency, rate limiting, audit log.
4. **Çok rollü, çok kiracılı tasarım** — SuperAdmin/Owner/Waiter/Customer ayrımı tutarlı.
5. **Akıllı ödeme bölüştürme** — 3 ayrı strateji, iki fazlı transaction ile tutarlılık.
6. **Coğrafi keşif** — MongoDB 2dsphere + OSRM rota + harita entegrasyonu.
7. **Cilalı UI** — Tutarlı dark tema, glassmorphism (mobil), Tailwind UI kit (web), TL/kuruş format yardımcıları.
8. **Çevrimdışı/demo dayanıklılığı (mobil)** — mock fallback ile backend olmadan da gösterilebilir.

---

## 6. Zayıf Yönler ve Riskler

### 🔴 Kritik
| # | Sorun | Konum | Etki |
|---|-------|-------|------|
| 1 | **Gerçek ödeme gateway'i yok** — bakiye düşüyor ama tahsilat yapılmıyor | Payments handler'ları | Finansal açık / sahtekârlık riski |
| 2 | **JWT localStorage'da + imza doğrulanmıyor (web)** | `AuthContext.tsx`, `authService.ts` | XSS ile token çalınması |
| 3 | **Refresh token üretiliyor ama mobil/web'de kullanılmıyor** | mobil + web | Token bitince sessiz düşme |
| 4 | **Login/register/refresh rate-limit yok** | `AuthController` | Brute-force'a açık |
| 5 | **Sabit kodlu ngrok API URL'i** (mobil + web) | `app_config.dart`, `apiClient.ts` | Tünel kapanınca tüm uygulama çöker; geçici altyapı |
| 6 | **Sabit kodlu secret'lar** (dev signing key + süper admin şifresi config'te) | `appsettings*.json` | Sızıntı riski (env override mevcut ama varsayılan kötü) |

### 🟡 Önemli
- **PaymentsController'da rol bazlı yetki yok** — yalnızca `PaidByUserId == currentUser` kontrolü; rol seviyesinde koruma eksik.
- **N+1 / tüm-tabloyu-belleğe-alma** — login & refresh handler'larında `GetAllAsync` + LINQ filtre (email indeksi kullanılmıyor).
- **Sahte metrikler** — SuperAdmin dashboard gelirleri hesaplanmış/uydurma; backend metrik endpoint'i yok.
- **Sayfalama yok** — orders/bills/users/tenant listeleri limitsiz.
- **OrderItem'da concurrency yok** — iki garson aynı kalemi güncellerse son-yazan-kazanır (veri kaybı).
- **Soft delete yok** — kullanıcı/menü/fatura kalıcı silinir, audit izi kopar.
- **Email format validasyonu yok**; **menü görseli upload yok** (sadece URL).
- **Mock fallback prod'da açık kalırsa** kullanıcı sahte veriyi gerçek sanır.

### 🟠 Kod Kalitesi / Olgunluk
- **Hiç test yok** — backend, mobil, web hiçbirinde unit/integration/e2e test mevcut değil.
- **Şablon/placeholder dosyalar** — `WeatherForecastController`, `WeatherForecast.cs`, iki `Class1.cs`, legacy `Product` entity.
- **Hata izleme/loglama yok** — Sentry/Crashlytics yok; SignalR bağlantı hataları sessizce yutuluyor.
- **i18n yok** — yalnızca Türkçe, sabit metinler.
- **Web'de logout butonu, profil sayfası, kitchen filtre/arama eksik.**

---

## 7. Geliştirme Yol Haritası (Öncelikli)

### Faz 1 — Güvenlik & Üretim Hazırlığı (P0)
1. Gerçek ödeme entegrasyonu: `IPaymentGateway` soyutlaması + Stripe/iyzico/PayPal provider; tahsilat başarısızsa transaction rollback.
2. Token akışını tamamla: refresh token'ı hem mobil hem web'de kullan; 401 interceptor → otomatik yenileme; web'de token'ı HttpOnly cookie'ye taşı.
3. Auth endpoint'lerine rate limiting + email format validasyonu ekle.
4. Tüm secret'ları env değişkeni / secret manager'a taşı; varsayılan dev key'leri kaldır.
5. API URL'ini ortam değişkeninden zorunlu kıl (ngrok'u kalıcı domain ile değiştir).

### Faz 2 — Doğruluk & Ölçeklenebilirlik (P1)
6. PaymentsController + ilgili endpoint'lere rol bazlı `[Authorize(Roles=...)]` ekle.
7. Login/refresh/users sorgularını indeksli filtreli sorgulara çevir (GetAll'ı kaldır).
8. Liste endpoint'lerine sayfalama + cursor; web/mobil tarafında lazy-load.
9. OrderItem güncellemelerine concurrency/version kontrolü.
10. SuperAdmin için gerçek metrik endpoint'leri (ciro/sipariş özetleri).

### Faz 3 — Olgunluk & Kalite (P2)
11. Test altyapısı: backend handler unit testleri + MongoDB/SignalR integration; Flutter widget/repository testleri; web Vitest + Playwright e2e.
12. Hata izleme (Sentry) + yapılandırılmış loglama + sağlık/health endpoint'leri.
13. Soft delete + tam audit kapsamı.
14. Şablon/placeholder dosyaları (`WeatherForecast`, `Class1`, legacy `Product`) temizle.
15. Web'de logout/profil/kitchen-filtre; mobil'de offline cache, JWT yenileme UX'i.
16. i18n (intl) altyapısı, menü görseli upload, dark/light tema toggle.

---

## 8. Eklenebilecek Yeni Özellikler

- **Bildirimler:** Push (FCM) — sipariş hazır, ödeme alındı.
- **Sadakat / kampanya:** puan, kupon, happy hour fiyatlandırması.
- **Garson mobil arayüzü:** şu an sadece veri katmanı var; tam ekran akışı eklenebilir.
- **Raporlama:** owner için günlük/haftalık ciro, en çok satan ürün, masa devir hızı.
- **Stok/envanter yönetimi** ve malzeme bazlı maliyet.
- **Çoklu dil ve para birimi.**
- **Rezervasyon sistemi** (RestaurantTableStatus.Reserved zaten mevcut).
- **Fiş/e-fatura entegrasyonu** (POS köprüsü genişletilebilir).
- **QR menü (oturumsuz)** — sadece menü görüntüleme modu.
- **Mutfak performans metrikleri** — ortalama hazırlık süresi takibi (MenuItem.AveragePreparationTime zaten var).

---

## 9. Hızlı Referans — Dosya Konumları

| Ne | Nerede |
|----|--------|
| API giriş noktası | `backend/src/AppSukran.API/Program.cs` |
| Controller'lar | `backend/src/AppSukran.API/Controllers/` |
| CQRS handler'ları | `backend/src/AppSukran.Application/{Feature}/` |
| Domain entity/enum | `backend/src/AppSukran.Domain/` |
| MongoDB & güvenlik | `backend/src/AppSukran.Infrastructure/` |
| Mobil giriş | `lib/main.dart`, `lib/src/app/` |
| Mobil ekranlar | `lib/src/features/{feature}/presentation/` |
| Mobil API/config | `lib/src/core/network/`, `lib/src/core/config/app_config.dart` |
| Web sayfalar | `web/src/app/` |
| Web bileşenler | `web/src/components/` |
| Web servisler/auth | `web/src/services/`, `web/src/context/AuthContext.tsx` |
