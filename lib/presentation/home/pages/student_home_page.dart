import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../../../domain/homework/models/weekly_homework.dart';
import '../../../domain/progress/models/progress_info.dart';
import '../../../domain/progress/repositories/progress_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../exam/pages/student_exams_page.dart';
import '../../notification/pages/notifications_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../progress/pages/my_progress_page.dart';
import '../../session/pages/student_session_page.dart';
import '../../task/pages/today_task_page.dart';

// ---------------------------------------------------------------------------
//  Aggregated data across ALL of the student's halaqat.
// ---------------------------------------------------------------------------

/// One halaqa's status for today: its plan, whether it's done, the partner.
class _HalaqaToday {
  final Circle circle;
  final DayPlan? plan; // null = no واجب today
  final bool done;
  final String partner;
  final DateTime? doneAt;
  const _HalaqaToday(this.circle, this.plan, this.done, this.partner,
      [this.doneAt]);
}

class _SessionItem {
  final Circle circle;
  final Session session;
  const _SessionItem(this.circle, this.session);
}

class _ExamItem {
  final Circle circle;
  final Exam exam;
  final ExamResult? myResult;
  const _ExamItem(this.circle, this.exam, this.myResult);
  bool get upcoming => exam.date.isAfter(DateTime.now());
}

class _HomeAgg {
  final List<_HalaqaToday> halaqat;
  final List<_SessionItem> sessions;
  final List<_ExamItem> exams;
  final ProgressInfo? progress;
  const _HomeAgg(this.halaqat, this.sessions, this.exams, this.progress);

  int get wajibTotal => halaqat.where((h) => h.plan != null).length;
  int get wajibDone =>
      halaqat.where((h) => h.plan != null && h.done).length;
}

class StudentHomeTab extends StatefulWidget {
  final AppUser user;
  final Circle circle; // entry circle (kept for compatibility)
  const StudentHomeTab({super.key, required this.user, required this.circle});

  @override
  State<StudentHomeTab> createState() => StudentHomeTabState();
}

class StudentHomeTabState extends State<StudentHomeTab> {
  late Future<_HomeAgg> _future;

  HomeworkRepository get _hw =>
      HomeworkRepository(getIt<FirebaseFirestore>(), getIt<FirebaseAuth>());

  DateTime get _weekStart => WeeklyHomework.weekStartOf(DateTime.now());
  String get _weekId => DateFormat('yyyy-MM-dd').format(_weekStart);

  String _todayCode() {
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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeAgg> _load() async {
    final circles = await getIt<CircleRepository>().getMyCircles();
    final now = DateTime.now();
    final weekStart = _weekStart;
    final weekId = _weekId;
    final today = _todayCode();

    final halaqat = <_HalaqaToday>[];
    final sessions = <_SessionItem>[];
    final exams = <_ExamItem>[];

    for (final c in circles) {
      // --- today's واجب + my completion ---
      DayPlan? plan;
      var done = false;
      var partner = '';
      try {
        final wk = await _hw.weekStream(c.id, weekId, weekStart).first;
        final p = wk.planOf(today);
        if (!p.isEmpty) plan = p;
        final comp = await _hw.myCompletion(c.id, weekId);
        done = comp.isDone(today);
        partner = comp.partners[today] ?? '';
      } catch (_) {/* homework optional */}
      halaqat.add(_HalaqaToday(c, plan, done, partner));

      // --- upcoming / live sessions ---
      try {
        final ss = await getIt<SessionRepository>().getSessions(c.id);
        for (final s in ss) {
          final live = s.status == SessionStatus.live;
          final upcoming =
              s.scheduledAt.isAfter(now) && s.status != SessionStatus.ended;
          if (live || upcoming) sessions.add(_SessionItem(c, s));
        }
      } catch (_) {/* sessions optional */}

      // --- nearby exams (upcoming, or recent with my published result) ---
      try {
        final ex = await getIt<ExamRepository>().getExams(c.id);
        for (final e in ex) {
          if (e.date.isAfter(now)) {
            exams.add(_ExamItem(c, e, null));
          } else if (e.resultsPublished) {
            final r = await getIt<ExamRepository>()
                .getMyResult(circleId: c.id, examId: e.id);
            exams.add(_ExamItem(c, e, r));
          }
        }
      } catch (_) {/* exams optional */}
    }

    sessions.sort((a, b) => a.session.scheduledAt.compareTo(b.session.scheduledAt));
    // upcoming exams first (soonest), then recent results (latest first)
    exams.sort((a, b) {
      if (a.upcoming != b.upcoming) return a.upcoming ? -1 : 1;
      return a.upcoming
          ? a.exam.date.compareTo(b.exam.date)
          : b.exam.date.compareTo(a.exam.date);
    });

    ProgressInfo? progress;
    try {
      progress = await getIt<ProgressRepository>().getMyProgress();
    } catch (_) {/* progress optional */}

    return _HomeAgg(halaqat, sessions.take(4).toList(),
        exams.take(4).toList(), progress);
  }

  Future<void> _toggleWajib(_HalaqaToday h) async {
    final markDone = !h.done;
    var ok = true;
    try {
      await _hw.setDayDone(
        circleId: h.circle.id,
        weekId: _weekId,
        dayCode: _todayCode(),
        done: markDone,
        studentName: widget.user.name,
        partnerName: h.partner.isEmpty ? null : h.partner,
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: ok
            ? (markDone ? AppColors.success : AppColors.textMuted)
            : AppColors.error,
        content: Text(ok
            ? (markDone
                ? 'تم تسجيل التسليم — ستراه المعلّمة'
                : 'أُلغي التسليم')
            : 'تعذّر حفظ التسليم، حاولي مجددًا'),
      ),
    );
    setState(() => _future = _load());
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: FutureBuilder<_HomeAgg>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          return LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;

            final wajibCard = _cardShell(
              title: 'واجبات اليوم',
              icon: Icons.menu_book_rounded,
              trailing: d.wajibTotal > 0 ? _donePill(d) : null,
              child: _wajibContent(d),
            );
            final sessionsCard = _cardShell(
              title: 'جلساتك القادمة',
              icon: Icons.event_available_outlined,
              child: _sessionsContent(d),
            );
            final examsCard = _cardShell(
              title: 'اختبارات قريبة',
              icon: Icons.assignment_turned_in_outlined,
              child: _examsContent(d),
            );

            final Widget body = wide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: wajibCard),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: sessionsCard),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: examsCard),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      wajibCard,
                      const SizedBox(height: AppSpacing.md),
                      sessionsCard,
                      const SizedBox(height: AppSpacing.md),
                      examsCard,
                    ],
                  );

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _Header(
                    user: widget.user,
                    circleCount: d.halaqat.length,
                    onProfile: () => _open(const ProfilePage())),
                const SizedBox(height: AppSpacing.md),
                _statsRow(d, wide),
                const SizedBox(height: AppSpacing.md),
                body,
              ],
            );
          });
        },
      ),
    );
  }

  // ------------------------------------------------------------- stats row
  Widget _statsRow(_HomeAgg d, bool wide) {
    final liveOrSoon = d.sessions.length;
    final examsCount = d.exams.where((e) => e.upcoming).length;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 4 : 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: wide ? 2.5 : 2.3,
      children: [
        _StatTile(
          value: '${d.progress?.percent ?? 0}٪',
          label: 'تقدّمي العام',
          icon: Icons.trending_up_rounded,
          tint: AppColors.primary,
          onTap: () => _open(const MyProgressPage()),
        ),
        _StatTile(
          value: '${d.wajibDone}/${d.wajibTotal}',
          label: 'واجبات اليوم',
          icon: Icons.menu_book_rounded,
          tint: AppColors.success,
        ),
        _StatTile(
          value: '$liveOrSoon',
          label: 'جلسات قادمة',
          icon: Icons.event_available_outlined,
          tint: AppColors.primaryDark,
        ),
        _StatTile(
          value: '$examsCount',
          label: 'اختبارات قريبة',
          icon: Icons.assignment_turned_in_outlined,
          tint: AppColors.warning,
        ),
      ],
    );
  }

  Widget _donePill(_HomeAgg d) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${d.wajibDone} / ${d.wajibTotal} مكتمل',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );

  Widget _cardShell({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ]),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  // ----------------------------------------------------------- واجبات اليوم
  Widget _wajibContent(_HomeAgg d) {
    final withWajib = d.halaqat.where((h) => h.plan != null).toList();
    final without = d.halaqat.where((h) => h.plan == null).toList();
    if (withWajib.isEmpty && without.isEmpty) {
      return const _EmptyHint(text: 'لست مشتركة في أي حلقة بعد');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final h in withWajib) ...[
          _WajibCard(
            h: h,
            onToggle: () => _toggleWajib(h),
            onOpen: () =>
                _open(TodayTaskPage(circleId: h.circle.id, user: widget.user)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final h in without) ...[
          _EmptyHint(text: 'حلقة ${h.circle.name} • لا واجب لهذا اليوم'),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // -------------------------------------------------------- جلساتك القادمة
  Widget _sessionsContent(_HomeAgg d) {
    if (d.sessions.isEmpty) {
      return const _EmptyHint(text: 'لا جلسات قادمة حاليًا');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in d.sessions) ...[
          _SessionRow(
            item: s,
            onTap: () => _open(
                StudentSessionPage(circleId: s.circle.id, user: widget.user)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // -------------------------------------------------------- اختبارات قريبة
  Widget _examsContent(_HomeAgg d) {
    if (d.exams.isEmpty) {
      return const _EmptyHint(text: 'لا اختبارات قريبة');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in d.exams) ...[
          _ExamRow(
            item: e,
            onTap: () => _open(
                StudentExamsPage(circleId: e.circle.id, user: widget.user)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

// ===========================================================================
//  Widgets
// ===========================================================================

class _Header extends StatelessWidget {
  final AppUser user;
  final int circleCount;
  final VoidCallback onProfile;
  const _Header(
      {required this.user,
      required this.circleCount,
      required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfile,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.sky,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 19, color: AppColors.primary)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('السلام عليكم 👋',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Text(user.name,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
        const Spacer(),
        if (circleCount > 0)
          Text('$circleCount حلقات',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.textMuted),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WajibCard extends StatelessWidget {
  final _HalaqaToday h;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  const _WajibCard(
      {required this.h, required this.onToggle, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final plan = h.plan!;
    final done = h.done;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // checkbox
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: done ? AppColors.success : AppColors.primary,
                    width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 17, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('حلقة ${h.circle.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                      if (plan.type.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _typeChip(plan.type),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(plan.wajib.isNotEmpty ? plan.wajib : 'واجب اليوم',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textMuted)),
                  if (plan.notes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text('ملاحظة المعلّمة: ${plan.notes}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (h.partner.isNotEmpty)
                        _pill(Icons.people_alt_outlined,
                            'رفيقتي: ${h.partner}', AppColors.gray,
                            AppColors.textMuted),
                      done
                          ? _pill(Icons.check_circle, 'تم التسليم',
                              const Color(0xFFE1F5EE), const Color(0xFF0F6E56))
                          : _pill(null, 'بانتظار التسليم', AppColors.gray,
                              AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.sky,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(type,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark)),
      );

  Widget _pill(IconData? icon, String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Text(text, style: TextStyle(fontSize: 11, color: fg)),
          ],
        ),
      );
}

class _SessionRow extends StatelessWidget {
  final _SessionItem item;
  final VoidCallback onTap;
  const _SessionRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = item.session;
    final live = s.status == SessionStatus.live;
    final title = s.title.trim().isNotEmpty
        ? '${s.title.trim()} — حلقة ${item.circle.name}'
        : 'حلقة ${item.circle.name}';
    final when = live
        ? 'مباشرة الآن'
        : '${DateFormat('EEEE d MMM', 'ar').format(s.scheduledAt)} • ${DateFormat('h:mm a', 'ar').format(s.scheduledAt)}';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: live ? const Color(0xFFFCEBEB) : AppColors.sky,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(live ? Icons.podcasts_rounded : Icons.event_outlined,
                size: 20,
                color: live ? const Color(0xFFA32D2D) : AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(when,
                    style: TextStyle(
                        fontSize: 11,
                        color: live
                            ? const Color(0xFFA32D2D)
                            : AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          live
              ? FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('انضمام', style: TextStyle(fontSize: 12)),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('مجدولة',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  final _ExamItem item;
  final VoidCallback onTap;
  const _ExamRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = item.exam;
    final upcoming = item.upcoming;
    final r = item.myResult;
    String subtitle;
    Widget badge;
    Color iconBg;
    Color iconFg;
    IconData icon;
    if (upcoming) {
      subtitle =
          '${DateFormat('EEEE d MMM', 'ar').format(e.date)} • ${DateFormat('h:mm a', 'ar').format(e.date)}';
      badge = _badge('قادم', const Color(0xFFFAEEDA), const Color(0xFF854F0B));
      iconBg = const Color(0xFFFAEEDA);
      iconFg = const Color(0xFF854F0B);
      icon = Icons.assignment_outlined;
    } else if (r != null && r.attendance == ExamAttendance.present) {
      final pct = e.totalMarks == 0
          ? 0
          : (r.score / e.totalMarks * 100).round();
      subtitle = 'نتيجتك: $pct٪ — ${examGradeLabel(r.score, e.totalMarks)}';
      badge = _badge(
          'النتيجة', const Color(0xFFE1F5EE), const Color(0xFF0F6E56));
      iconBg = const Color(0xFFE1F5EE);
      iconFg = const Color(0xFF0F6E56);
      icon = Icons.check_circle_outline;
    } else {
      subtitle = 'بانتظار رصد النتيجة';
      badge = _badge('انتهى', AppColors.gray, AppColors.textMuted);
      iconBg = AppColors.gray;
      iconFg = AppColors.textMuted;
      icon = Icons.assignment_outlined;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconFg),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.title} — حلقة ${item.circle.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            badge,
          ],
        ),
      ),
    );
  }

  Widget _badge(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(fontSize: 11, color: fg)),
      );
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: tint),
                ),
                const Spacer(),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: tint)),
              ],
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.coffee_outlined,
              size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
