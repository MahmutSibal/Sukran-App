import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/backend_dtos.dart';
import '../../../core/theme/app_dark.dart';
import '../../customer/presentation/customer_qr_session_screen.dart'
    show customerLocationProvider, nearbyRestaurantsProvider;
import '../../reviews/presentation/restaurant_reviews_screen.dart';
import '../data/route_service.dart';

/// Ekran: Keşfet — sistemdeki restoran/kafeleri harita üzerinde gösterir ve
/// kullanıcının seçtiği mekana rota (yol tarifi) oluşturmasını sağlar.
class CustomerDiscoverScreen extends ConsumerStatefulWidget {
  const CustomerDiscoverScreen({super.key});

  @override
  ConsumerState<CustomerDiscoverScreen> createState() => _CustomerDiscoverScreenState();
}

class _CustomerDiscoverScreenState extends ConsumerState<CustomerDiscoverScreen> {
  static const _istanbulCenter = LatLng(40.9867, 29.0293);

  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.86);

  int _selectedIndex = 0;
  RouteResult? _route;
  String? _routeRestaurantId;
  bool _routeLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  LatLng? get _userLatLng {
    final position = ref.read(customerLocationProvider).maybeWhen(data: (v) => v, orElse: () => null);
    return position == null ? null : LatLng(position.latitude, position.longitude);
  }

  void _onMarkerTap(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      _focusRestaurantAt(index);
    }
  }

  void _onCardChanged(int index, List<NearbyRestaurantDto> restaurants) {
    setState(() => _selectedIndex = index);
    _focusRestaurant(restaurants[index]);
  }

  void _focusRestaurantAt(int index) {
    final restaurants = ref.read(nearbyRestaurantsProvider).maybeWhen(data: (v) => v, orElse: () => const <NearbyRestaurantDto>[]);
    if (index >= 0 && index < restaurants.length) _focusRestaurant(restaurants[index]);
  }

  void _focusRestaurant(NearbyRestaurantDto restaurant) {
    _mapController.move(LatLng(restaurant.latitude, restaurant.longitude), 15);
  }

  Future<void> _createRoute(NearbyRestaurantDto restaurant) async {
    final from = _userLatLng;
    if (from == null) {
      _showSnack('Rota için konum izni gerekli. Yine de "Yol Tarifi" ile haritada açabilirsiniz.');
      return;
    }

    setState(() => _routeLoading = true);
    final to = LatLng(restaurant.latitude, restaurant.longitude);
    final result = await ref.read(routeServiceProvider).fetchDrivingRoute(from: from, to: to);
    if (!mounted) return;

    setState(() {
      _route = result;
      _routeRestaurantId = restaurant.id;
      _routeLoading = false;
    });

    // Rota tamamen görünecek şekilde kamerayı sığdır.
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: result.points,
        padding: const EdgeInsets.fromLTRB(50, 90, 50, 230),
        maxZoom: 16,
      ),
    );

    if (result.isFallback) {
      _showSnack('Canlı yol verisi alınamadı, yaklaşık düz rota gösteriliyor.');
    }
  }

  void _clearRoute() {
    setState(() {
      _route = null;
      _routeRestaurantId = null;
    });
  }

  Future<void> _openExternalDirections(NearbyRestaurantDto restaurant) async {
    final from = _userLatLng;
    if (from == null) {
      _showSnack('Google Maps rotası için konum izni gerekli.');
      return;
    }
    final uri = ref.read(routeServiceProvider).externalDirectionsUri(
          from: from,
          to: LatLng(restaurant.latitude, restaurant.longitude),
          label: restaurant.name,
        );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _showSnack('Harita uygulaması açılamadı.');
  }

  void _openReviews(NearbyRestaurantDto restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantReviewsScreen(restaurantId: restaurant.id, restaurantName: restaurant.name),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(nearbyRestaurantsProvider);
    final userLatLng = _userLatLng;

    return Scaffold(
      body: restaurantsAsync.when(
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return AppDark.scaffoldBackground(
              child: const Center(
                child: Text('Yakında mekan bulunamadı.', style: TextStyle(color: AppDark.textSecondary)),
              ),
            );
          }

          final selected = restaurants[_selectedIndex.clamp(0, restaurants.length - 1)];

          return Stack(
            children: [
              _buildMap(restaurants, userLatLng),
              _buildTopBar(context),
              if (_route != null) _buildRouteBanner(),
              _buildCarousel(restaurants),
              Positioned(
                right: 16,
                bottom: 232,
                child: _RecenterButton(
                  onTap: () {
                    final target = userLatLng ?? LatLng(selected.latitude, selected.longitude);
                    _mapController.move(target, 15);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => AppDark.scaffoldBackground(
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => AppDark.scaffoldBackground(
          child: Center(
            child: Text('Mekanlar yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary)),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(List<NearbyRestaurantDto> restaurants, LatLng? userLatLng) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userLatLng ?? _istanbulCenter,
        initialZoom: 14,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom | InteractiveFlag.flingAnimation,
        ),
      ),
      children: [
        TileLayer(
          // Birincil: standart OpenStreetMap döşemeleri — her ağda güvenilir
          // şekilde yüklenir ve net biçimde "harita" görünür.
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // CARTO koyu tema erişilebilirse daha şık görünür; bir döşeme
          // alınamazsa OSM'e geri düşülür.
          fallbackUrl: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sukran.app',
          maxZoom: 19,
          tileProvider: NetworkTileProvider(),
        ),
        if (_route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route!.points,
                strokeWidth: 5,
                color: AppDark.accentBright,
                borderColor: Colors.black.withValues(alpha: 0.5),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (userLatLng != null)
              Marker(
                point: userLatLng,
                width: 26,
                height: 26,
                child: const _UserDot(),
              ),
            for (var i = 0; i < restaurants.length; i++)
              Marker(
                point: LatLng(restaurants[i].latitude, restaurants[i].longitude),
                width: 46,
                height: 56,
                alignment: Alignment.topCenter,
                child: _RestaurantPin(
                  selected: i == _selectedIndex,
                  onTap: () => _onMarkerTap(i),
                ),
              ),
          ],
        ),
        const _MapAttribution(),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppDark.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          border: Border.all(color: AppDark.hairline),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_rounded, color: AppDark.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keşfet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppDark.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Yakındaki Sukran mekanları',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteBanner() {
    final route = _route!;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 78,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppDark.accentGradient,
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          boxShadow: [BoxShadow(color: AppDark.accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car_rounded, color: Color(0xFF1A1206), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Rota: ${route.distanceLabel} • ${route.durationLabel}${route.isFallback ? ' (yaklaşık)' : ''}',
                style: const TextStyle(color: Color(0xFF1A1206), fontWeight: FontWeight.w800),
              ),
            ),
            InkWell(
              onTap: _clearRoute,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, color: Color(0xFF1A1206), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(List<NearbyRestaurantDto> restaurants) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => _onCardChanged(index, restaurants),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return _RestaurantCard(
                restaurant: restaurant,
                isRouteTarget: _routeRestaurantId == restaurant.id,
                routeLoading: _routeLoading && _selectedIndex == index,
                onCreateRoute: () => _createRoute(restaurant),
                onExternal: () => _openExternalDirections(restaurant),
                onReviews: () => _openReviews(restaurant),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.isRouteTarget,
    required this.routeLoading,
    required this.onCreateRoute,
    required this.onExternal,
    required this.onReviews,
  });

  final NearbyRestaurantDto restaurant;
  final bool isRouteTarget;
  final bool routeLoading;
  final VoidCallback onCreateRoute;
  final VoidCallback onExternal;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) {
    final distance = restaurant.distanceMeters >= 1000
        ? '${(restaurant.distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${restaurant.distanceMeters.toStringAsFixed(0)} m';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppDark.surface,
          borderRadius: BorderRadius.circular(AppDark.radiusModule),
          border: Border.all(color: isRouteTarget ? AppDark.accent : AppDark.hairline, width: isRouteTarget ? 1.4 : 1),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 14))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppDark.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF1A1206)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppDark.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (restaurant.averageRating >= 4.5 && restaurant.reviewCount > 0) ...[
                            const SizedBox(width: 6),
                            const _FeaturedBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      _RatingLine(rating: restaurant.averageRating, count: restaurant.reviewCount),
                      const SizedBox(height: 2),
                      Text(
                        restaurant.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onReviews,
                  tooltip: 'Yorumlar',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.reviews_outlined, color: AppDark.accentBright),
                ),
                Column(
                  children: [
                    const Icon(Icons.near_me_rounded, color: AppDark.accent, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      distance,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppDark.accentBright,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppDark.accentGradient,
                      borderRadius: BorderRadius.circular(AppDark.radiusControl),
                    ),
                    child: FilledButton.icon(
                      onPressed: routeLoading ? null : onCreateRoute,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF120D04),
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: routeLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1206)),
                            )
                          : const Icon(Icons.route_rounded, size: 18),
                      label: Text(
                        isRouteTarget ? 'Google Maps Açık' : 'Google Maps Rota',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onExternal,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppDark.accentBright,
                      side: BorderSide(color: AppDark.accent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDark.radiusControl)),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Restoran kartında ortalama yıldız + yorum sayısı satırı.
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        'Henüz puan yok',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
      );
    }
    final full = rating.floor();
    final hasHalf = rating - full >= 0.5;
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full
                ? Icons.star_rounded
                : (i == full && hasHalf ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: 15,
            color: AppDark.accentBright,
          ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppDark.accentBright, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
        ),
      ],
    );
  }
}

/// Yüksek puanlı restoranlar için "Öne çıkan" altın rozeti.
class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppDark.accentGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: Color(0xFF1A1206)),
          SizedBox(width: 3),
          Text('Öne çıkan', style: TextStyle(color: Color(0xFF1A1206), fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _RestaurantPin extends StatelessWidget {
  const _RestaurantPin({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: selected ? 42 : 34,
            height: selected ? 42 : 34,
            decoration: BoxDecoration(
              gradient: AppDark.accentGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: selected ? 0.95 : 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppDark.accent.withValues(alpha: selected ? 0.7 : 0.4),
                  blurRadius: selected ? 16 : 8,
                  spreadRadius: selected ? 1 : 0,
                ),
              ],
            ),
            child: Icon(Icons.restaurant_rounded, color: const Color(0xFF1A1206), size: selected ? 22 : 18),
          ),
          CustomPaint(size: const Size(12, 8), painter: _PinTailPainter(selected: selected)),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = selected ? AppDark.accent : AppDark.accentBright;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => oldDelegate.selected != selected;
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4DA3FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF4DA3FF).withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)],
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppDark.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.my_location_rounded, color: AppDark.accent),
        ),
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 202),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '© OpenStreetMap · CARTO',
            style: TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ),
      ),
    );
  }
}
