import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'create_circle_page.dart';
import 'join_circle_page.dart';
import 'qr_join_page.dart';
import 'circle_workspace_page.dart';
import 'student_circle_page.dart';

/// One circle plus its quick stats for the list cards.
typedef _CircleStat = ({Circle circle, int count, int avg});

/// الحلقات — all circles the current user belongs to, shown as a KPI summary
/// strip plus a responsive grid of rich «وِصَال» cards.
class CirclesListPage extends StatefulWidget {
  const CirclesListPage({super.key});

  @override
  State<CirclesListPage> createState() => _CirclesListPageState();
}

class _CirclesListPageState extends State<CirclesListPage> {
  late Future<List<_CircleStat>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_CircleStat>> _load() async {
    final repo = getIt<CircleRepository>();
    final circles = await repo.getMyCircles();
    return Future.wait(circles.map((c) async {
      final members = await repo.getMembers(c.id);
      final students = members
          .where((m) =>
              m.role == UserRole.student && m.status == MemberStatus.active)
          .toList();
      final count = students.length;
      final avg = students.isEmpty
          ? 0
          : (students.map((s) => s.memorizedPercent).reduce((a, b) => a + b) /
                  count)
              .round();
      return (circle: c, count: count, avg: avg);
    }));
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _createCircle() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateCirclePage()));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    final isTeacher = user?.role == UserRole.teacher;

    return Scaffold(
      appBar: AppBar(title: const Text('الحلقات')),
      body: FutureBuilder<List<_CircleStat>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snap.data ?? const [];
          if (stats.isEmpty) {
            return _empty(context, user);
          }

          final totalStudents =
              stats.fold<int>(0, (sum, s) => sum + s.count);
          final overallAvg = totalStudents == 0
              ? 0
              : (stats.fold<int>(0, (sum, s) => sum + s.avg * s.count) /
                      totalStudents)
                  .round();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _KpiStrip(
                circles: stats.length,
                students: totalStudents,
                avg: overallAvg,
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('حلقاتي (${stats.length})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w >= 1100 ? 3 : (w >= 700 ? 2 : 1);
                  const gap = AppSpacing.md;
                  final cardW = (w - gap * (cols - 1)) / cols - 0.5;
                  final tiles = <Widget>[
                    for (final s in stats)
                      _CircleCard(stat: s, user: user),
                    if (isTeacher) _AddCircleTile(onTap: _createCircle),
                  ];
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: tiles
                        .map((t) => SizedBox(width: cardW, child: t))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, AppUser? user) {
    final isTeacher = user?.role == UserRole.teacher;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: AppColors.sky,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Icon(Icons.groups_2_outlined,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(isTeacher ? 'لا توجد حلقة بعد' : 'لم تنضمّي إلى حلقة بعد',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            if (isTeacher)
              ElevatedButton.icon(
                onPressed: _createCircle,
                icon: const Icon(Icons.add),
                label: const Text('إنشاء حلقة'),
              )
            else if (user != null) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => JoinCirclePage(user: user)));
                  _reload();
                },
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('الانضمام برمز دعوة'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QrJoinPage(user: user)));
                  _reload();
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('الانضمام بمسح QR'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Top summary strip: total circles, students and overall memorization.
class _KpiStrip extends StatelessWidget {
  final int circles;
  final int students;
  final int avg;

  const _KpiStrip(
      {required this.circles, required this.students, required this.avg});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiTile(
          value: '$circles',
          label: 'الحلقات',
          filled: true,
          icon: Icons.groups_2_outlined,
        ),
        const SizedBox(width: AppSpacing.sm),
        _KpiTile(
          value: '$students',
          label: 'إجمالي الطالبات',
          icon: Icons.people_outline,
        ),
        const SizedBox(width: AppSpacing.sm),
        _KpiTile(
          value: '$avg٪',
          label: 'متوسط الحفظ',
          icon: Icons.speed_outlined,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool filled;

  const _KpiTile({
    required this.value,
    required this.label,
    required this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: filled ? AppColors.sky : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: filled ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(value,
                style: theme.textTheme.titleLarge?.copyWith(
                    color: filled ? AppColors.primaryDark : AppColors.ink,
                    fontWeight: FontWeight.w700)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  final _CircleStat stat;
  final AppUser? user;
  const _CircleCard({required this.stat, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = stat.circle;
    final initial = c.name.isNotEmpty ? c.name.characters.first : '؟';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F1F2937), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: user == null
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => c.canManage(user)
                        ? CircleWorkspacePage(circle: c, user: user!)
                        : StudentCirclePage(circle: c, user: user!),
                  )),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium),
                    ),
                    const Icon(Icons.chevron_left, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Pill(
                      label: c.gender == Gender.female ? 'بنات' : 'بنين',
                      bg: AppColors.pink.withValues(alpha: 0.14),
                      fg: AppColors.warning,
                    ),
                    _Pill(
                      label: c.privacy.arabicLabel,
                      bg: AppColors.gray,
                      fg: AppColors.textMuted,
                    ),
                    if (c.level.isNotEmpty)
                      _Pill(
                        label: c.level,
                        bg: AppColors.sky,
                        fg: AppColors.primaryDark,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _MiniStat(
                        icon: Icons.people_outline,
                        label: 'الطالبات',
                        value: '${stat.count}'),
                    const SizedBox(width: AppSpacing.sm),
                    _MiniStat(
                        icon: Icons.speed_outlined,
                        label: 'معدل الحفظ',
                        value: '${stat.avg}٪'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تقدّم الحفظ',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    Text('${stat.avg}٪',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: stat.avg / 100,
                    minHeight: 7,
                    backgroundColor: AppColors.sky,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed-style "create a circle" tile that sits in the grid (teacher only).
class _AddCircleTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCircleTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.sky.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline,
                  size: 30, color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('إنشاء حلقة جديدة',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted, fontSize: 11)),
                  Text(value,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
