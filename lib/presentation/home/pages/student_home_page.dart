import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../core/util/session_occurrences.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/achievement/models/achievement.dart';
import '../../../domain/achievement/repositories/achievement_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/homework/models/weekly_homework.dart';
import '../../../domain/progress/models/progress_info.dart';
import '../../../domain/progress/repositories/progress_repository.dart';
import '../../../domain/schedule/repositories/schedule_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../../domain/task/models/daily_task.dart';
import '../../../domain/task/repositories/task_repository.dart';
import '../../achievement/pages/achievement_page.dart';
import '../../progress/pages/my_progress_page.dart';
import '../../session/pages/student_session_page.dart';
import '../../reminder/pages/reminder_settings_page.dart';
import '../../task/pages/today_task_page.dart';

const Color _green = AppColors.primary;
const Color _gold = Color(0xFFE0A93B);

/// All data the student dashboard shows, fetched once per load.
typedef _HomeData = ({
  ProgressInfo progress,
  String todayRange,
  bool taskDone,
  SessionOccurrence? nextSession,
  List<SessionOccurrence> upcoming,
  List<_WeekSession> weekSessions,
  Achievement achievement,
  List<_WajibItem> wajibToday,
});

/// One session occurrence in the current week, tagged with its حلقة (for the
/// aggregated «جدول الأسبوع» card).
class _WeekSession {
  final SessionOccurrence occ;
  final String circle;
  const _WeekSession(this.occ, this.circle);
}

/// One حلقة's واجب for today (from the homework plan, the teacher's source).
class _WajibItem {
  final String circleId;
  final String circleName;
  final DayPlan plan;
  final bool done;
  const _WajibItem(this.circleId, this.circleName, this.plan, this.done);
}

class StudentHomeTab extends StatefulWidget {
  final AppUser user;
  final Circle circle;
  const StudentHomeTab({super.key, required this.user, required this.circle});

  @override
  State<StudentHomeTab> createState() => StudentHomeTabState();
}

class StudentHomeTabState extends State<StudentHomeTab> {
  late Future<_HomeData> _future;

  /// Optimistic overlay for today's واجب ticks, keyed by circleId.
  final Map<String, bool> _wajibOverride = {};

  HomeworkRepository get _hw =>
      HomeworkRepository(getIt<FirebaseFirestore>(), getIt<FirebaseAuth>());

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final id = widget.circle.id;
    final uid = widget.user.uid;
    final now = DateTime.now();
    final dateId = _ymd(now);

    final progress = await getIt<ProgressRepository>().getMyProgress();

    DailyTask? task;
    try {
      task = await getIt<TaskRepository>()
          .getTaskForDay(circleId: id, dateId: dateId, uid: uid);
    } catch (_) {/* task optional */}

    String range = task?.range ?? '';
    if (range.isEmpty) {
      try {
        final saturday = now.subtract(Duration(days: now.weekday % 7));
        final schedule = await getIt<ScheduleRepository>()
            .getSchedule(circleId: id, weekId: _ymd(saturday));
        range = schedule?.days[_todayCode()] ?? '';
      } catch (_) {/* schedule optional */}
    }

    List<Session> sessions = const [];
    try {
      sessions = await getIt<SessionRepository>().getSessions(id);
    } catch (_) {/* sessions optional */}
    Map<String, ({String type, String? time})> exc = const {};
    try {
      exc = await getIt<CircleRepository>().getScheduleExceptions(id);
    } catch (_) {}
    final occ = buildSessionOccurrences(
      circle: widget.circle,
      from: DateTime(now.year, now.month, now.day),
      to: now.add(const Duration(days: 30)),
      exceptions: exc,
      docs: sessions,
    );
    final upcoming = occ.where((o) => o.at.isAfter(now)).toList();

    Achievement ach = const Achievement();
    try {
      ach = await getIt<AchievementRepository>().getAchievement();
    } catch (_) {/* achievements optional */}

    // Across ALL her halaqat: today's واجبات (homework plan) + this week's
    // sessions (rule + exceptions + docs), each tagged with its حلقة.
    final wajibToday = <_WajibItem>[];
    final weekSessions = <_WeekSession>[];
    final ws = WeeklyHomework.weekStartOf(now);
    final weekEnd = ws.add(const Duration(days: 6));
    final wid = _ymd(ws);
    final code = _todayCode();
    try {
      final circles = await getIt<CircleRepository>().getMyCircles();
      for (final c in circles) {
        try {
          final wk = await _hw.weekStream(c.id, wid, ws).first;
          final plan = wk.planOf(code);
          if (!plan.isEmpty) {
            final comp = await _hw.myCompletion(c.id, wid);
            wajibToday.add(_WajibItem(c.id, c.name, plan, comp.isDone(code)));
          }
        } catch (_) {/* skip this circle */}
        try {
          final ss = await getIt<SessionRepository>().getSessions(c.id);
          Map<String, ({String type, String? time})> cExc = const {};
          try {
            cExc = await getIt<CircleRepository>().getScheduleExceptions(c.id);
          } catch (_) {}
          final occs = buildSessionOccurrences(
            circle: c,
            from: ws,
            to: weekEnd,
            exceptions: cExc,
            docs: ss,
          );
          for (final o in occs) {
            weekSessions.add(_WeekSession(o, c.name));
          }
        } catch (_) {/* skip this circle */}
      }
    } catch (_) {/* circles optional */}
    weekSessions.sort((a, b) => a.occ.at.compareTo(b.occ.at));

    return (
      progress: progress,
      todayRange: range,
      taskDone: task?.status == TaskStatus.done,
      nextSession: upcoming.isEmpty ? null : upcoming.first,
      upcoming: upcoming,
      weekSessions: weekSessions,
      achievement: ach,
      wajibToday: wajibToday,
    );
  }

  Future<void> _toggleWajib(_WajibItem item) async {
    final cur = _wajibOverride[item.circleId] ?? item.done;
    setState(() => _wajibOverride[item.circleId] = !cur);
    var ok = true;
    try {
      await _hw.setDayDone(
        circleId: item.circleId,
        weekId: _ymd(WeeklyHomework.weekStartOf(DateTime.now())),
        dayCode: _todayCode(),
        done: !cur,
        studentName: widget.user.name,
      );
    } catch (_) {
      ok = false;
      if (mounted) setState(() => _wajibOverride[item.circleId] = cur);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: ok
            ? (!cur ? AppColors.success : AppColors.textMuted)
            : AppColors.error,
        content: Text(ok
            ? (!cur ? 'تم تسجيل التسليم — ستراه المعلّمة' : 'أُلغي التسليم')
            : 'تعذّر حفظ التسليم، حاولي مجددًا'),
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _wajibOverride.clear();
        _future = _load();
      }),
      child: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          return LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 860;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                child: wide ? _wide(d) : _narrow(d),
              );
            },
          );
        },
      ),
    );
  }

  // ── layouts ────────────────────────────────────────────────

  Widget _wide(_HomeData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _progressCard(d.progress)),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _todayCard(d)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _remindersCard(d.upcoming)),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _weekCard(d.weekSessions)),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _nextSessionCard(d.nextSession)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _achievementsCard(d.achievement),
      ],
    );
  }

  Widget _narrow(_HomeData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _todayCard(d),
        const SizedBox(height: 14),
        _progressCard(d.progress),
        const SizedBox(height: 14),
        _nextSessionCard(d.nextSession),
        const SizedBox(height: 14),
        _weekCard(d.weekSessions),
        const SizedBox(height: 14),
        _remindersCard(d.upcoming),
        const SizedBox(height: 14),
        _achievementsCard(d.achievement),
      ],
    );
  }

  // ── header ─────────────────────────────────────────────────

  // ── واجب اليوم ─────────────────────────────────────────────

  Widget _todayCard(_HomeData d) {
    final now = DateTime.now();
    final items = d.wajibToday;
    final doneCount = items
        .where((it) => _wajibOverride[it.circleId] ?? it.done)
        .length;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/quran_icon.png',
                  width: 64, height: 64, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('واجبات اليوم',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        const Spacer(),
                        if (items.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: _green,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('$doneCount / ${items.length} مكتمل',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('EEEE d MMMM yyyy', 'ar').format(now)} م'
                      '${_hijri(now).isEmpty ? '' : '  •  ${_hijri(now)}'}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty) ...[
            const Text('لا يوجد تكليف لهذا اليوم',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 12),
            _pillButton(
              label: d.taskDone ? 'تم الحفظ' : 'سجّلي الحفظ',
              icon: d.taskDone ? Icons.check_circle : Icons.menu_book_rounded,
              onTap: () => _open(
                  TodayTaskPage(circleId: widget.circle.id, user: widget.user)),
            ),
          ] else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppColors.border),
              _wajibRow(items[i]),
            ],
        ],
      ),
    );
  }

  Widget _wajibRow(_WajibItem item) {
    final done = _wajibOverride[item.circleId] ?? item.done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleWajib(item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: done ? AppColors.success : _green, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 17, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('حلقة ${item.circleName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                    ),
                    if (item.plan.type.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.sky,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(item.plan.type,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(item.plan.wajib.isNotEmpty ? item.plan.wajib : 'واجب اليوم',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted)),
                if (item.plan.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('ملاحظة: ${item.plan.notes}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── تقدّمي العام ───────────────────────────────────────────

  Widget _progressCard(ProgressInfo p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressRing(
                value: p.ratio,
                size: 86,
                stroke: 9,
                center: Text('${p.percent}%',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تقدّمي العام',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 6),
                    const Text('أنتِ على الطريق الصحيح',
                        style:
                            TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text('${p.pagesDone} من ${p.totalPages} صفحة',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _open(const MyProgressPage()),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, foregroundColor: _green),
              child: const Text('عرض التفاصيل',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── الجلسة القادمة ─────────────────────────────────────────

  Widget _nextSessionCard(SessionOccurrence? s) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الجلسة القادمة',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          Center(
            child: Image.asset('assets/images/calendar_icon.png',
                width: 92, height: 92, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Text(
            s != null && (s.title?.trim().isNotEmpty ?? false)
                ? s.title!.trim()
                : 'حلقة ${widget.circle.name}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink),
          ),
          const SizedBox(height: 3),
          Text(
            s == null
                ? 'لا توجد جلسة قادمة'
                : '${_dayLabel(s.at)} • ${DateFormat('h:mm a', 'ar').format(s.at)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _open(StudentSessionPage(
                  circleId: widget.circle.id, user: widget.user)),
              icon: const Icon(Icons.videocam_outlined, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: BorderSide(color: _green.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('انضمام للجلسة',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── جدول الأسبوع ───────────────────────────────────────────

  Widget _weekCard(List<_WeekSession> week) {
    final now = DateTime.now();
    final saturday = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(7, (i) => saturday.add(Duration(days: i)));
    final daysWithSession = week.map((w) => _ymd(w.occ.at)).toSet();
    final todays = week.where((w) => _sameDay(w.occ.at, now)).toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جدول الأسبوع',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days)
                _dayChip(day, _sameDay(day, now),
                    daysWithSession.contains(_ymd(day))),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          if (todays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('لا جلسات مجدولة اليوم',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            for (final w in todays) _scheduleRow(w),
        ],
      ),
    );
  }

  Widget _dayChip(DateTime day, bool today, bool hasSession) {
    return Column(
      children: [
        Text(DateFormat('EEEE', 'ar').format(day),
            style: TextStyle(
                fontSize: 11,
                color: today ? _green : AppColors.textMuted,
                fontWeight: today ? FontWeight.w700 : FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: today ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${day.day}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: today ? Colors.white : AppColors.ink)),
        ),
        const SizedBox(height: 4),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: hasSession
                ? (today ? _green : AppColors.pink)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _scheduleRow(_WeekSession w) {
    final t = w.occ.title?.trim() ?? '';
    final label = t.isEmpty ? 'حلقة ${w.circle}' : '$t — حلقة ${w.circle}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: w.occ.isLive ? AppColors.error : _green,
                  shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
          ),
          Text(
              w.occ.isLive
                  ? 'مباشرة'
                  : DateFormat('h:mm a', 'ar').format(w.occ.at),
              style: TextStyle(
                  fontSize: 12.5,
                  color: w.occ.isLive ? AppColors.error : AppColors.textMuted)),
        ],
      ),
    );
  }

  // ── التذكيرات ──────────────────────────────────────────────

  Widget _remindersCard(List<SessionOccurrence> upcoming) {
    final items = upcoming.take(3).toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('التذكيرات',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const Spacer(),
              TextButton(
                onPressed: () => _open(const ReminderSettingsPage()),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    foregroundColor: _green),
                child: const Text('عرض الكل',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('لا تذكيرات قادمة',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            for (final s in items) _reminderRow(s),
        ],
      ),
    );
  }

  Widget _reminderRow(SessionOccurrence s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 19, color: _green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((s.title?.trim().isEmpty ?? true) ? 'جلسة' : s.title!.trim(),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                Text(
                  '${_dayLabel(s.at)} • ${DateFormat('h:mm a', 'ar').format(s.at)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── إنجازات حديثة ──────────────────────────────────────────

  Widget _achievementsCard(Achievement ach) {
    final earned = ach.badges
        .map((k) => Badge.fromKey(k))
        .whereType<Badge>()
        .toList()
      ..sort((a, b) => b.threshold.compareTo(a.threshold));
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('إنجازات حديثة',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const Spacer(),
              if (ach.streakCount > 0)
                Text('🔥 ${ach.streakCount} يوم متتالي',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _gold)),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _open(const AchievementPage()),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    foregroundColor: _green),
                child: const Text('عرض الكل',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (earned.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('أكملي واجباتك لتكسبي أوسمتك الأولى',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final b in earned) _badgeChip(b)],
            ),
        ],
      ),
    );
  }

  Widget _badgeChip(Badge b) {
    final sub = b == Badge.starter
        ? 'أول واجب مكتمل'
        : '${_arDigits('${b.threshold}')} يوم متتالي';
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded,
                color: _gold, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.arabicLabel,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── shared bits ────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _pillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: filled ? AppColors.success : _green,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────

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

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'اليوم';
    if (_sameDay(d, now.add(const Duration(days: 1)))) return 'غدًا';
    return DateFormat('EEEE d MMM', 'ar').format(d);
  }
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _hijri(DateTime now) {
  try {
    HijriCalendar.setLocal('ar');
    final h = HijriCalendar.now();
    return '${_arDigits(h.toFormat("dd MMMM yyyy"))} هـ';
  } catch (_) {
    return '';
  }
}

String _arDigits(String s) {
  const w = '0123456789';
  const a = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = w.indexOf(ch);
    b.write(i == -1 ? ch : a[i]);
  }
  return b.toString();
}
