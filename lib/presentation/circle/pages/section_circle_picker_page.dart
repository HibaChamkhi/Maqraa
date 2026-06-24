import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';

/// A reusable hub for sections that are scoped to a single circle
/// (schedule, exams, reports, announcements). It lists the teacher's circles
/// and opens [pageBuilder] for the chosen circle — keeping per-circle data
/// strictly separated.
class SectionCirclePickerPage extends StatefulWidget {
  final String title;
  final IconData icon;

  /// Builds the per-circle destination for the tapped circle.
  final Widget Function(Circle circle) pageBuilder;

  const SectionCirclePickerPage({
    super.key,
    required this.title,
    required this.icon,
    required this.pageBuilder,
  });

  @override
  State<SectionCirclePickerPage> createState() =>
      _SectionCirclePickerPageState();
}

class _SectionCirclePickerPageState extends State<SectionCirclePickerPage> {
  late final Future<List<Circle>> _future =
      getIt<CircleRepository>().getMyCircles();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false, title: Text(widget.title)),
      body: FutureBuilder<List<Circle>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final circles = snap.data ?? [];
          if (circles.isEmpty) {
            return _Empty(icon: widget.icon, title: widget.title);
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('اختاري الحلقة',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final c in circles)
                _CircleTile(
                  circle: c,
                  icon: widget.icon,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => widget.pageBuilder(c)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CircleTile extends StatelessWidget {
  final Circle circle;
  final IconData icon;
  final VoidCallback onTap;
  const _CircleTile(
      {required this.circle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle =
        '${circle.gender.arabicLabel} · ${circle.privacy.arabicLabel}';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(circle.name, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  const _Empty({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('لا توجد حلقات بعد',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('أنشئي حلقة أولًا لعرض «$title».',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
