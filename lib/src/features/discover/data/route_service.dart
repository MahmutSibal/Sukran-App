import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

final routeServiceProvider = Provider<RouteService>((ref) => RouteService());

/// Hesaplanan rotanın sonucu — harita üzerinde çizilecek noktalar ve özet.
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isFallback,
  });

  /// Rota çizgisini oluşturan koordinatlar (başlangıç → hedef).
  final List<LatLng> points;

  /// Toplam yol mesafesi (metre).
  final double distanceMeters;

  /// Tahmini sürüş süresi (saniye).
  final double durationSeconds;

  /// Gerçek yol verisi alınamadı, düz çizgiye düşüldü mü?
  final bool isFallback;

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.toStringAsFixed(0)} m';
  }

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 1) return '<1 dk';
    if (minutes < 60) return '$minutes dk';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '$hours sa' : '$hours sa $rem dk';
  }
}

/// OSRM açık yönlendirme servisini kullanarak iki nokta arası sürüş rotası
/// üretir. Servise ulaşılamazsa düz çizgi (geodesic) ile geri düşer.
class RouteService {
  RouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _distance = Distance();

  Future<RouteResult> fetchDrivingRoute({required LatLng from, required LatLng to}) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = body['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coords = (geometry['coordinates'] as List<dynamic>)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList(growable: false);
          if (coords.isNotEmpty) {
            return RouteResult(
              points: coords,
              distanceMeters: (route['distance'] as num?)?.toDouble() ?? _distance(from, to),
              durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
              isFallback: false,
            );
          }
        }
      }
    } catch (_) {
      // Ağ/servis hatası — düz çizgiye düş.
    }

    return _straightLineFallback(from, to);
  }

  RouteResult _straightLineFallback(LatLng from, LatLng to) {
    final meters = _distance(from, to);
    return RouteResult(
      points: [from, to],
      distanceMeters: meters,
      // Kaba tahmin: ortalama 30 km/sa şehir içi sürüş.
      durationSeconds: meters / (30000 / 3600),
      isFallback: true,
    );
  }

  /// Harici harita uygulaması (Google Haritalar) için yol tarifi bağlantısı.
  Uri externalDirectionsUri({required LatLng to, LatLng? from, String? label}) {
    final origin = from == null ? '' : '&origin=${from.latitude},${from.longitude}';
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '$origin'
      '&destination=${to.latitude},${to.longitude}'
      '&travelmode=driving',
    );
  }
}
