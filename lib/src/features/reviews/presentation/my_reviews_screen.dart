import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dark.dart';
import '../data/review_repository.dart';

/// Oturum açan kullanıcının yaptığı tüm yorumlar.
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yorumlarım')),
      body: AppDark.scaffoldBackground(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myReviewsProvider),
          child: reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.rate_review_outlined, size: 56, color: AppDark.textSecondary),
                    SizedBox(height: 12),
                    Center(child: Text('Henüz yorum yapmadınız.', style: TextStyle(color: AppDark.textSecondary))),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: AppDark.surfaceCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 16,
                                  color: AppDark.accentBright,
                                );
                              }),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _delete(context, ref, review.id),
                              icon: const Icon(Icons.delete_outline, color: AppDark.textSecondary, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(review.comment, style: const TextStyle(color: AppDark.textPrimary, height: 1.4)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up_outlined, size: 14, color: AppDark.textSecondary),
                            const SizedBox(width: 4),
                            Text('${review.likeCount}', style: const TextStyle(color: AppDark.textSecondary, fontSize: 12)),
                            const SizedBox(width: 14),
                            const Icon(Icons.thumb_down_outlined, size: 14, color: AppDark.textSecondary),
                            const SizedBox(width: 4),
                            Text('${review.dislikeCount}', style: const TextStyle(color: AppDark.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary))),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String reviewId) async {
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
      await ref.read(reviewRepositoryProvider).deleteReview(reviewId);
      ref.invalidate(myReviewsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silinemedi.')));
      }
    }
  }
}
