import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/theme/app_dark.dart';
import '../../session/data/session_repository.dart';
import '../data/customer_card_repository.dart';

final customerCardsProvider = FutureProvider<List<CustomerCardResponse>>((ref) async {
  final session = await ref.read(sessionRepositoryProvider).loadSavedSession();
  return ref.read(customerCardRepositoryProvider).fetchMyCards(accessToken: session?.accessToken);
});

class CustomerCardManagementSection extends ConsumerStatefulWidget {
  const CustomerCardManagementSection({super.key});

  @override
  ConsumerState<CustomerCardManagementSection> createState() => _CustomerCardManagementSectionState();
}

class _CustomerCardManagementSectionState extends ConsumerState<CustomerCardManagementSection> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isDefault = true;
  bool _isSaving = false;
  String _brand = 'Kart';

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_onNumberChanged);
  }

  @override
  void dispose() {
    _numberController.removeListener(_onNumberChanged);
    _holderController.dispose();
    _numberController.dispose();
    _cvvController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onNumberChanged() {
    final brand = detectCardBrand(_numberController.text);
    if (brand != _brand) setState(() => _brand = brand);
  }

  /// Sunucudan dönen ham hata gövdesini kullanıcı dostu mesaja çevirir.
  String _friendlyError(Object error) {
    if (error is ApiException) {
      final body = error.message;
      // Backend JSON hata gövdesinden mesajı ayıkla.
      final match = RegExp(r'"(?:message|detail|title)"\s*:\s*"([^"]+)"').firstMatch(body);
      if (match != null) return match.group(1)!;
      if (error.statusCode == 401) return 'Oturum gerekli. Lütfen tekrar giriş yapın.';
      if (body.isNotEmpty && body.length < 200) return body;
      return 'İşlem reddedildi (${error.statusCode}).';
    }
    return 'Bağlantı hatası. İnternetinizi kontrol edin.';
  }

  Future<void> _saveCard() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final session = await ref.read(sessionRepositoryProvider).loadSavedSession();
    final month = int.parse(_monthController.text.trim());
    final year = _normalizeYear(_yearController.text.trim());

    try {
      await ref.read(customerCardRepositoryProvider).createCard(
            cardholderName: _holderController.text.trim(),
            cardNumber: _numberController.text.replaceAll(RegExp(r'\s'), '').trim(),
            expiryMonth: month,
            expiryYear: year,
            cvv: _cvvController.text.trim(),
            isDefault: _isDefault,
            accessToken: session?.accessToken,
          );
      if (mounted) {
        _numberController.clear();
        _cvvController.clear();
        _holderController.clear();
        _monthController.clear();
        _yearController.clear();
        setState(() {
          _isDefault = true;
          _brand = 'Kart';
        });
        ref.invalidate(customerCardsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kart güvenle kaydedildi.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kart kaydedilemedi: ${_friendlyError(error)}')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 2 haneli yıl girilirse 4 haneye tamamlar (25 -> 2025).
  int _normalizeYear(String raw) {
    final y = int.tryParse(raw) ?? 0;
    return y < 100 ? 2000 + y : y;
  }

  Future<void> _verifyCard(CustomerCardResponse card) async {
    final session = await ref.read(sessionRepositoryProvider).loadSavedSession();
    final storedNumber = await ref.read(customerCardRepositoryProvider).readStoredCardNumber(card.id);
    try {
      final result = await ref.read(customerCardRepositoryProvider).verifyCard(
            cardId: card.id,
            cardNumber: storedNumber ?? _numberController.text.trim(),
            accessToken: session?.accessToken,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doğrulama başarısız: ${_friendlyError(error)}')));
      }
    }
  }

  Future<void> _deleteCard(CustomerCardResponse card) async {
    final session = await ref.read(sessionRepositoryProvider).loadSavedSession();
    try {
      await ref.read(customerCardRepositoryProvider).deleteCard(cardId: card.id, accessToken: session?.accessToken);
      ref.invalidate(customerCardsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kart silindi.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kart silinemedi: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(customerCardsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kartlarım', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _holderController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    decoration: const InputDecoration(labelText: 'Kart üzerindeki ad'),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Ad gerekli';
                      if (!v.contains(' ')) return 'Ad ve soyad girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Kart numarası',
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                      suffixText: _brand == 'Kart' ? null : _brand,
                    ),
                    validator: (value) {
                      final v = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                      if (v.isEmpty) return 'Kart numarası gerekli';
                      if (!isCardNumberValid(v)) return 'Geçersiz kart numarası';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _monthController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(labelText: 'Ay (AA)'),
                          validator: (value) {
                            final m = int.tryParse(value?.trim() ?? '');
                            if (m == null || m < 1 || m > 12) return 'Geçersiz ay';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(labelText: 'Yıl (YY/YYYY)'),
                          validator: (value) {
                            final raw = value?.trim() ?? '';
                            if (raw.isEmpty) return 'Yıl gerekli';
                            final year = _normalizeYear(raw);
                            final month = int.tryParse(_monthController.text.trim()) ?? 0;
                            if (!isCardExpiryValid(month, year)) return 'Süresi geçmiş';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(labelText: 'CVV'),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.length < 3 || v.length > 4) return '3-4 hane';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Varsayılan kart yap'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: AppDark.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Kart numaranız sunucuda şifreli saklanır; tam numara hiçbir yerde açık tutulmaz.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveCard,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.credit_card_rounded),
                    label: Text(_isSaving ? 'Kaydediliyor...' : 'Kart Kaydet'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        cardsAsync.when(
          data: (cards) {
            if (cards.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Kayıtlı kart yok.', style: TextStyle(color: AppDark.textSecondary)),
              );
            }

            return Column(
              children: cards.map((card) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_card_rounded),
                    title: Text('${card.brand} •••• ${card.last4}'),
                    subtitle: Text('${card.cardholderName} • ${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'verify':
                            _verifyCard(card);
                            break;
                          case 'delete':
                            _deleteCard(card);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'verify', child: Text('Doğrula')),
                        PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                    isThreeLine: card.isDefault || !card.isActive,
                    dense: false,
                  ),
                );
              }).toList(growable: false),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Kartlar yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary)),
          ),
        ),
      ],
    );
  }
}
