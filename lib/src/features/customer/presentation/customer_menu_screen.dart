import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/backend_dtos.dart';
import '../../../core/theme/app_dark.dart';
import '../../menu/data/menu_repository.dart';
import '../../session/data/session_repository.dart';
import '../../session/domain/customer_session.dart';
import '../../orders/domain/order_models.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final customerCurrentOrderProvider = StateProvider<OrderResponse?>((ref) => null);
final customerMenuCartProvider =
    StateNotifierProvider<CustomerMenuCartController, Map<String, int>>((ref) => CustomerMenuCartController());

final customerSessionProvider = FutureProvider<CustomerSession?>((ref) {
  return ref.read(sessionRepositoryProvider).loadSavedSession();
});

final menuItemsProvider = FutureProvider.family<List<MenuItemResponse>, String>((ref, restaurantId) {
  return ref.read(menuRepositoryProvider).fetchMenuItems(restaurantId);
});

/// Backend `long` (kuruş) fiyatını "150.00 TL" formatına çevirir.
String formatMinorAsTry(int minor) {
  final formatter = NumberFormat('#,##0.00', 'tr_TR');
  return '${formatter.format(minor / 100)} TL';
}

class CustomerMenuCartController extends StateNotifier<Map<String, int>> {
  CustomerMenuCartController() : super(const {});

  void increment(String menuItemId) => state = {...state, menuItemId: (state[menuItemId] ?? 0) + 1};

  void decrement(String menuItemId) {
    final current = state[menuItemId] ?? 0;
    if (current <= 1) {
      final copy = Map<String, int>.from(state)..remove(menuItemId);
      state = copy;
      return;
    }
    state = {...state, menuItemId: current - 1};
  }

  void clear() => state = const {};
}

class CustomerMenuScreen extends ConsumerWidget {
  const CustomerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(customerSessionProvider);
    final cart = ref.watch(customerMenuCartProvider);
    final category = ref.watch(selectedCategoryProvider);

    return Scaffold(
      body: AppDark.scaffoldBackground(
        child: sessionAsync.when(
          data: (session) {
            if (session == null) {
              return _CenteredAction(
                label: 'Önce QR oturumu açın',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () => context.go('/customer/qr'),
              );
            }

            final menuAsync = ref.watch(menuItemsProvider(session.restaurantId));

            return menuAsync.when(
              data: (menuItems) {
                final categories = [
                  'Tüm Menü',
                  ...(menuItems.map((item) => item.category).toSet().toList()..sort()),
                ];
                final selectedCategory = category ?? 'Tüm Menü';
                final visibleItems = selectedCategory == 'Tüm Menü'
                    ? menuItems
                    : menuItems.where((item) => item.category == selectedCategory).toList(growable: false);

                return Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          expandedHeight: 132,
                          backgroundColor: Colors.transparent,
                          flexibleSpace: FlexibleSpaceBar(
                            titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                            title: Text(
                              'Dijital Menü',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppDark.textPrimary,
                                  ),
                            ),
                          ),
                          actions: [
                            IconButton(
                              onPressed: () => context.go('/customer/orders'),
                              icon: const Icon(Icons.timeline_rounded, color: AppDark.accent),
                              tooltip: 'Sipariş takibi',
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: _MenuHeader(session: session),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 60,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final item = categories[index];
                                return _CategoryChip(
                                  label: item,
                                  selected: item == selectedCategory,
                                  onTap: () => ref.read(selectedCategoryProvider.notifier).state = item,
                                );
                              },
                              separatorBuilder: (context, index) => const SizedBox(width: 10),
                              itemCount: categories.length,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(20, 6, 20, cart.isEmpty ? 28 : 140),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = visibleItems[index];
                                return _MenuItemCard(
                                  item: item,
                                  quantity: cart[item.id] ?? 0,
                                  onAdd: () => ref.read(customerMenuCartProvider.notifier).increment(item.id),
                                  onRemove: () => ref.read(customerMenuCartProvider.notifier).decrement(item.id),
                                );
                              },
                              childCount: visibleItems.length,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.66,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (cart.isNotEmpty)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _SmartCartBar(
                          cart: cart,
                          menuItems: menuItems,
                          onTap: () => _openCartSheet(context, ref, session, menuItems),
                          onOrder: () => _placeOrder(context, ref, session, menuItems),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const _CenteredMessage(
                icon: Icons.restaurant_menu_rounded,
                message: 'Menü yüklenemedi, demo veri kullanılıyor.',
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _CenteredAction(
            label: 'Oturum bulunamadı',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => context.go('/customer/qr'),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(
    BuildContext context,
    WidgetRef ref,
    CustomerSession session,
    List<MenuItemResponse> menuItems,
  ) async {
    final cart = ref.read(customerMenuCartProvider);
    if (cart.isEmpty) return;

    final selectedItems = _expandCart(cart, menuItems);
    final order = await ref.read(menuRepositoryProvider).createOrder(session: session, selectedItems: selectedItems);
    ref.read(customerCurrentOrderProvider.notifier).state = order;
    ref.read(customerMenuCartProvider.notifier).clear();
    if (!context.mounted) return;
    context.go('/customer/orders');
  }

  Future<void> _openCartSheet(
    BuildContext context,
    WidgetRef ref,
    CustomerSession session,
    List<MenuItemResponse> menuItems,
  ) async {
    if (ref.read(customerMenuCartProvider).isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final cart = sheetRef.watch(customerMenuCartProvider);
            return _CartSheet(
              cart: cart,
              menuItems: menuItems,
              onIncrement: (id) => sheetRef.read(customerMenuCartProvider.notifier).increment(id),
              onDecrement: (id) => sheetRef.read(customerMenuCartProvider.notifier).decrement(id),
              onOrder: () async {
                final selectedItems = _expandCart(cart, menuItems);
                if (selectedItems.isEmpty) return;
                final order = await sheetRef
                    .read(menuRepositoryProvider)
                    .createOrder(session: session, selectedItems: selectedItems);
                sheetRef.read(customerCurrentOrderProvider.notifier).state = order;
                sheetRef.read(customerMenuCartProvider.notifier).clear();
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                if (context.mounted) context.go('/customer/orders');
              },
            );
          },
        );
      },
    );
  }

  static List<MenuItemResponse> _expandCart(Map<String, int> cart, List<MenuItemResponse> menuItems) {
    final selectedItems = <MenuItemResponse>[];
    for (final entry in cart.entries) {
      final item = menuItems.where((menuItem) => menuItem.id == entry.key).firstOrNull;
      if (item == null) continue;
      for (var i = 0; i < entry.value; i++) {
        selectedItems.add(item);
      }
    }
    return selectedItems;
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.session});

  final CustomerSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDark.surfaceCard(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppDark.accentGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_dining_rounded, color: Color(0xFF000000)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa ${session.tableNo}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppDark.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Siparişleriniz ve sepetiniz canlı tutulur.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppDark.success),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppDark.accentGradient : null,
          color: selected ? null : AppDark.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.transparent : AppDark.hairline),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? const Color(0xFF000000) : AppDark.textSecondary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item, required this.quantity, required this.onAdd, required this.onRemove});

  final MenuItemResponse item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDark.surfaceCard(radius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const ColoredBox(color: AppDark.surfaceHigh);
                  },
                  errorBuilder: (context, error, stackTrace) => const ColoredBox(
                    color: AppDark.surfaceHigh,
                    child: Icon(Icons.fastfood_rounded, color: AppDark.accent, size: 38),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.45, 1.0],
                    ),
                  ),
                ),
                if (!item.isAvailable)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Tükendi',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppDark.danger,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppDark.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        formatMinorAsTry(item.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppDark.accentBright,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (quantity == 0)
                      _RoundAddButton(onTap: item.isAvailable ? onAdd : null)
                    else
                      _QuantityStepper(quantity: quantity, onAdd: onAdd, onRemove: onRemove),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAddButton extends StatelessWidget {
  const _RoundAddButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: enabled ? AppDark.accentGradient : null,
          color: enabled ? null : AppDark.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.add_rounded, color: enabled ? const Color(0xFF000000) : AppDark.textSecondary, size: 22),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onAdd, required this.onRemove});

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDark.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppDark.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepIcon(icon: Icons.remove_rounded, onTap: onRemove),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppDark.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          _StepIcon(icon: Icons.add_rounded, onTap: onAdd),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 30, height: 34, child: Icon(icon, size: 18, color: AppDark.accentBright)),
    );
  }
}

class _SmartCartBar extends StatelessWidget {
  const _SmartCartBar({required this.cart, required this.menuItems, required this.onTap, required this.onOrder});

  final Map<String, int> cart;
  final List<MenuItemResponse> menuItems;
  final VoidCallback onTap;
  final Future<void> Function() onOrder;

  @override
  Widget build(BuildContext context) {
    final total = cart.entries.fold<int>(0, (sum, entry) {
      final item = menuItems.where((menuItem) => menuItem.id == entry.key).firstOrNull;
      return sum + (item == null ? 0 : item.price * entry.value);
    });
    final count = cart.values.fold<int>(0, (sum, qty) => sum + qty);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppDark.surface,
            borderRadius: BorderRadius.circular(AppDark.radiusModuleLg),
            border: Border.all(color: AppDark.hairline),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 34, offset: Offset(0, 16))],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$count ürün • sepeti gör',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppDark.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMinorAsTry(total),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppDark.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _GoldOrderButton(onOrder: onOrder),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tamamen altın renginde, üzerinde siyah kalın fontla "Sipariş Ver".
class _GoldOrderButton extends StatelessWidget {
  const _GoldOrderButton({required this.onOrder});

  final Future<void> Function() onOrder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppDark.accentGradient,
        borderRadius: BorderRadius.circular(AppDark.radiusControl),
        boxShadow: [
          BoxShadow(color: AppDark.accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: FilledButton(
        onPressed: onOrder,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF000000),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        ),
        child: const Text('Sipariş Ver', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet({
    required this.cart,
    required this.menuItems,
    required this.onIncrement,
    required this.onDecrement,
    required this.onOrder,
  });

  final Map<String, int> cart;
  final List<MenuItemResponse> menuItems;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;
  final Future<void> Function() onOrder;

  @override
  Widget build(BuildContext context) {
    final total = cart.entries.fold<int>(0, (sum, entry) {
      final item = menuItems.where((menuItem) => menuItem.id == entry.key).firstOrNull;
      return sum + (item == null ? 0 : item.price * entry.value);
    });

    return Container(
      decoration: const BoxDecoration(
        color: AppDark.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDark.radiusModuleLg)),
        border: Border(top: BorderSide(color: AppDark.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(color: AppDark.surfaceHigh, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Sepet Detayı',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppDark.textPrimary,
                ),
          ),
          const SizedBox(height: 14),
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Sepet boş.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppDark.textSecondary)),
            )
          else
            ...cart.entries.map((entry) {
              final item = menuItems.where((menuItem) => menuItem.id == entry.key).firstOrNull;
              if (item == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppDark.textPrimary,
                            ),
                      ),
                    ),
                    _QuantityStepper(
                      quantity: entry.value,
                      onAdd: () => onIncrement(entry.key),
                      onRemove: () => onDecrement(entry.key),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 92,
                      child: Text(
                        formatMinorAsTry(item.price * entry.value),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppDark.accentBright,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 28, color: AppDark.hairline),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Toplam',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppDark.textPrimary,
                      ),
                ),
              ),
              Text(
                formatMinorAsTry(total),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppDark.accentBright,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: _GoldOrderButton(onOrder: onOrder),
          ),
        ],
      ),
    );
  }
}

class _CenteredAction extends StatelessWidget {
  const _CenteredAction({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: AppDark.accent),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppDark.textSecondary)),
        ],
      ),
    );
  }
}
