import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:worthwatch/theme.dart';

/// A visual bar that represents how much of the user's total monthly working time
/// a purchase consumes.
///
/// - [consumedMinutes]: Minutes of work required for the current purchase.
/// - [monthlyMinutes]: Total working minutes in the user's month.
class MonthlyTimeConsumptionBar extends StatelessWidget {
  const MonthlyTimeConsumptionBar({
    super.key,
    required this.consumedMinutes,
    required this.monthlyMinutes,
    this.title,
    this.rangeLabel,
    this.startCaption,
    this.endCaption,
  });

  final int consumedMinutes;
  final int monthlyMinutes;
  final String? title;
  final String? rangeLabel;
  final String? startCaption;
  final String? endCaption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final safeMonthly = math.max(0, monthlyMinutes);
    final safeConsumed = math.max(0, consumedMinutes);
    final pct = safeMonthly == 0 ? 0.0 : (safeConsumed / safeMonthly).clamp(0.0, 1.0);

    final totalMonthlyHours = safeMonthly / 60.0;
    final pctLabel = (pct * 100).toStringAsFixed(1);

    final resolvedTitle = title ?? 'This purchase consumes $pctLabel% of your work month';
    final resolvedRangeLabel = rangeLabel ?? '0h → ${totalMonthlyHours.toStringAsFixed(totalMonthlyHours >= 100 ? 0 : 1)}h';
    final resolvedStartCaption = startCaption ?? 'Start';
    final resolvedEndCaption = endCaption ?? 'End of month';

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timelapse_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  resolvedTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            resolvedRangeLabel,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: AppSpacing.md),
          _GradientProgressBar(value: pct),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(resolvedStartCaption, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
              Text(resolvedEndCaption, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundGradient = LinearGradient(
      colors: [
        theme.colorScheme.tertiary.withValues(alpha: 0.22),
        theme.colorScheme.secondary.withValues(alpha: 0.22),
        theme.colorScheme.error.withValues(alpha: 0.22),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final activeGradient = LinearGradient(
      colors: [
        theme.colorScheme.tertiary,
        theme.colorScheme.secondary,
        theme.colorScheme.error,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = 14.0;
        final radius = BorderRadius.circular(999);
        final clamped = value.clamp(0.0, 1.0);
        final activeWidth = constraints.maxWidth * clamped;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: h,
              decoration: BoxDecoration(
                gradient: backgroundGradient,
                borderRadius: radius,
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.10)),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              height: h,
              width: activeWidth,
              decoration: BoxDecoration(
                gradient: activeGradient,
                borderRadius: radius,
              ),
            ),
            if (clamped > 0)
              Positioned(
                left: math.max(0, activeWidth - 8),
                top: (h / 2) - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: theme.colorScheme.onSurface, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
