import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_seed.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/theme/app_dark.dart';
import '../../auth/application/auth_controller.dart';
import '../data/restaurant_owner_repository.dart';

class RestaurantOwnerShell extends ConsumerStatefulWidget {
  const RestaurantOwnerShell({super.key, required this.accessToken});

  final String? accessToken;

  @override
  ConsumerState<RestaurantOwnerShell> createState() => _RestaurantOwnerShellState();
}

class _RestaurantOwnerShellState extends ConsumerState<RestaurantOwnerShell> {
  final _restaurantQueryController = TextEditingController(text: DemoSeed.restaurantDetail.slug);
  final _tableNoController = TextEditingController(text: '1');

  RestaurantDetailResponse? _restaurant;
  List<MenuItemResponse> _menuItems = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _restaurantQueryController.dispose();
    _tableNoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repository = ref.read(restaurantOwnerRepositoryProvider);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final restaurant = await repository.fetchRestaurantByQuery(
        _restaurantQueryController.text,
        accessToken: widget.accessToken,
      );
      if (restaurant == null) {
        throw StateError('Restaurant not found.');
      }
      final menuItems = await repository.fetchMenuItems(restaurant.id, accessToken: widget.accessToken);
      if (!mounted) return;
      setState(() {
        _restaurant = restaurant;
        _menuItems = menuItems;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _restaurant = null;
        _menuItems = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleSession({required bool open}) async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    final tableNo = int.tryParse(_tableNoController.text.trim());
    if (tableNo == null || tableNo <= 0) {
      _showMessage('Masa numarası geçerli olmalı.');
      return;
    }

    try {
      final repository = ref.read(restaurantOwnerRepositoryProvider);
      if (open) {
        await repository.openTableSession(restaurantId: restaurant.id, tableNo: tableNo, accessToken: widget.accessToken);
      } else {
        await repository.closeTableSession(restaurantId: restaurant.id, tableNo: tableNo, accessToken: widget.accessToken);
      }
      _showMessage(open ? 'Masa oturumu açıldı.' : 'Masa oturumu kapatıldı.');
    } catch (error) {
      _showMessage('İşlem başarısız: $error');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant;
    final totalMenuItems = _menuItems.length;
    final availableMenuItems = _menuItems.where((item) => item.isAvailable).length;
    final totalMenuValue = _menuItems.fold<int>(0, (sum, item) => sum + item.price);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: AppDark.scaffoldBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
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
                            Text(
                              'İşletme Paneli',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppDark.textPrimary,
                                  ),
                            ),
                            Text(
                              'Menu ve masa oturumları web üzerinden yönetilir.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Çıkış yap',
                        onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                        icon: const Icon(Icons.logout_rounded, color: AppDark.textSecondary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _restaurantQueryController,
                          style: const TextStyle(color: AppDark.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Restaurant slug veya ID',
                            prefixIcon: Icon(Icons.restaurant_rounded),
                          ),
                          onSubmitted: (_) => _loadData(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _loading ? null : _loadData,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1206)),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: const Text('Yükle', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppDark.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppDark.hairline),
                    ),
                    child: const TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: 'Pano'),
                        Tab(text: 'Menü'),
                        Tab(text: 'Masalar'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DashboardTab(
                        loading: _loading,
                        error: _error,
                        restaurant: restaurant,
                        totalMenuItems: totalMenuItems,
                        availableMenuItems: availableMenuItems,
                        totalMenuValue: totalMenuValue,
                      ),
                      _MenuTab(loading: _loading, error: _error, menuItems: _menuItems),
                      _TablesTab(
                        restaurant: restaurant,
                        loading: _loading,
                        error: _error,
                        tableNoController: _tableNoController,
                        onOpenSession: () => _toggleSession(open: true),
                        onCloseSession: () => _toggleSession(open: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.loading,
    required this.error,
    required this.restaurant,
    required this.totalMenuItems,
    required this.availableMenuItems,
    required this.totalMenuValue,
  });

  final bool loading;
  final String? error;
  final RestaurantDetailResponse? restaurant;
  final int totalMenuItems;
  final int availableMenuItems;
  final int totalMenuValue;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text('Veri alınamadı: $error', style: const TextStyle(color: AppDark.textSecondary)),
      );
    }
    final currentRestaurant = restaurant;
    if (currentRestaurant == null) {
      return const Center(child: Text('Restoran seçilmedi.', style: TextStyle(color: AppDark.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppDark.surfaceCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentRestaurant.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppDark.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text('${currentRestaurant.slug} • ${currentRestaurant.address}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricChip(label: 'Toplam Menü', value: '$totalMenuItems'),
                  _MetricChip(label: 'Satılabilir', value: '$availableMenuItems'),
                  _MetricChip(label: 'Toplam Menü Değeri', value: _formatTry(totalMenuValue)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({required this.loading, required this.error, required this.menuItems});

  final bool loading;
  final String? error;
  final List<MenuItemResponse> menuItems;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text('Menü alınamadı: $error', style: const TextStyle(color: AppDark.textSecondary)),
      );
    }
    if (menuItems.isEmpty) {
      return const Center(
        child: Text('Menü öğesi yok.', style: TextStyle(color: AppDark.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: AppDark.surfaceCard(),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppDark.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: AppDark.accentBright),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppDark.textPrimary,
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 4),
                    Text('${item.category} • ${item.averagePreparationTime} dk',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(_formatTry(item.price),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppDark.accentBright,
                        fontWeight: FontWeight.w800,
                      )),
              const SizedBox(width: 12),
              Chip(
                label: Text(item.isAvailable ? 'Aktif' : 'Pasif'),
                backgroundColor: item.isAvailable ? AppDark.success.withValues(alpha: 0.15) : AppDark.danger.withValues(alpha: 0.15),
                side: BorderSide.none,
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: menuItems.length,
    );
  }
}

class _TablesTab extends StatelessWidget {
  const _TablesTab({
    required this.restaurant,
    required this.loading,
    required this.error,
    required this.tableNoController,
    required this.onOpenSession,
    required this.onCloseSession,
  });

  final RestaurantDetailResponse? restaurant;
  final bool loading;
  final String? error;
  final TextEditingController tableNoController;
  final VoidCallback onOpenSession;
  final VoidCallback onCloseSession;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text('Masalar yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary)),
      );
    }
    if (restaurant == null) {
      return const Center(child: Text('Önce restoran yükleyin.', style: TextStyle(color: AppDark.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppDark.surfaceCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Masa Oturumu', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tableNoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Masa No',
                        prefixIcon: Icon(Icons.table_restaurant_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: onOpenSession,
                    child: const Text('Aç'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onCloseSession,
                    child: const Text('Kapat'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Bu aksiyonlar ${restaurant!.name} için oturum açma / kapama yapar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppDark.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDark.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppDark.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppDark.textPrimary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

String _formatTry(int value) => '${(value / 100).toStringAsFixed(2)} TL';
