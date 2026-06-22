import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_dark.dart';
import '../domain/tenant.dart';

/// Kuruş (long) değerini "₺486.500" biçiminde gösterir.
String adminFormatTry(int minor) {
  final formatter = NumberFormat.decimalPattern('tr_TR');
  return '₺${formatter.format((minor / 100).round())}';
}

Color tenantStatusColor(TenantStatus status) => switch (status) {
      TenantStatus.active => AppDark.success,
      TenantStatus.pending => AppDark.accentBright,
      TenantStatus.suspended => AppDark.danger,
    };

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.status});

  final TenantStatus status;

  @override
  Widget build(BuildContext context) {
    final color = tenantStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class AdminPlanBadge extends StatelessWidget {
  const AdminPlanBadge({super.key, required this.plan});

  final TenantPlan plan;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = plan == TenantPlan.enterprise;
    final isPro = plan == TenantPlan.pro;
    final color = isEnterprise
        ? AppDark.accentBright
        : isPro
            ? AppDark.accent
            : AppDark.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppDark.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        plan.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppDark.accent,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDark.surfaceCard(radius: AppDark.radiusModule),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppDark.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppDark.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Basit responsive ızgara — verilen genişliğe göre sütun sayısını seçer.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minItemWidth = 240, this.spacing = 16});

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        var columns = (maxWidth / minItemWidth).floor();
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length.clamp(1, children.length);
        final itemWidth = (maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
