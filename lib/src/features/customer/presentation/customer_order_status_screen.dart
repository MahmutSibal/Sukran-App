import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/backend_dtos.dart';
import '../../../core/theme/app_dark.dart';
import '../data/customer_card_repository.dart';
import '../../orders/data/order_repository.dart';
import '../../payments/presentation/smart_payment_sheet.dart';
import '../../session/data/session_repository.dart';
import 'customer_card_management_section.dart' show customerCardsProvider;
import 'customer_menu_screen.dart';

/// SignalR `/hubs/orders` hub'ına bağlı kalan canlı sipariş akışı.
final customerOrderStreamProvider = StreamProvider<List<OrderResponse>>((ref) async* {
  final session = await ref.read(sessionRepositoryProvider).loadSavedSession();
  if (session == null) {
    yield const <OrderResponse>[];
    return;
  }
  yield* ref.read(orderRepositoryProvider).watchOrdersByRestaurant(session.restaurantId, accessToken: session.accessToken);
});

const _statusOrder = <OrderItemStatus>[
  OrderItemStatus.pending,
  OrderItemStatus.kitchen,
  OrderItemStatus.preparing,
  OrderItemStatus.ready,
  OrderItemStatus.delivered,
];

String _statusLabel(OrderItemStatus status) {
  return switch (status) {
    OrderItemStatus.pending => 'Bekliyor',
    OrderItemStatus.kitchen => 'Mutfakta',
    OrderItemStatus.preparing => 'Hazırlanıyor',
    OrderItemStatus.ready => 'Hazır',
    OrderItemStatus.delivered => 'Teslim Edildi',
  };
}

IconData _statusIcon(OrderItemStatus status) {
  return switch (status) {
    OrderItemStatus.pending => Icons.schedule_rounded,
    OrderItemStatus.kitchen => Icons.soup_kitchen_rounded,
    OrderItemStatus.preparing => Icons.restaurant_rounded,
    OrderItemStatus.ready => Icons.check_circle_rounded,
    OrderItemStatus.delivered => Icons.done_all_rounded,
  };
}

Color _statusColor(OrderItemStatus status) {
  return switch (status) {
    OrderItemStatus.pending => AppDark.textSecondary,
    OrderItemStatus.kitchen || OrderItemStatus.preparing => AppDark.accent,
    OrderItemStatus.ready || OrderItemStatus.delivered => AppDark.success,
  };
}

class CustomerOrderStatusScreen extends ConsumerWidget {
  const CustomerOrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(customerSessionProvider);
    final currentOrder = ref.watch(customerCurrentOrderProvider);
    final orderStream = ref.watch(customerOrderStreamProvider);

    return Scaffold(
      body: AppDark.scaffoldBackground(
        child: sessionAsync.when(
          data: (session) {
            if (session == null) {
              return Center(
                child: FilledButton(
                  onPressed: () => context.go('/customer/qr'),
                  child: const Text('Önce QR oturumu açın'),
                ),
              );
            }

            return orderStream.when(
              data: (orders) {
                final tableOrders = orders.where((order) => order.tableNo == session.tableNo).toList(growable: false);
                final activeOrder = currentOrder ?? (tableOrders.isNotEmpty ? tableOrders.first : null);
                final items = activeOrder?.items ?? const <OrderItemResponse>[];

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 120,
                      backgroundColor: Colors.transparent,
                      leading: IconButton(
                        onPressed: () => context.go('/customer/menu'),
                        icon: const Icon(Icons.arrow_back_rounded, color: AppDark.textPrimary),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
                        title: Text(
                          'Sipariş Takibi',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppDark.textPrimary,
                              ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: AppDark.screenPadding,
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          _OrderHeroCard(
                            tableNo: session.tableNo,
                            totalAmount: activeOrder?.totalAmount ?? 0,
                            remainingAmount: activeOrder?.remainingAmount ?? 0,
                            itemCount: items.length,
                          ),
                          if ((activeOrder?.remainingAmount ?? 0) > 0) ...[
                            const SizedBox(height: 16),
                            _PayBillButton(
                              billId: activeOrder!.id,
                              remainingAmount: activeOrder.remainingAmount,
                              items: items,
                              onPaid: () => ref.invalidate(customerOrderStreamProvider),
                            ),
                            const SizedBox(height: 16),
                            _CardPaymentPanel(
                              billId: activeOrder.id,
                              remainingAmount: activeOrder.remainingAmount,
                              tableNo: session.tableNo,
                              paidByUserId: session.tableSessionId,
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Canlı Zaman Tüneli',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppDark.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Durumlar SignalR ile anlık güncellenir.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          if (items.isEmpty)
                            const _EmptyTimeline()
                          else
                            ...List.generate(items.length, (index) {
                              return _TimelineItem(item: items[index], isLast: index == items.length - 1);
                            }),
                        ]),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Sipariş durumu alınamadı: $error',
                    style: const TextStyle(color: AppDark.textSecondary)),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Oturum alınamadı: $error', style: const TextStyle(color: AppDark.textSecondary)),
          ),
        ),
      ),
    );
  }
}

/// Spec'teki "Hesap Öde" butonu — Akıllı Ödeme panelini (3 sekme) açar.
class _PayBillButton extends StatelessWidget {
  const _PayBillButton({
    required this.billId,
    required this.remainingAmount,
    required this.items,
    required this.onPaid,
  });

  final String billId;
  final int remainingAmount;
  final List<OrderItemResponse> items;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDark.accentGradient,
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          boxShadow: [
            BoxShadow(color: AppDark.accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: FilledButton.icon(
          onPressed: () => showSmartPaymentSheet(
            context,
            billId: billId,
            remainingAmount: remainingAmount,
            items: items,
            onPaid: onPaid,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF000000),
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
          label: const Text('Hesap Öde', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    );
  }
}

class _CardPaymentPanel extends ConsumerWidget {
  const _CardPaymentPanel({
    required this.billId,
    required this.remainingAmount,
    required this.tableNo,
    required this.paidByUserId,
  });

  final String billId;
  final int remainingAmount;
  final int tableNo;
  final String paidByUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(customerCardsProvider);

    return cardsAsync.when(
      data: (cards) {
        final defaultCard = cards.where((card) => card.isDefault && card.isActive).firstOrNull;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: AppDark.surfaceCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card_rounded, color: AppDark.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kartla Ödeme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppDark.textPrimary,
                          ),
                    ),
                  ),
                  if (defaultCard != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppDark.success.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Varsayılan: •••• ${defaultCard.last4}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppDark.success,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Kalan tutar: ${formatMinorAsTry(remainingAmount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: defaultCard == null ? null : () => _payWithDefaultCard(context, ref, defaultCard),
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Kayıtlı kartla öde'),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Kartlar yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary)),
    );
  }

  Future<void> _payWithDefaultCard(BuildContext context, WidgetRef ref, CustomerCardResponse card) async {
    final session = await ref.read(sessionRepositoryProvider).loadSavedSession();
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ödeme için oturum gerekli.')));
      return;
    }

    final paidByUserId = await ref.read(appSessionStoreProvider).readUserId() ?? session.tableSessionId;

    final secret = await ref.read(customerCardRepositoryProvider).readStoredCardNumber(card.id);
    if (secret == null || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıtlı kart numarası cihazda bulunamadı.')));
      return;
    }

    try {
      await ref.read(customerCardRepositoryProvider).payRemainingAmountWithCard(
            billId: billId,
            amount: remainingAmount,
        paidByUserId: paidByUserId,
            cardId: card.id,
            cardNumber: secret,
            accessToken: session.accessToken,
          );
      ref.invalidate(customerOrderStreamProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ödeme tamamlandı.')));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ödeme başarısız: $error')));
    }
  }
}

class _OrderHeroCard extends StatelessWidget {
  const _OrderHeroCard({
    required this.tableNo,
    required this.totalAmount,
    required this.remainingAmount,
    required this.itemCount,
  });

  final int tableNo;
  final int totalAmount;
  final int remainingAmount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDark.surfaceCard(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppDark.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF000000), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa $tableNo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppDark.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount kalem • canlı takip',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMinorAsTry(totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppDark.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kalan: ${formatMinorAsTry(remainingAmount)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item, required this.isLast});

  final OrderItemResponse item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    final stageIndex = _statusOrder.indexOf(item.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _AnimatedStatusNode(status: item.status),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDark.surfaceCard(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppDark.textPrimary,
                                ),
                          ),
                        ),
                        _StatusChip(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StageDots(activeIndex: stageIndex, color: color),
                    const SizedBox(height: 8),
                    Text(
                      item.orderedBy.isEmpty ? formatMinorAsTry(item.price) : '${item.orderedBy} • ${formatMinorAsTry(item.price)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SignalR güncellemesinde parlayan/animasyonlu durum düğümü.
/// "Hazırlanıyor" için dönen ikon, "Hazır/Teslim" için açılan parlak tik.
class _AnimatedStatusNode extends StatefulWidget {
  const _AnimatedStatusNode({required this.status});

  final OrderItemStatus status;

  @override
  State<_AnimatedStatusNode> createState() => _AnimatedStatusNodeState();
}

class _AnimatedStatusNodeState extends State<_AnimatedStatusNode> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  bool get _spins => widget.status == OrderItemStatus.preparing || widget.status == OrderItemStatus.kitchen;

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedStatusNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      // Status changed via SignalR — replay a bright pop.
      _controller.forward(from: 0);
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (_spins) {
      _controller.repeat();
    } else {
      _controller.stop();
      if (!_controller.isAnimating && _controller.value == 0) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.status);
    final icon = _statusIcon(widget.status);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pop = _spins ? 1.0 : (0.85 + 0.15 * Curves.easeOutBack.transform(_controller.value.clamp(0, 1)));
        return Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14)],
          ),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: pop,
            child: Transform.rotate(
              angle: _spins ? _controller.value * 6.283185 : 0,
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        );
      },
    );
  }
}

class _StageDots extends StatelessWidget {
  const _StageDots({required this.activeIndex, required this.color});

  final int activeIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_statusOrder.length, (index) {
        final reached = index <= activeIndex;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == _statusOrder.length - 1 ? 0 : 5),
            decoration: BoxDecoration(
              color: reached ? color : AppDark.surfaceHigh,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderItemStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppDark.surfaceCard(),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, size: 48, color: AppDark.accent),
          const SizedBox(height: 12),
          Text(
            'Henüz aktif sipariş yok',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppDark.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menüden sipariş verdiğinizde durum burada canlı görünür.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
          ),
        ],
      ),
    );
  }
}
