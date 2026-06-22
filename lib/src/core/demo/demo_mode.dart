import 'package:flutter/foundation.dart';

/// Uygulamanın şu anda canlı backend yerine çevrimdışı **demo verisi** sunup
/// sunmadığını izler. Repository'ler bir ağ çağrısı başarısız olup mock
/// fallback döndürdüğünde [markDemoFallback] ile bu bayrağı kaldırır; UI da
/// kullanıcıya "Demo modu" uyarısı gösterir.
final ValueNotifier<bool> demoModeActive = ValueNotifier<bool>(false);

/// Bir repository çevrimdışı demo verisine düştüğünde çağrılır.
void markDemoFallback() {
  if (!demoModeActive.value) {
    demoModeActive.value = true;
  }
}

/// Canlı backend'e tekrar bağlanıldığında (başarılı bir gerçek yanıt) çağrılır.
void clearDemoFallback() {
  if (demoModeActive.value) {
    demoModeActive.value = false;
  }
}
