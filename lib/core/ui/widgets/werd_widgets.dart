import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../styles/theme.dart';

/// Circular progress ring with a centred label — the signature «وِرد» element
/// (e.g. the 75% / 62% memorization rings in the mockups).
class ProgressRing extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final double stroke;
  final Widget? center;
  final Color? color;
  final Color? trackColor;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 140,
    this.stroke = 12,
    this.center,
    this.color,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0, 1),
          color: c,
          track: trackColor ?? AppColors.sky,
          stroke: stroke,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, base);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// A small section title with optional trailing action (e.g. "عرض الكل").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// KPI / stat card used across the dashboards (count + label + icon chip).
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? accent;
  final String? delta;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.accent,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = accent ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineSmall),
          Text(label, style: theme.textTheme.bodySmall),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Text(delta!,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}

/// Status pill (e.g. حاضر / غياب / قيد التلاوة).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// Streak chip with a flame icon (سلسلة الالتزام).
class StreakBadge extends StatelessWidget {
  final int days;
  const StreakBadge({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.warning, size: 18),
          const SizedBox(width: 6),
          Text('$days يوم متتالية',
              style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Circular achievement / badge medallion.
class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
