# AppSukran Backend Detayli Dokumani

Bu dokuman, backend kodunu inceleyerek hazirlanmistir ve iki amaca odaklanir:
- Projenin ne oldugunu ve nasil kurgulandigini aciklamak
- Tum endpointleri ve endpointlerin ne istedigini (path/query/body, yetki, temel kurallar) listelemek

## 1) Proje Nedir?

AppSukran backend, restoran masasi/siparis/hesap odakli bir API katmanidir. Sistem; QR oturumu, kullanici kimlik dogrulama (JWT + refresh token), siparis yonetimi, hesap (bill) yonetimi, parcali odeme ve restoran/menu yonetimi senaryolarini kapsar.

### Temel teknik yapi
- Mimari: Katmanli yapi (API, Application, Domain, Infrastructure)
- API: ASP.NET Core Web API + Controller tabanli
- Is kurallari ve use-case: MediatR Command/Query yapisi
- Validation: FluentValidation pipeline
- Veri katmani: MongoDB (MongoClient + generic repository + unit of work)
- Kimlik dogrulama: JWT Bearer
- Yetkilendirme:
  - Rol bazli (`SuperAdmin`, `RestaurantOwner`, vb.)
  - Politika bazli (`SuperAdminOnly`)
- Gercek zamanli iletisim: SignalR (`/hubs/orders`)
- Koruma:
  - CORS policy (development ortaminda genis, productionda kisitli)
  - Rate limiting (orders-write, payments-write)

### Dikkat edilmesi gereken genel noktalar
- JWT signing key, ortama gore `JWT_SIGNING_KEY` env var ile override edilebiliyor.
- Refresh token server tarafinda `appsukran_refresh` adli HttpOnly cookie ile de yonetiliyor.
- Enum alanlari yanitlarda **sayisal (int)** doner. Istek gonderirken hem sayisal (`1`) hem string (`"Pending"`) deger kabul edilir (System.Text.Json varsayilani). Istemciler (Flutter + web) enum yanitlarini sayisal okur; sayisal gondermek en guvenlisidir.

## 2) Ortak Kurallar

### Base URL ve route kalibi
- Controller route kalibi genelde: `api/[controller]`
- Ornek: `AuthController` => `api/auth`

### Auth tipleri
- Acik endpointler: `AuthController`, bazi restoran/menu/public GET endpointleri
- JWT zorunlu endpointler: `Orders`, `Bills`, `Payments`, `Users`
- Rol kisiti olan endpointler:
  - `Users`: SuperAdmin policy
  - `Restaurants` POST: SuperAdmin
  - `MenuItems` POST/PUT/DELETE: RestaurantOwner
  - `RestaurantTables`: SuperAdmin veya RestaurantOwner

### Rate limit
- `OrdersController` ve `BillsController`: `orders-write`
  - Dakikada 30 istek, kuyruk 10
- `PaymentsController`: `payments-write`
  - Dakikada 20 istek, kuyruk 10

## 3) Enum Degerleri (isteklerde kullanilan)

### UserRole
- 1: SuperAdmin
- 2: RestaurantOwner
- 4: Customer

### OrderSessionStatus
- 1: Active
- 2: Closed

### OrderItemStatus
- 1: Pending
- 2: Kitchen
- 3: Preparing
- 4: Ready
- 5: Delivered

### PaymentStatus
- 1: Unpaid
- 2: Processing
- 3: Paid

## 4) Endpoint Listesi ve Istedikleri

Asagida her endpoint icin su format kullanilir:
- Route
- Method
- Yetki
- Path/Query parametreleri
- Body (istenen alanlar)
- Temel validasyon kurallari
- Beklenen sonuc tipi (genel)

---

## 4.1 Auth (`/api/auth`)

### 1. QR Session olustur
- Route: `/api/auth/qr-session`
- Method: `POST`
- Yetki: Acik
- Body:
  - `restaurantId` (string)
  - `tableNo` (int)
  - `qrToken` (string)
- Validasyon:
  - `restaurantId` bos olamaz
  - `tableNo` > 0
  - `qrToken` bos olamaz
- Donus:
  - `QrSessionResponse`:
    - `accessToken`
    - `expiresAt`
    - `restaurantId`
    - `tableNo`
    - `tableSessionId`

### 2. Kayit ol
- Route: `/api/auth/register`
- Method: `POST`
- Yetki: Acik
- Body:
  - `name` (string)
  - `email` (string)
  - `password` (string)
  - `role` (UserRole)
  - `restaurantId` (string, opsiyonel ama role'e gore zorunlu)
- Validasyon:
  - `name`: bos olamaz, max 150
  - `email`: bos olamaz, email format, max 250
  - `password`: bos olamaz, min 8 max 200
  - `role`: SuperAdmin olamaz
    - `role` RestaurantOwner ise `restaurantId` zorunlu
- Donus:
  - `TokenResponse` (`accessToken`, `refreshToken`, `refreshTokenExpiresAt`)
  - Ayrica HttpOnly refresh cookie set edilir (`appsukran_refresh`)

### 3. Giris yap
- Route: `/api/auth/login`
- Method: `POST`
- Yetki: Acik
- Body:
  - `email` (string)
  - `password` (string)
- Validasyon:
  - `email`: bos olamaz, email format
  - `password`: bos olamaz
- Donus:
  - `TokenResponse`
  - HttpOnly refresh cookie set edilir

### 4. Token yenile
- Route: `/api/auth/refresh`
- Method: `POST`
- Yetki: Acik
- Body:
  - `refreshToken` (string, bos gelirse cookie'den okunmaya calisilir)
- Validasyon:
  - refresh token bos olamaz
- Donus:
  - `TokenResponse`
  - refresh cookie rotate edilir

### 5. Cikis yap
- Route: `/api/auth/logout`
- Method: `POST`
- Yetki: Acik
- Body:
  - `refreshToken` (opsiyonel, yoksa cookie'den okunur)
- Islem:
  - Token varsa revoke komutu cagrilir
  - `appsukran_refresh` cookie temizlenir
- Donus:
  - `204 No Content`

---

## 4.2 Users (`/api/users`)

Not: Tum endpointler `SuperAdminOnly` policy ister.

### 1. Kullanicinin rolunu guncelle
- Route: `/api/users/{userId}/role`
- Method: `PUT`
- Yetki: SuperAdminOnly
- Path:
  - `userId` (string)
- Body:
  - `role` (UserRole)
  - `restaurantId` (string, role'e gore gerekli)
- Validasyon:
  - `userId` bos olamaz
  - `role` enum icinde olmali
    - `role` RestaurantOwner ise `restaurantId` zorunlu
- Donus:
  - `204 No Content`

### 2. Kullanici sifresini resetle
- Route: `/api/users/{userId}/reset-password`
- Method: `PUT`
- Yetki: SuperAdminOnly
- Path:
  - `userId` (string)
- Body:
  - `newPassword` (string)
- Validasyon:
  - `userId` bos olamaz
  - `newPassword` bos olamaz, min 8 max 200
- Donus:
  - `204 No Content`

---

## 4.3 Restaurants (`/api/restaurants`)

### 1. Yakindaki restoranlari getir
- Route: `/api/restaurants/nearby`
- Method: `GET`
- Yetki: Acik
- Query:
  - `longitude` (double)
  - `latitude` (double)
  - `maxDistanceMeters` (int, varsayilan 5000)
- Donus:
  - `NearbyRestaurantDto[]`:
    - `id`, `slug`, `name`, `address`, `longitude`, `latitude`, `distanceMeters`

### 2. ID ile restoran detayi
- Route: `/api/restaurants/{restaurantId}`
- Method: `GET`
- Yetki: Acik
- Path:
  - `restaurantId` (string)
- Donus:
  - `RestaurantDetailResponse` veya `404`

### 3. Slug ile restoran detayi
- Route: `/api/restaurants/by-slug/{slug}`
- Method: `GET`
- Yetki: Acik
- Path:
  - `slug` (string)
- Donus:
  - `RestaurantDetailResponse` veya `404`

### 4. Masa session dogrulama
- Route: `/api/restaurants/{restaurantId}/tables/{tableNo}/session`
- Method: `GET`
- Yetki: Acik
- Path:
  - `restaurantId` (string)
  - `tableNo` (int)
- Query:
  - `token` (string)
- Donus:
  - `RestaurantTableSessionDto` veya `404`

### 5. Restoran olustur
- Route: `/api/restaurants`
- Method: `POST`
- Yetki: Sadece SuperAdmin
- Body:
  - `name` (string)
  - `slug` (string)
  - `ownerId` (string)
  - `longitude` (double)
  - `latitude` (double)
  - `address` (string)
- Donus:
  - `{ restaurantId: string }`

---

## 4.4 Restaurant Tables (`/api/restaurants/{restaurantId}/tables`)

Not: Tum endpointler `SuperAdmin,RestaurantOwner` rollerini ister.

### 1. Masa session ac
- Route: `/api/restaurants/{restaurantId}/tables/{tableNo}/session/open`
- Method: `POST`
- Yetki: SuperAdmin veya RestaurantOwner
- Path:
  - `restaurantId` (string)
  - `tableNo` (int)
- Body: Yok
- Donus:
  - `RestaurantTableSessionDto`

### 2. Masa session kapat
- Route: `/api/restaurants/{restaurantId}/tables/{tableNo}/session/close`
- Method: `POST`
- Yetki: SuperAdmin veya RestaurantOwner
- Path:
  - `restaurantId` (string)
  - `tableNo` (int)
- Body: Yok
- Donus:
  - `RestaurantTableSessionDto`

---

## 4.5 Menu Items (`/api/menuitems`)

### 1. Menu item getir (ID)
- Route: `/api/menuitems/{menuItemId}`
- Method: `GET`
- Yetki: Acik
- Path:
  - `menuItemId` (string)
- Donus:
  - `MenuItemResponse` veya null

### 2. Restorana ait menu itemler
- Route: `/api/menuitems/restaurant/{restaurantId}`
- Method: `GET`
- Yetki: Acik
- Path:
  - `restaurantId` (string)
- Donus:
  - `MenuItemResponse[]`

### 3. Menu item olustur
- Route: `/api/menuitems`
- Method: `POST`
- Yetki: RestaurantOwner
- Body:
  - `restaurantId` (string)
  - `category` (string)
  - `name` (string)
  - `imageUrl` (string)
  - `ingredients` (string[])
  - `recipe` (string, nullable)
  - `averagePreparationTime` (int)
  - `price` (long)
  - `isAvailable` (bool)
- Validasyon:
  - `restaurantId` bos olamaz
  - `category` bos olamaz, max 100
  - `name` bos olamaz, max 200
  - `imageUrl` bos olamaz, max 500
  - `averagePreparationTime` >= 0
  - `price` >= 0
- Donus:
  - Olusan kaydin id'si (string)

### 4. Menu item guncelle
- Route: `/api/menuitems/{menuItemId}`
- Method: `PUT`
- Yetki: RestaurantOwner
- Path:
  - `menuItemId` (string)
- Body:
  - `category` (string)
  - `name` (string)
  - `imageUrl` (string)
  - `ingredients` (string[])
  - `recipe` (string, nullable)
  - `averagePreparationTime` (int)
  - `price` (long)
  - `isAvailable` (bool)
- Validasyon:
  - `menuItemId` bos olamaz
  - `category` bos olamaz, max 100
  - `name` bos olamaz, max 200
  - `imageUrl` bos olamaz, max 500
  - `averagePreparationTime` >= 0
  - `price` >= 0
- Donus:
  - `204 No Content`

### 5. Menu item sil
- Route: `/api/menuitems/{menuItemId}`
- Method: `DELETE`
- Yetki: RestaurantOwner
- Path:
  - `menuItemId` (string)
- Donus:
  - `204 No Content`

---

## 4.6 Orders (`/api/orders`)

Not: Controller seviyesinde JWT zorunlu + `orders-write` rate limit.

### 1. Siparis getir (ID)
- Route: `/api/orders/{orderId}`
- Method: `GET`
- Yetki: JWT
- Path:
  - `orderId` (string)
- Donus:
  - `OrderResponse` veya null

### 2. Restorana ait siparisler
- Route: `/api/orders/restaurant/{restaurantId}`
- Method: `GET`
- Yetki: JWT
- Path:
  - `restaurantId` (string)
- Donus:
  - `OrderResponse[]`

### 3. Siparis olustur
- Route: `/api/orders`
- Method: `POST`
- Yetki: JWT
- Body:
  - `restaurantId` (string)
  - `tableNo` (int)
  - `tableSessionId` (string)
  - `qrToken` (string)
  - `items` (array)
    - her item:
      - `menuItemId` (string)
      - `name` (string)
      - `price` (long)
      - `orderedBy` (string)
      - `status` (OrderItemStatus)
      - `paymentStatus` (PaymentStatus)
- Validasyon:
  - `restaurantId` bos olamaz
  - `tableNo` > 0
  - `tableSessionId` bos olamaz
  - `qrToken` bos olamaz
  - `items` bos/null olamaz, en az 1 item olmali
- Donus:
  - Olusan siparis id'si (string)

### 4. Siparis session status guncelle
- Route: `/api/orders/{orderId}/status`
- Method: `PUT`
- Yetki: JWT
- Path:
  - `orderId` (string)
- Body:
  - `sessionStatus` (OrderSessionStatus)
- Donus:
  - `204 No Content`

### 5. Siparis sil
- Route: `/api/orders/{orderId}`
- Method: `DELETE`
- Yetki: JWT
- Path:
  - `orderId` (string)
- Donus:
  - `204 No Content`

### 6. Siparis item status guncelle
- Route: `/api/orders/{orderId}/items/{orderItemId}/status`
- Method: `PUT`
- Yetki: JWT
- Path:
  - `orderId` (string)
  - `orderItemId` (string)
- Body:
  - `status` (OrderItemStatus)
- Donus:
  - `204 No Content`

---

## 4.7 Bills (`/api/bills`)

Not: Controller seviyesinde JWT zorunlu + `orders-write` rate limit.

### 1. Hesap getir (ID)
- Route: `/api/bills/{billId}`
- Method: `GET`
- Yetki: JWT
- Path:
  - `billId` (string)
- Donus:
  - `BillResponse` veya null

### 2. Restorana ait hesaplar
- Route: `/api/bills/restaurant/{restaurantId}`
- Method: `GET`
- Yetki: JWT
- Path:
  - `restaurantId` (string)
- Donus:
  - `BillResponse[]`

### 3. Hesap olustur
- Route: `/api/bills`
- Method: `POST`
- Yetki: JWT
- Body:
  - `restaurantId` (string)
  - `tableNo` (int)
  - `tableSessionId` (string)
  - `qrToken` (string)
  - `items` (array)
    - her item:
      - `menuItemId` (string)
      - `name` (string)
      - `price` (long)
      - `orderedBy` (string)
      - `status` (OrderItemStatus)
      - `paymentStatus` (PaymentStatus)
- Validasyon:
  - `restaurantId` bos olamaz
  - `tableNo` > 0
  - `tableSessionId` bos olamaz
  - `qrToken` bos olamaz
  - `items` bos/null olamaz, en az 1 item olmali
- Donus:
  - Olusan bill id'si (string)

### 4. Hesap guncelle
- Route: `/api/bills/{billId}`
- Method: `PUT`
- Yetki: JWT
- Path:
  - `billId` (string)
- Body:
  - `sessionStatus` (OrderSessionStatus)
  - `remainingAmount` (long)
- Donus:
  - `204 No Content`

### 5. Hesap sil
- Route: `/api/bills/{billId}`
- Method: `DELETE`
- Yetki: JWT
- Path:
  - `billId` (string)
- Donus:
  - `204 No Content`

### 6. Bill item status guncelle
- Route: `/api/bills/{billId}/items/{orderItemId}/status`
- Method: `PUT`
- Yetki: JWT
- Path:
  - `billId` (string)
  - `orderItemId` (string)
- Body:
  - `status` (OrderItemStatus)
- Donus:
  - `204 No Content`

---

## 4.8 Customer Cards (`/api/customercards`)

Not: Controller seviyesinde JWT zorunlu + müşteri rolü gerekir.

### 1. Kendi kartlarini getir
- Route: `/api/customercards/me`
- Method: `GET`
- Yetki: Customer
- Donus:
  - `CustomerCardResponse[]`

### 2. Kart ekle
- Route: `/api/customercards`
- Method: `POST`
- Yetki: Customer
- Body:
  - `cardholderName` (string)
  - `cardNumber` (string)
  - `expiryMonth` (int)
  - `expiryYear` (int)
  - `cvv` (string)
  - `isDefault` (bool, opsiyonel)
- Validasyon:
  - `cardholderName` bos olamaz
  - `cardNumber` bos olamaz, Luhn dogrulamasi gecerli olmali
  - `expiryMonth` 1..12 olmalı
  - `expiryYear` mevcut/past olmayan yil olmali
  - `cvv` bos olamaz, 3-4 hane olmali
- Donus:
  - `CustomerCardResponse`

### 3. Kart dogrula
- Route: `/api/customercards/verify`
- Method: `POST`
- Yetki: Customer
- Body:
  - `customerCardId` (string)
  - `cardNumber` (string)
- Donus:
  - `CustomerCardVerificationResponse`

### 4. Kart sil
- Route: `/api/customercards/{customerCardId}`
- Method: `DELETE`
- Yetki: Customer
- Path:
  - `customerCardId` (string)
- Donus:
  - `204 No Content`

---

## 4.9 Payments (`/api/payments`)

Not: Controller seviyesinde JWT zorunlu + `payments-write` rate limit.

### 1. Secili urunleri ode
- Route: `/api/payments/specific-items`
- Method: `POST`
- Yetki: JWT
- Body:
  - `billId` (string)
  - `itemIds` (string[])
  - `paidByUserId` (string)
  - `customerCardId` (string, opsiyonel)
  - `cardNumber` (string, opsiyonel; cardId verildiğinde gerekli)
- Validasyon:
  - `billId` bos olamaz
  - `paidByUserId` bos olamaz
  - `itemIds` bos/null olamaz, en az 1 oge olmali
- Donus:
  - Komut sonucu `200 OK` ile doner

### 2. Hesabi esit bol
- Route: `/api/payments/split-equally`
- Method: `POST`
- Yetki: JWT
- Body:
  - `billId` (string)
  - `personCount` (int)
  - `paidByUserId` (string)
  - `customerCardId` (string, opsiyonel)
  - `cardNumber` (string, opsiyonel; cardId verildiğinde gerekli)
- Validasyon:
  - `billId` bos olamaz
  - `paidByUserId` bos olamaz
  - `personCount` > 0 ve <= 100
- Donus:
  - Komut sonucu `200 OK` ile doner

### 3. Ozel tutar ode
- Route: `/api/payments/custom-amount`
- Method: `POST`
- Yetki: JWT
- Body:
  - `billId` (string)
  - `amount` (long)
  - `paidByUserId` (string)
  - `customerCardId` (string, opsiyonel)
  - `cardNumber` (string, opsiyonel; cardId verildiğinde gerekli)
- Validasyon:
  - `billId` bos olamaz
  - `paidByUserId` bos olamaz
  - `amount` > 0
- Donus:
  - Komut sonucu `200 OK` ile doner

---

## 4.10 Products (`/api/products`)

### 1. Tum urunleri getir
- Route: `/api/products`
- Method: `GET`
- Yetki: Acik
- Body: Yok
- Donus:
  - Product listesi

### 2. Urun getir (ID)
- Route: `/api/products/{id}`
- Method: `GET`
- Yetki: Acik
- Path:
  - `id` (int)
- Donus:
  - Product veya `404`

### 3. Urun olustur
- Route: `/api/products`
- Method: `POST`
- Yetki: Acik
- Body:
  - `name` (string)
  - `price` (decimal)
- Controller seviyesinde ek kontrol:
  - `name` bos olamaz
  - `price` > 0 olmali
- Donus:
  - `201 Created`

---

## 4.10 WeatherForecast (`/weatherforecast`)

Bu endpoint standart ASP.NET template endpointidir.

### 1. Hava tahmini
- Route: `/weatherforecast`
- Method: `GET`
- Yetki: Acik
- Donus:
  - Ornek hava tahmini listesi

---

## 5) Realtime Endpoint

### SignalR Hub
- Route: `/hubs/orders`
- Hub methodlari:
  - `JoinRestaurantGroup(restaurantId)`
  - `LeaveRestaurantGroup(restaurantId)`

Bu kanal, restoran bazli gercek zamanli siparis olaylari icin kullanilmaya uygun sekilde kurgulanmis.

## 6) Kisa Sonuc

Bu backend; restoran operasyonunu uc ana eksende yoneten bir API'dir:
- Kimlik + session (Auth, Users)
- Operasyon (Restaurant, Menu, Order, Bill)
- Tahsilat (Payments)

Dokuman endpoint seviyesinde hangi alanlarin zorunlu oldugunu ve hangi kosullarda calistigini netlestirir; frontend/mobil ekipleri dogrudan bu dosyayi kontrat referansi olarak kullanabilir.
