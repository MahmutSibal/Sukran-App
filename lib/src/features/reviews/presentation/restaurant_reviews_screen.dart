import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/theme/app_dark.dart';
import '../../profile/data/profile_repository.dart';
import '../data/review_repository.dart';
import 'watermark_camera_screen.dart';

/// Bir restoranın yorumlarını listeler; kullanıcı yorum ekleyebilir ve
/// yorumları beğenip/beğenmeme yapabilir.
class RestaurantReviewsScreen extends ConsumerWidget {
  const RestaurantReviewsScreen({required this.restaurantId, required this.restaurantName, super.key});

  final String restaurantId;
  final String restaurantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(restaurantReviewsProvider(restaurantId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(restaurantName, maxLines: 1, overflow: TextOverflow.ellipsis),
            const Text('Yorumlar', style: TextStyle(fontSize: 12, color: AppDark.textSecondary)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppDark.accent,
        foregroundColor: const Color(0xFF1A1206),
        onPressed: () => _openComposer(context, ref),
        icon: const Icon(Icons.rate_review_rounded),
        label: const Text('Yorum Yap', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: AppDark.scaffoldBackground(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(restaurantReviewsProvider(restaurantId)),
          child: reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.reviews_outlined, size: 56, color: AppDark.textSecondary),
                    SizedBox(height: 12),
                    Center(child: Text('Henüz yorum yok. İlk yorumu sen yap!', style: TextStyle(color: AppDark.textSecondary))),
                  ],
                );
              }
              final avg = reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: reviews.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SummaryHeader(average: avg, count: reviews.length);
                  }
                  final review = reviews[index - 1];
                  return _ReviewCard(
                    review: review,
                    onReact: (isLike) => _react(context, ref, review, isLike),
                    onDelete: review.isMine ? () => _delete(context, ref, review) : null,
                    onReply: (mention) => _openReply(context, ref, review, mention),
                    onDeleteReply: (replyId) => _deleteReply(context, ref, review.id, replyId),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Yorumlar yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _react(BuildContext context, WidgetRef ref, ReviewResponse review, bool isLike) async {
    try {
      await ref.read(reviewRepositoryProvider).react(reviewId: review.id, isLike: isLike);
      ref.invalidate(restaurantReviewsProvider(restaurantId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İşlem başarısız: ${_friendly(error)}')));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ReviewResponse review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu sil'),
        content: const Text('Bu yorumu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(reviewRepositoryProvider).deleteReview(review.id);
      ref.invalidate(restaurantReviewsProvider(restaurantId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silinemedi: ${_friendly(error)}')));
      }
    }
  }

  Future<void> _openReply(BuildContext context, WidgetRef ref, ReviewResponse review, String? mentionName) async {
    final controller = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDark.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDark.radiusModuleLg))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mentionName != null ? '@$mentionName kişisine yanıt' : 'Yoruma yanıt',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(color: AppDark.textPrimary, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: AppDark.textPrimary),
                decoration: InputDecoration(
                  hintText: mentionName != null ? '@$mentionName ...' : 'Yanıtını yaz...',
                  filled: true,
                  fillColor: AppDark.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDark.radiusControl), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppDark.accent, foregroundColor: const Color(0xFF1A1206), minimumSize: const Size.fromHeight(48)),
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Yanıtla', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (sent != true) return;
    final comment = controller.text.trim();
    if (comment.isEmpty) return;
    try {
      await ref.read(reviewRepositoryProvider).addReply(reviewId: review.id, comment: comment, mentionedUserName: mentionName);
      ref.invalidate(restaurantReviewsProvider(restaurantId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yanıt gönderilemedi: ${_friendly(error)}')));
      }
    }
  }

  Future<void> _deleteReply(BuildContext context, WidgetRef ref, String reviewId, String replyId) async {
    try {
      await ref.read(reviewRepositoryProvider).deleteReply(reviewId: reviewId, replyId: replyId);
      ref.invalidate(restaurantReviewsProvider(restaurantId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yanıt silinemedi: ${_friendly(error)}')));
      }
    }
  }

  Future<void> _openComposer(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDark.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDark.radiusModuleLg)),
      ),
      builder: (context) => _ReviewComposer(restaurantId: restaurantId, restaurantName: restaurantName),
    );
    if (created == true) {
      ref.invalidate(restaurantReviewsProvider(restaurantId));
    }
  }

  String _friendly(Object error) {
    if (error is ApiException) {
      final match = RegExp(r'"(?:errors|message|detail|title)"\s*:\s*(?:\[\s*)?"([^"]+)"').firstMatch(error.message);
      if (match != null) return match.group(1)!;
      if (error.statusCode == 401) return 'Bu işlem için giriş yapmalısınız.';
    }
    return 'Bağlantı hatası.';
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppDark.surfaceCard(),
      child: Row(
        children: [
          Text(average.toStringAsFixed(1), style: const TextStyle(color: AppDark.accentBright, fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StarRow(rating: average.round()),
              const SizedBox(height: 4),
              Text('$count değerlendirme', style: const TextStyle(color: AppDark.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onReact,
    required this.onReply,
    required this.onDeleteReply,
    this.onDelete,
  });

  final ReviewResponse review;
  final void Function(bool isLike) onReact;
  final void Function(String? mentionName) onReply;
  final void Function(String replyId) onDeleteReply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDark.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppDark.accent.withValues(alpha: 0.2),
                child: Text(
                  review.userName.isEmpty ? '?' : review.userName.characters.first.toUpperCase(),
                  style: const TextStyle(color: AppDark.accentBright, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isEmpty ? 'Misafir' : review.userName,
                      style: const TextStyle(color: AppDark.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    _StarRow(rating: review.rating, size: 14),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppDark.textSecondary, size: 20),
                  tooltip: 'Sil',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment, style: const TextStyle(color: AppDark.textPrimary, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ReactionButton(
                icon: review.likedByMe ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                label: '${review.likeCount}',
                active: review.likedByMe,
                onTap: () => onReact(true),
              ),
              const SizedBox(width: 10),
              _ReactionButton(
                icon: review.dislikedByMe ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                label: '${review.dislikeCount}',
                active: review.dislikedByMe,
                onTap: () => onReact(false),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => onReply(review.userName.isEmpty ? null : review.userName),
                style: TextButton.styleFrom(foregroundColor: AppDark.textSecondary, padding: const EdgeInsets.symmetric(horizontal: 8)),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Yanıtla'),
              ),
              const Spacer(),
              Text(_formatDate(review.createdAt), style: const TextStyle(color: AppDark.textSecondary, fontSize: 12)),
            ],
          ),
          if (review.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppDark.hairline, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in review.replies)
                    _ReplyRow(
                      reply: reply,
                      onReply: () => onReply(reply.userName.isEmpty ? null : reply.userName),
                      onDelete: reply.isMine ? () => onDeleteReply(reply.id) : null,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }
}

/// Bir yorumun altındaki tek yanıt satırı. @ ile etiketlenen kişi vurgulanır.
class _ReplyRow extends StatelessWidget {
  const _ReplyRow({required this.reply, required this.onReply, this.onDelete});

  final ReviewReplyResponse reply;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                reply.userName.isEmpty ? 'Misafir' : reply.userName,
                style: const TextStyle(color: AppDark.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onReply,
                child: const Icon(Icons.reply_rounded, size: 15, color: AppDark.textSecondary),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline, size: 15, color: AppDark.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                if (reply.mentionedUserName != null && reply.mentionedUserName!.isNotEmpty)
                  TextSpan(
                    text: '@${reply.mentionedUserName} ',
                    style: const TextStyle(color: AppDark.accentBright, fontWeight: FontWeight.w700),
                  ),
                TextSpan(text: reply.comment, style: const TextStyle(color: AppDark.textPrimary, height: 1.35)),
              ],
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppDark.accentBright : AppDark.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppDark.accent.withValues(alpha: 0.16) : AppDark.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppDark.accent.withValues(alpha: 0.5) : AppDark.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, this.size = 18});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppDark.accentBright,
        );
      }),
    );
  }
}

/// Yorum ekleme alt sayfası. Kullanıcı **önce mekanın filigranlı fotoğrafını
/// çekmek zorunda**; ancak ondan sonra puan/metin alanları ve gönderme aktif olur.
/// Çekilen görsel sosyal medyaya (LinkedIn / Instagram / WhatsApp) paylaşılabilir.
class _ReviewComposer extends ConsumerStatefulWidget {
  const _ReviewComposer({required this.restaurantId, required this.restaurantName});

  final String restaurantId;
  final String restaurantName;

  @override
  ConsumerState<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends ConsumerState<_ReviewComposer> {
  final _controller = TextEditingController();
  int _rating = 5;
  bool _saving = false;
  File? _photo; // filigran gömülmüş fotoğraf

  bool get _hasPhoto => _photo != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final profile = ref.read(myProfileProvider).valueOrNull;
    final userName = (profile?.name.isNotEmpty ?? false) ? profile!.name : 'Misafir';

    final result = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => WatermarkCameraScreen(
          restaurantName: widget.restaurantName,
          userName: userName,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      setState(() => _photo = result);
    }
  }

  Future<void> _share() async {
    final photo = _photo;
    if (photo == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(photo.path, mimeType: 'image/png')],
          text: '${widget.restaurantName} • Şükran ile değerlendirdim',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paylaşım açılamadı.')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce mekanın fotoğrafını çekmelisin.')));
      return;
    }
    final comment = _controller.text.trim();
    if (comment.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorum en az 3 karakter olmalı.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(reviewRepositoryProvider).createReview(
            restaurantId: widget.restaurantId,
            comment: comment,
            rating: _rating,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException && error.statusCode == 401
            ? 'Yorum yapmak için giriş yapmalısınız.'
            : 'Yorum gönderilemedi.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Değerlendir', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppDark.textPrimary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _PhotoGate(photo: _photo, onTake: _takePhoto, onShare: _share),
            const SizedBox(height: 16),
            // Puan ve metin yalnızca fotoğraf çekildikten sonra aktif.
            IgnorePointer(
              ignoring: !_hasPhoto,
              child: Opacity(
                opacity: _hasPhoto ? 1 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < _rating;
                        return IconButton(
                          onPressed: () => setState(() => _rating = i + 1),
                          icon: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 38,
                            color: AppDark.accentBright,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      maxLength: 1000,
                      style: const TextStyle(color: AppDark.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Deneyimini paylaş...',
                        filled: true,
                        fillColor: AppDark.inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDark.radiusControl), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppDark.accent, foregroundColor: const Color(0xFF1A1206), minimumSize: const Size.fromHeight(52)),
                onPressed: (_saving || !_hasPhoto) ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1206)))
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Gönderiliyor...' : 'Yorumu Gönder', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zorunlu fotoğraf adımı: çekilmemişse uyarı + "Fotoğraf Çek"; çekilmişse
/// filigranlı önizleme + paylaş / yeniden çek.
class _PhotoGate extends StatelessWidget {
  const _PhotoGate({required this.photo, required this.onTake, required this.onShare});

  final File? photo;
  final VoidCallback onTake;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppDark.inputFill,
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          border: Border.all(color: AppDark.hairline),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_a_photo_outlined, color: AppDark.accentBright, size: 32),
            const SizedBox(height: 10),
            const Text(
              'Yorum yapabilmek için önce mekanın fotoğrafını çekmen gerekiyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppDark.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fotoğrafa Şükran adı, mekan ve adın filigran olarak eklenir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppDark.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppDark.accent, foregroundColor: const Color(0xFF1A1206)),
              onPressed: onTake,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Fotoğraf Çek', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          child: Image.file(photo!, height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTake,
                style: OutlinedButton.styleFrom(foregroundColor: AppDark.accentBright, side: BorderSide(color: AppDark.accent.withValues(alpha: 0.5))),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Yeniden Çek'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onShare,
                style: FilledButton.styleFrom(backgroundColor: AppDark.surfaceHigh, foregroundColor: AppDark.accentBright),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Paylaş'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'LinkedIn, Instagram hikaye/gönderi veya WhatsApp durumu olarak paylaşabilirsin.',
          style: TextStyle(color: AppDark.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
