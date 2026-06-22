import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_dark.dart';

/// Yorum için zorunlu fotoğraf çekim ekranı.
///
/// Canlı kamera önizlemesinde ve çekilen fotoğrafta filigran gösterilir:
/// - Sol üst: uygulama adı (Şükran)
/// - Sol alt: restoran adı
/// - Sağ alt: kullanıcı adı soyadı
///
/// "Kullan" denildiğinde filigran fotoğrafa gömülür ve oluşturulan dosya
/// [Navigator.pop] ile geri döndürülür.
class WatermarkCameraScreen extends StatefulWidget {
  const WatermarkCameraScreen({
    required this.restaurantName,
    required this.userName,
    super.key,
  });

  final String restaurantName;
  final String userName;

  static const String appName = 'Şükran';

  @override
  State<WatermarkCameraScreen> createState() => _WatermarkCameraScreenState();
}

class _WatermarkCameraScreenState extends State<WatermarkCameraScreen> {
  CameraController? _controller;
  final GlobalKey _stillKey = GlobalKey();

  String? _error;
  bool _capturing = false;
  bool _saving = false;
  XFile? _shot; // çekilen ham fotoğraf

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Cihazda kamera bulunamadı.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      if (mounted) setState(() => _error = 'Kamera açılamadı: $error');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (mounted) setState(() => _shot = file);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fotoğraf çekilemedi: $error')));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// Filigranı çekilen fotoğrafa gömer ve geçici PNG dosyasını döndürür.
  Future<void> _useShot() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Bir kare bekleyip RepaintBoundary'nin tamamen yerleştiğinden emin ol.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final boundary = _stillKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Önizleme hazır değil.');
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('Görsel oluşturulamadı.');

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/sukran_review_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) Navigator.of(context).pop(file);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İşlenemedi: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_shot == null ? 'Mekanın fotoğrafını çek' : 'Önizleme'),
      ),
      body: _error != null
          ? _ErrorView(message: _error!)
          : _shot == null
              ? _buildLivePreview()
              : _buildStillPreview(),
    );
  }

  Widget _buildLivePreview() {
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1 / controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  _WatermarkOverlay(
                    restaurantName: widget.restaurantName,
                    userName: widget.userName,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: GestureDetector(
              onTap: _capturing ? null : _capture,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppDark.accent, width: 4),
                ),
                child: _capturing
                    ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A1206), size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStillPreview() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: RepaintBoundary(
              key: _stillKey,
              child: Stack(
                children: [
                  Image.file(File(_shot!.path), fit: BoxFit.contain),
                  Positioned.fill(
                    child: _WatermarkOverlay(
                      restaurantName: widget.restaurantName,
                      userName: widget.userName,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => setState(() => _shot = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Çek'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _useShot,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppDark.accent,
                    foregroundColor: const Color(0xFF1A1206),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1206)))
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'İşleniyor...' : 'Kullan'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Üç köşeye yerleşen filigran katmanı (canlı önizleme ve çekilen kare için ortak).
class _WatermarkOverlay extends StatelessWidget {
  const _WatermarkOverlay({required this.restaurantName, required this.userName});

  final String restaurantName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Align(alignment: Alignment.topLeft, child: _Tag(text: WatermarkCameraScreen.appName, bold: true)),
            Align(alignment: Alignment.bottomLeft, child: _Tag(text: restaurantName)),
            Align(alignment: Alignment.bottomRight, child: _Tag(text: userName)),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: bold ? AppDark.accentBright : Colors.white,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          fontSize: bold ? 15 : 13,
          letterSpacing: bold ? 0.3 : 0,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
