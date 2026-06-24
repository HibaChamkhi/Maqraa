import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/util/session_occurrences.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/homework/models/weekly_homework.dart';
import '../../../domain/session/repositories/session_repository.dart';
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

  Future<void> _joinCircle(AppUser user) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => JoinCirclePage(user: user)));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    final isTeacher = user?.role == UserRole.teacher;
    final isManager = user != null &&
        (user.role == UserRole.teacher || user.role == UserRole.supervisor);

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
              if (isManager) ...[
                _KpiStrip(
                  circles: stats.length,
                  students: totalStudents,
                  avg: overallAvg,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
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
                      isManager
                          ? _CircleCard(stat: s, user: user)
                          : _StudentCircleCard(
                              circle: s.circle, count: s.count, user: user!),
                    if (isTeacher) _AddCircleTile(onTap: _createCircle),
                    if (!isManager && user != null)
                      _JoinCircleTile(onTap: () => _joinCircle(user)),
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

String _todayDayCode() {
  const map = {
    DateTime.saturday: 'sat',
    DateTime.sunday: 'sun',
    DateTime.monday: 'mon',
    DateTime.tuesday: 'tue',
    DateTime.wednesday: 'wed',
    DateTime.thursday: 'thu',
    DateTime.friday: 'fri',
  };
  return map[DateTime.now().weekday] ?? 'sat';
}

/// Student card: her حلقة info only — name, teacher, tags, student count,
/// next session, and today's واجب status. No memorization stats.
class _StudentCircleCard extends StatelessWidget {
  final Circle circle;
  final int count;
  final AppUser user;
  const _StudentCircleCard(
      {required this.circle, required this.count, required this.user});

  Future<({DateTime? next, int wajib})> _load() async {
    DateTime? next;
    try {
      final ss = await getIt<SessionRepository>().getSessions(circle.id);
      Map<String, ({String type, String? time})> exc = const {};
      try {
        exc = await getIt<CircleRepository>().getScheduleExceptions(circle.id);
      } catch (_) {}
      final now = DateTime.now();
      final occ = buildSessionOccurrences(
        circle: circle,
        from: now,
        to: now.add(const Duration(days: 60)),
        exceptions: exc,
        docs: ss,
      ).where((o) => o.at.isAfter(now)).toList();
      next = occ.isEmpty ? null : occ.first.at;
    } catch (_) {/* sessions optional */}

    var wajib = 0; // 0 = none today · 1 = done · 2 = pending
    try {
      final hw =
          HomeworkRepository(getIt<FirebaseFirestore>(), getIt<FirebaseAuth>());
      final ws = WeeklyHomework.weekStartOf(DateTime.now());
      final wid = DateFormat('yyyy-MM-dd').format(ws);
      final today = _todayDayCode();
      final wk = await hw.weekStream(circle.id, wid, ws).first;
      if (!wk.planOf(today).isEmpty) {
        final comp = await hw.myCompletion(circle.id, wid);
        wajib = comp.isDone(today) ? 1 : 2;
      }
    } catch (_) {/* homework optional */}
    return (next: next, wajib: wajib);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = circle.name.isNotEmpty ? circle.name.characters.first : '؟';
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
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StudentCirclePage(circle: circle, user: user),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(circle.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium),
                          if (circle.teacherName.isNotEmpty)
                            Text('المعلّمة: ${circle.teacherName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
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
                      label: circle.gender == Gender.female ? 'بنات' : 'بنين',
                      bg: AppColors.pink.withValues(alpha: 0.14),
                      fg: AppColors.warning,
                    ),
                    _Pill(
                      label: circle.privacy.arabicLabel,
                      bg: AppColors.gray,
                      fg: AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _infoRow(Icons.people_outline, '$count طالبات'),
                const SizedBox(height: 8),
                FutureBuilder<({DateTime? next, int wajib})>(
                  future: _load(),
                  builder: (context, snap) {
                    final data = snap.data;
                    final next = data?.next;
                    final wajib = data?.wajib ?? 0;
                    final sessionText = data == null
                        ? '…'
                        : next == null
                            ? 'لا توجد جلسة قادمة'
                            : '${DateFormat('EEEE', 'ar').format(next)} • ${DateFormat('h:mm a', 'ar').format(next)}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.event_outlined,
                            'الجلسة القادمة: $sessionText'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.menu_book_outlined,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text('واجب اليوم:',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.ink)),
                            const SizedBox(width: 6),
                            _wajibPill(wajib, data == null),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.ink)),
          ),
        ],
      );

  Widget _wajibPill(int wajib, bool loading) {
    String t;
    Color bg, fg;
    if (loading) {
      t = '…';
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    } else if (wajib == 1) {
      t = 'تم التسليم';
      bg = const Color(0xFFE1F5EE);
      fg = const Color(0xFF0F6E56);
    } else if (wajib == 2) {
      t = 'بانتظار التسليم';
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    } else {
      t = 'لا واجب اليوم';
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(fontSize: 11, color: fg)),
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

/// Dashed-style "join a circle by code" tile (student only).
class _JoinCircleTile extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinCircleTile({required this.onTap});

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
              const Icon(Icons.vpn_key_outlined,
                  size: 30, color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('الانضمام برمز دعوة',
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
