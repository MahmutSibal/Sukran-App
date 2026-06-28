import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/backend_dtos.dart';
import '../../../core/theme/app_dark.dart';
import '../../customer/data/customer_card_repository.dart';
import '../../customer/presentation/customer_card_management_section.dart' show customerCardsProvider;
import '../../customer/presentation/customer_menu_screen.dart' show formatMinorAsTry;
import '../../session/data/session_repository.dart';
import '../data/payment_repository.dart';

/// Akıllı Ödeme panelini alttan açar.
///
/// Sipariş takip ekranında "Hesap Öde" butonuna basıldığında çağrılır.
/// Backend'deki üç ödeme tipini tek bir şık panelde toplar:
///  1. Kendi Aldıklarımı Öde → `/payments/specific-items`
///  2. Eşit Bölüş             → `/payments/split-equally`
///  3. Tutar Gir              → `/payments/custom-amount`
///
/// [onPaid] başarı sonrası tetiklenir (genelde canlı sipariş akışını invalidate
/// etmek için).
Future<void> showSmartPaymentSheet(
  BuildContext context, {
  required String billId,
  required int remainingAmount,
  required List<OrderItemResponse> items,
  required VoidCallback onPaid,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SmartPaymentSheet(
      billId: billId,
      remainingAmount: remainingAmount,
      items: items,
      onPaid: onPaid,
    ),
  );
}

class SmartPaymentSheet extends ConsumerStatefulWidget {
  const SmartPaymentSheet({
    super.key,
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
  ConsumerState<SmartPaymentSheet> createState() => _SmartPaymentSheetState();
}

class _SmartPaymentSheetState extends ConsumerState<SmartPaymentSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    // Sekme değişince ödeme butonundaki tutar etiketi güncellenir.
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  // Tab 1 — seçili ürünler (orderItemId kümesi).
  final Set<String> _selectedItemIds = {};

  // Tab 2 — eşit bölüşülecek kişi sayısı.
  int _personCount = 2;

  // Tab 3 — manuel tutar (TL).
  final TextEditingController _amountController = TextEditingController();

  // Seçili kart (null → kart olmadan / kapıda gibi).
  String? _selectedCardId;
  bool _cardChoiceInitialised = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int get _selectedItemsTotal => widget.items
      .where((item) => _selectedItemIds.contains(item.orderItemId))
      .fold<int>(0, (sum, item) => sum + item.price);

  int get _perPersonShare => _personCount <= 0 ? 0 : (widget.remainingAmount / _personCount).round();

  int? get _customAmountMinor {
    final text = _amountController.text.trim();
    if (text.isEmpty) return null;
    // Türkçe biçim: binlik ayıracı "." kaldırılır, ondalık "," noktaya çevrilir.
    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  Future<void> _submit() async {
    final repo = ref.read(paymentRepositoryProvider);
    final session = await ref.read(sessionRepositoryProvider).loadSavedSession();
    if (session == null) {
      _snack('Ödeme için aktif oturum gerekli.');
      return;
    }
    final paidByUserId = await ref.read(appSessionStoreProvider).readUserId() ?? session.tableSessionId;

    // Kart seçildiyse cihazda saklı numarayı çöz (backend cardId ile birlikte
    // cardNumber bekler).
    String? cardNumber;
    if (_selectedCardId != null) {
      cardNumber = await ref.read(customerCardRepositoryProvider).readStoredCardNumber(_selectedCardId!);
      if (cardNumber == null || cardNumber.isEmpty) {
        _snack('Seçili kartın numarası cihazda bulunamadı, lütfen kartı yeniden ekleyin.');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final PaymentResultDto result;
      switch (_tabController.index) {
        case 0:
          if (_selectedItemIds.isEmpty) {
            _snack('En az bir ürün seçin.');
            return;
          }
          result = await repo.paySpecificItems(
            billId: widget.billId,
            itemIds: _selectedItemIds.toList(growable: false),
            paidByUserId: paidByUserId,
            amount: _selectedItemsTotal,
            customerCardId: _selectedCardId,
            cardNumber: cardNumber,
            accessToken: session.accessToken,
          );
          break;
        case 1:
          result = await repo.paySplitEqually(
            billId: widget.billId,
            personCount: _personCount,
            paidByUserId: paidByUserId,
            shareAmount: _perPersonShare,
            customerCardId: _selectedCardId,
            cardNumber: cardNumber,
            accessToken: session.accessToken,
          );
          break;
        default:
          final minor = _customAmountMinor;
          if (minor == null) {
            _snack('Geçerli bir tutar girin.');
            return;
          }
          result = await repo.payCustomAmount(
            billId: widget.billId,
            amount: minor,
            paidByUserId: paidByUserId,
            customerCardId: _selectedCardId,
            cardNumber: cardNumber,
            accessToken: session.accessToken,
          );
      }

      widget.onPaid();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme alındı: ${formatMinorAsTry(result.paidAmount)}')),
      );
    } catch (error) {
      _snack('Ödeme başarısız: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(customerCardsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppDark.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDark.radiusModuleLg)),
            border: Border(top: BorderSide(color: AppDark.hairline)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(color: AppDark.surfaceHigh, borderRadius: BorderRadius.circular(999)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesap Öde',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppDark.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kalan tutar: ${formatMinorAsTry(widget.remainingAmount)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppDark.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF000000)),
                    ),
                  ],
                ),
              ),
              _PaymentTabBar(controller: _tabController),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SpecificItemsTab(
                      scrollController: scrollController,
                      items: widget.items,
                      selectedIds: _selectedItemIds,
                      selectedTotal: _selectedItemsTotal,
                      onToggle: (id) => setState(() {
                        _selectedItemIds.contains(id) ? _selectedItemIds.remove(id) : _selectedItemIds.add(id);
                      }),
                    ),
                    _SplitEquallyTab(
                      remainingAmount: widget.remainingAmount,
                      personCount: _personCount,
                      perPersonShare: _perPersonShare,
                      onChanged: (value) => setState(() => _personCount = value),
                    ),
                    _CustomAmountTab(
                      controller: _amountController,
                      remainingAmount: widget.remainingAmount,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              _CardSelector(
                cardsAsync: cardsAsync,
                selectedCardId: _selectedCardId,
                onSelect: (cardId) => setState(() => _selectedCardId = cardId),
                onInitialiseDefault: (cards) {
                  if (_cardChoiceInitialised) return;
                  _cardChoiceInitialised = true;
                  final fallback = cards.where((c) => c.isDefault && c.isActive).firstOrNull ??
                      cards.where((c) => c.isActive).firstOrNull;
                  if (fallback != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedCardId = fallback.id);
                    });
                  }
                },
              ),
              _PayButtonBar(
                amountLabel: _payButtonLabel(),
                enabled: !_isSubmitting,
                isSubmitting: _isSubmitting,
                onPay: _submit,
              ),
            ],
          ),
        );
      },
    );
  }

  String _payButtonLabel() {
    switch (_tabController.index) {
      case 0:
        return _selectedItemIds.isEmpty ? 'Ürün seçin' : '${formatMinorAsTry(_selectedItemsTotal)} öde';
      case 1:
        return '${formatMinorAsTry(_perPersonShare)} öde';
      default:
        final minor = _customAmountMinor;
        return minor == null ? 'Tutarı öde' : '${formatMinorAsTry(minor)} öde';
    }
  }
}

class _PaymentTabBar extends StatelessWidget {
  const _PaymentTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppDark.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: false,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          indicator: BoxDecoration(
            gradient: AppDark.accentGradient,
            borderRadius: BorderRadius.circular(999),
          ),
          labelColor: const Color(0xFF000000),
          unselectedLabelColor: AppDark.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          tabs: const [
            Tab(text: 'Aldıklarım'),
            Tab(text: 'Eşit Bölüş'),
            Tab(text: 'Tutar Gir'),
          ],
        ),
      ),
    );
  }
}

class _SpecificItemsTab extends StatelessWidget {
  const _SpecificItemsTab({
    required this.scrollController,
    required this.items,
    required this.selectedIds,
    required this.selectedTotal,
    required this.onToggle,
  });

  final ScrollController scrollController;
  final List<OrderItemResponse> items;
  final Set<String> selectedIds;
  final int selectedTotal;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _TabEmptyState(icon: Icons.receipt_long_rounded, message: 'Bu hesapta ödenecek ürün yok.');
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final isPaid = item.paymentStatus == PaymentStatus.paid;
        final selected = selectedIds.contains(item.orderItemId);

        return Opacity(
          opacity: isPaid ? 0.45 : 1,
          child: GestureDetector(
            onTap: isPaid ? null : () => onToggle(item.orderItemId),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppDark.surfaceHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppDark.accent : AppDark.hairline,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  _CheckDot(selected: selected, disabled: isPaid),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppDark.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPaid ? 'Ödendi' : (item.orderedBy.isEmpty ? 'Hesaba ekli' : item.orderedBy),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isPaid ? AppDark.success : AppDark.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMinorAsTry(item.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppDark.accentBright,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplitEquallyTab extends StatelessWidget {
  const _SplitEquallyTab({
    required this.remainingAmount,
    required this.personCount,
    required this.perPersonShare,
    required this.onChanged,
  });

  final int remainingAmount;
  final int personCount;
  final int perPersonShare;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: AppDark.surfaceCard(),
            child: Column(
              children: [
                Text(
                  'Kişi başına düşen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  formatMinorAsTry(perPersonShare),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppDark.accentBright,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam ${formatMinorAsTry(remainingAmount)} • $personCount kişi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundStepButton(
                icon: Icons.remove_rounded,
                onTap: personCount > 1 ? () => onChanged(personCount - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      '$personCount',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppDark.textPrimary,
                          ),
                    ),
                    Text('kişi', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary)),
                  ],
                ),
              ),
              _RoundStepButton(
                icon: Icons.add_rounded,
                onTap: personCount < 50 ? () => onChanged(personCount + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomAmountTab extends StatelessWidget {
  const _CustomAmountTab({required this.controller, required this.remainingAmount, required this.onChanged});

  final TextEditingController controller;
  final int remainingAmount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ödemek istediğiniz tutar (TL)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppDark.textPrimary,
                ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_rounded),
              hintText: '0,00',
              suffixText: 'TL',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in _presetAmounts(remainingAmount))
                _PresetChip(
                  label: formatMinorAsTry(preset),
                  onTap: () {
                    controller.text = (preset / 100).toStringAsFixed(2).replaceAll('.', ',');
                    onChanged();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _presetAmounts(int remaining) {
    final presets = <int>{};
    for (final value in [5000, 10000, 25000]) {
      if (value < remaining) presets.add(value);
    }
    if (remaining > 0) presets.add(remaining); // tamamını öde
    return presets.toList(growable: false)..sort();
  }
}

class _CardSelector extends StatelessWidget {
  const _CardSelector({
    required this.cardsAsync,
    required this.selectedCardId,
    required this.onSelect,
    required this.onInitialiseDefault,
  });

  final AsyncValue<List<CustomerCardResponse>> cardsAsync;
  final String? selectedCardId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<List<CustomerCardResponse>> onInitialiseDefault;

  @override
  Widget build(BuildContext context) {
    return cardsAsync.when(
      data: (cards) {
        onInitialiseDefault(cards);
        final active = cards.where((c) => c.isActive).toList(growable: false);
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CardChip(
                  label: 'Kart yok',
                  icon: Icons.account_balance_wallet_outlined,
                  selected: selectedCardId == null,
                  onTap: () => onSelect(null),
                ),
                for (final card in active)
                  _CardChip(
                    label: '${card.brand} •••• ${card.last4}',
                    icon: Icons.credit_card_rounded,
                    selected: selectedCardId == card.id,
                    onTap: () => onSelect(card.id),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 52, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
      error: (_, _) => const SizedBox(height: 4),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppDark.accent.withValues(alpha: 0.18) : AppDark.surfaceHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppDark.accent : AppDark.hairline, width: selected ? 1.3 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? AppDark.accentBright : AppDark.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? AppDark.textPrimary : AppDark.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayButtonBar extends StatelessWidget {
  const _PayButtonBar({
    required this.amountLabel,
    required this.enabled,
    required this.isSubmitting,
    required this.onPay,
  });

  final String amountLabel;
  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppDark.accentGradient,
            borderRadius: BorderRadius.circular(AppDark.radiusControl),
            boxShadow: [
              BoxShadow(color: AppDark.accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: FilledButton(
            onPressed: enabled ? onPay : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF000000),
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF000000)),
                  )
                : Text(amountLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.selected, required this.disabled});

  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: selected ? AppDark.accentGradient : null,
        color: selected ? null : AppDark.surface,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? Colors.transparent : AppDark.textSecondary.withValues(alpha: 0.5), width: 1.5),
      ),
      child: disabled
          ? const Icon(Icons.lock_rounded, size: 13, color: AppDark.textSecondary)
          : (selected ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF000000)) : null),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? AppDark.surfaceHigh : AppDark.surfaceHigh.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? AppDark.accent.withValues(alpha: 0.5) : AppDark.hairline),
        ),
        child: Icon(icon, color: enabled ? AppDark.accentBright : AppDark.textSecondary),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppDark.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppDark.hairline),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppDark.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppDark.accent),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary)),
        ],
      ),
    );
  }
}
