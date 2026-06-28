import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/demo/demo_seed.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/theme/app_dark.dart';
import '../../session/data/session_repository.dart';

final customerLocationProvider = FutureProvider<Position?>((ref) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    return null;
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
});

final nearbyRestaurantsProvider = FutureProvider<List<NearbyRestaurantDto>>((ref) {
  final position = ref.watch(customerLocationProvider).maybeWhen(data: (value) => value, orElse: () => null);
  return ref.read(sessionRepositoryProvider).fetchNearbyRestaurants(
        longitude: position?.longitude ?? 29.0293,
        latitude: position?.latitude ?? 40.9867,
      );
});

/// Ekran 2.1 — Otomatik QR Oturum Açma ve Konum Doğrulama.
///
/// KRİTİK: Bu ekranda manuel 'Masa No' / 'QR Token' alanı ya da buton
/// **yoktur**. Kamera QR kodu algıladığı an payload arka planda parse edilir,
/// `POST /api/auth/qr-session` tetiklenir ve başarılıysa doğrudan menüye
/// geçilir — hiçbir kullanıcı etkileşimi beklenmez.
class CustomerQrSessionScreen extends ConsumerStatefulWidget {
  const CustomerQrSessionScreen({super.key});

  @override
  ConsumerState<CustomerQrSessionScreen> createState() => _CustomerQrSessionScreenState();
}

class _CustomerQrSessionScreenState extends ConsumerState<CustomerQrSessionScreen> {
  // Kamera ekran açılır açılmaz başlamaz; kullanıcı "QR Okut"a basınca başlar.
  final MobileScannerController _scannerController = MobileScannerController(autoStart: false);

  /// Kamera alanı aktif mi? Başlangıçta kapalı — önce "QR Okut" gösterilir.
  bool _scannerActive = false;

  /// Tek seferlik tetikleme kilidi — kamera aynı kodu defalarca okusa da
  /// oturum yalnızca bir kez açılır.
  bool _handled = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// "QR Okut" butonuna basıldığında kamerayı başlatır.
  Future<void> _activateScanner() async {
    if (_scannerActive) return;
    setState(() => _scannerActive = true);
    try {
      await _scannerController.start();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera başlatılamadı: $error')),
        );
        setState(() => _scannerActive = false);
      }
    }
  }

  /// Kamerayı kapatıp tekrar bekleme (idle) durumuna döner.
  Future<void> _deactivateScanner() async {
    unawaited(_scannerController.stop());
    if (mounted) setState(() => _scannerActive = false);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        raw = value.trim();
        break;
      }
    }
    if (raw == null) return;

    _handled = true; // lock immediately to avoid duplicate POSTs
    setState(() => _isSubmitting = true);
    unawaited(_scannerController.stop());

    final payload = _parseQrPayload(raw);
    try {
      await ref.read(sessionRepositoryProvider).createQrSession(
            restaurantId: payload.restaurantId,
            tableNo: payload.tableNo,
            qrToken: payload.qrToken,
          );
      if (!mounted) return;
      GoRouter.of(context).go('/customer/menu');
    } catch (error) {
      // Allow another attempt if the session call fails.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oturum açılamadı: $error')),
        );
        setState(() => _isSubmitting = false);
        _handled = false;
        unawaited(_scannerController.start());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(customerLocationProvider);
    final nearbyRestaurants = ref.watch(nearbyRestaurantsProvider);
    final nearbyData = nearbyRestaurants.maybeWhen(data: (value) => value, orElse: () => const <NearbyRestaurantDto>[]);
    final nearestDistance = nearbyData.isNotEmpty ? nearbyData.first.distanceMeters : 3.0;
    final position = locationAsync.maybeWhen(data: (value) => value, orElse: () => null);

    return Scaffold(
      body: AppDark.scaffoldBackground(
        child: SafeArea(
          child: Padding(
            padding: AppDark.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR Giriş ve Konum Doğrulama',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _scannerActive
                      ? 'QR kodu çerçeveye hizalayın, oturum otomatik açılır.'
                      : 'Hazır olduğunuzda "QR Okut" ile kamerayı açın.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: _ScannerView(
                      controller: _scannerController,
                      isActive: _scannerActive,
                      isSubmitting: _isSubmitting,
                      onDetect: _onDetect,
                      onActivate: _activateScanner,
                      onClose: _deactivateScanner,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _LocationCard(
                  latitude: position?.latitude ?? 40.9867,
                  longitude: position?.longitude ?? 29.0293,
                  distanceMeters: nearestDistance,
                  targetMeters: 20,
                  isResolving: locationAsync.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerView extends StatelessWidget {
  const _ScannerView({
    required this.controller,
    required this.isActive,
    required this.isSubmitting,
    required this.onDetect,
    required this.onActivate,
    required this.onClose,
  });

  final MobileScannerController controller;
  final bool isActive;
  final bool isSubmitting;
  final Future<void> Function(BarcodeCapture capture) onDetect;
  final Future<void> Function() onActivate;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: isActive
            ? _buildCamera(context)
            : _IdleScanPanel(onActivate: onActivate),
      ),
    );
  }

  Widget _buildCamera(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.black, child: MobileScanner(controller: controller, onDetect: onDetect)),
        // Subtle vignette so the gold reticle reads on any camera feed.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Colors.transparent, Color(0x99000000)],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        const IgnorePointer(child: Center(child: _PulsingReticle())),
        Positioned(
          right: 12,
          top: 12,
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Kamerayı kapat',
              onPressed: isSubmitting ? null : onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: IgnorePointer(
            child: Center(
              child: Text(
                isSubmitting ? 'Oturum açılıyor…' : 'QR kodu çerçeveye hizalayın',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
        if (isSubmitting)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppDark.accentBright),
            ),
          ),
      ],
    );
  }
}

/// Kamera kapalıyken gösterilen bekleme paneli. Kullanıcı buradaki
/// "QR Okut" butonuna basana kadar kamera açılmaz.
class _IdleScanPanel extends StatelessWidget {
  const _IdleScanPanel({required this.onActivate});

  final Future<void> Function() onActivate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppDark.surface,
        border: Border.all(color: AppDark.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppDark.accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: AppDark.accent.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppDark.accentBright, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              'Kamera kapalı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppDark.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gizliliğiniz için kamera siz başlatana kadar açılmaz.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
            ),
            const SizedBox(height: 22),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppDark.accentGradient,
                borderRadius: BorderRadius.circular(AppDark.radiusControl),
                boxShadow: [
                  BoxShadow(color: AppDark.accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: FilledButton.icon(
                onPressed: onActivate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFF000000),
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: const Text('QR Okut', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İnce altın sarısı hatlara sahip, yanıp sönen (pulsing) QR hedefleme çerçevesi.
class _PulsingReticle extends StatefulWidget {
  const _PulsingReticle();

  @override
  State<_PulsingReticle> createState() => _PulsingReticleState();
}

class _PulsingReticleState extends State<_PulsingReticle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            painter: _ReticlePainter(
              progress: t,
              cornerColor: AppDark.accentBright,
              glowColor: AppDark.accent.withValues(alpha: 0.25 + 0.35 * t),
            ),
          ),
        );
      },
    );
  }
}

class _ReticlePainter extends CustomPainter {
  _ReticlePainter({required this.progress, required this.cornerColor, required this.glowColor});

  final double progress;
  final Color cornerColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double arm = 34;
    const double r = 18;
    final rect = Offset.zero & size;

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final linePaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void corner(Offset p, double dx, double dy) {
      final path = Path()
        ..moveTo(p.dx, p.dy + dy * (arm))
        ..lineTo(p.dx, p.dy + dy * r)
        ..arcToPoint(Offset(p.dx + dx * r, p.dy), radius: const Radius.circular(r), clockwise: dx * dy < 0)
        ..lineTo(p.dx + dx * arm, p.dy);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }

    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);
    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);

    // Scanning sweep line.
    final y = size.height * (0.18 + 0.64 * progress);
    final sweep = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, cornerColor.withValues(alpha: 0.9), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.12, y), Offset(size.width * 0.88, y), sweep);
  }

  @override
  bool shouldRepaint(_ReticlePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.glowColor != glowColor;
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.targetMeters,
    required this.isResolving,
  });

  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double targetMeters;
  final bool isResolving;

  @override
  Widget build(BuildContext context) {
    final ratio = (distanceMeters / targetMeters).clamp(0.0, 1.0);
    final withinRange = distanceMeters <= targetMeters;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDark.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppDark.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppDark.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Konum Doğrulama',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppDark.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (isResolving)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(
                  withinRange ? Icons.verified_rounded : Icons.my_location_rounded,
                  color: withinRange ? AppDark.success : AppDark.textSecondary,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Lat: ${latitude.toStringAsFixed(4)}  |  Lon: ${longitude.toStringAsFixed(4)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppDark.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation(AppDark.accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${distanceMeters.toStringAsFixed(0)} m / ${targetMeters.toStringAsFixed(0)} m',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppDark.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                withinRange ? 'Menzilde' : 'Yaklaşın',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: withinRange ? AppDark.success : AppDark.accentBright,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrSessionPayload {
  const _QrSessionPayload({required this.restaurantId, required this.tableNo, required this.qrToken});

  final String restaurantId;
  final int tableNo;
  final String qrToken;
}

/// QR dizesini parse eder. JSON ({restaurantId, tableNo, qrToken}) veya düz
/// token formatını destekler; eksik alanlar demo değerleriyle tamamlanır.
_QrSessionPayload _parseQrPayload(String rawValue) {
  final trimmed = rawValue.trim();

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      final restaurantId = decoded['restaurantId']?.toString();
      final qrToken = decoded['qrToken']?.toString();
      return _QrSessionPayload(
        restaurantId: (restaurantId != null && restaurantId.isNotEmpty) ? restaurantId : DemoSeed.restaurantId,
        tableNo: int.tryParse(decoded['tableNo']?.toString() ?? '') ?? 8,
        qrToken: (qrToken != null && qrToken.isNotEmpty) ? qrToken : trimmed,
      );
    }
  } catch (_) {
    // Fall through to plain-token handling.
  }

  return _QrSessionPayload(restaurantId: DemoSeed.restaurantId, tableNo: 8, qrToken: trimmed);
}
