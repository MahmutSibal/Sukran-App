import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../config/app_config.dart';
import '../storage/app_session_store.dart';

class OrderHubService {
  OrderHubService({required AppSessionStore sessionStore}) : _sessionStore = sessionStore;

  final AppSessionStore _sessionStore;
  final Map<String, HubConnection> _connections = {};
  final Map<String, StreamController<void>> _controllers = {};

  Stream<void> watchRestaurant(String restaurantId) {
    return _controllerFor(restaurantId).stream;
  }

  /// Restoran hub'ına bağlanmayı dener. Başarılıysa `true`, bağlantı/grup
  /// katılımı başarısızsa `false` döner — **istisna fırlatmaz**, böylece çağıran
  /// akış (sipariş izleme) çökmek yerine polling'e düşebilir.
  Future<bool> connect(String restaurantId, {String? accessToken}) async {
    if (_connections.containsKey(restaurantId)) {
      return true;
    }

    final token = accessToken ?? await _sessionStore.readAccessToken();
    final connection = HubConnectionBuilder()
        .withUrl(
          '${AppConfig.apiBaseUrl}/hubs/orders',
          options: HttpConnectionOptions(accessTokenFactory: () async => token ?? ''),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('orderCreated', (List<Object?>? arguments) => _controllerFor(restaurantId).add(null));
    connection.on('orderUpdated', (List<Object?>? arguments) => _controllerFor(restaurantId).add(null));

    // Yeniden bağlanınca grubu tekrar joinle ve bir kez yenileme tetikle —
    // aksi halde reconnect sonrası kaçırılan event'ler kalıcı olarak kaybolur.
    connection.onreconnected(({String? connectionId}) {
      connection.invoke('JoinRestaurantGroup', args: [restaurantId]).catchError((_) => null);
      _controllerFor(restaurantId).add(null);
    });

    try {
      await connection.start();
      await connection.invoke('JoinRestaurantGroup', args: [restaurantId]);
      _connections[restaurantId] = connection;
      return true;
    } catch (_) {
      // Yarıda kalan bağlantıyı temizle ki sonraki çağrı yeniden deneyebilsin.
      try {
        await connection.stop();
      } catch (_) {
        // yoksay
      }
      return false;
    }
  }

  Future<void> disconnect(String restaurantId) async {
    final connection = _connections.remove(restaurantId);
    await connection?.stop();
  }

  Future<void> dispose() async {
    for (final connection in _connections.values) {
      await connection.stop();
    }
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _connections.clear();
    _controllers.clear();
  }

  StreamController<void> _controllerFor(String restaurantId) {
    return _controllers.putIfAbsent(restaurantId, () => StreamController<void>.broadcast());
  }
}
