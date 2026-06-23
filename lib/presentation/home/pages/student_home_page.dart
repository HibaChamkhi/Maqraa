import 'package:flutter/material.dart' hide Badge;
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/achievement/models/achievement.dart';
import '../../../domain/achievement/repositories/achievement_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/progress/models/progress_info.dart';
import '../../../domain/progress/repositories/progress_repository.dart';
import '../../../domain/schedule/repositories/schedule_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../../domain/task/models/daily_task.dart';
import '../../../domain/task/repositories/task_repository.dart';
import '../../achievement/pages/achievement_page.dart';
import '../../circle/pages/circles_list_page.dart';
import '../../notification/pages/notifications_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../progress/pages/my_progress_page.dart';
import '../../reminder/pages/reminder_settings_page.dart';
import '../../task/pages/today_task_page.dart';

const Color _green = AppColors.primary;
const Color _gold = Color(0xFFE0A93B);

/// All data the student dashboard shows, fetched once per load.
typedef _HomeData = ({
  ProgressInfo progress,
  String todayRange,
  bool taskDone,
  Session? nextSession,
  List<Session> upcoming,
  List<Session> todaySessions,
  Achievement achievement,
});

class StudentHomeTab extends StatefulWidget {
  final AppUser user;
  final Circle circle;
  const StudentHomeTab({super.key, required this.user, required this.circle});

  @override
  State<StudentHomeTab> createState() => StudentHomeTabState();
}

class StudentHomeTabState extends State<StudentHomeTab> {
  late Future<_HomeData> _future;

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
    final upcoming = sessions
        .where((s) =>
            s.scheduledAt.isAfter(now) && s.status != SessionStatus.ended)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final todaySessions = sessions
        .where((s) => _sameDay(s.scheduledAt, now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    Achievement ach = const Achievement();
    try {
      ach = await getIt<AchievementRepository>().getAchievement();
    } catch (_) {/* achievements optional */}

    return (
      progress: progress,
      todayRange: range,
      taskDone: task?.status == TaskStatus.done,
      nextSession: upcoming.isEmpty ? null : upcoming.first,
      upcoming: upcoming,
      todaySessions: todaySessions,
      achievement: ach,
    );
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
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
        _header(),
        const SizedBox(height: 18),
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
              Expanded(flex: 4, child: _weekCard(d.todaySessions)),
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
        _header(),
        const SizedBox(height: 16),
        _todayCard(d),
        const SizedBox(height: 14),
        _progressCard(d.progress),
        const SizedBox(height: 14),
        _nextSessionCard(d.nextSession),
        const SizedBox(height: 14),
        _weekCard(d.todaySessions),
        const SizedBox(height: 14),
        _remindersCard(d.upcoming),
        const SizedBox(height: 14),
        _achievementsCard(d.achievement),
      ],
    );
  }

  // ── header ─────────────────────────────────────────────────

  Widget _header() {
    final u = widget.user;
    return Row(
      children: [
        GestureDetector(
          onTap: () => _open(const ProfilePage()),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.sky,
            backgroundImage:
                u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
            child: u.photoUrl == null
                ? const Icon(Icons.person, color: _green)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u.name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const Text('طالبة',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
        const Spacer(),
        const Text('الرئيسية',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
      ],
    );
  }

  // ── واجب اليوم ─────────────────────────────────────────────

  Widget _todayCard(_HomeData d) {
    final parts = _splitRange(d.todayRange);
    final has = d.todayRange.trim().isNotEmpty;
    final now = DateTime.now();
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/quran_icon.png',
              width: 104, height: 104, fit: BoxFit.contain),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('واجب اليوم',
                    style:
                        TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text(has ? parts.$1 : 'لا يوجد تكليف لهذا اليوم',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                if (has && parts.$2.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('من الآية ${parts.$2}',
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textMuted)),
                ],
                const SizedBox(height: 6),
                Text(
                  '${DateFormat('EEEE d MMMM yyyy', 'ar').format(now)} م'
                  '${_hijri(now).isEmpty ? '' : '  •  ${_hijri(now)}'}',
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                _pillButton(
                  label: d.taskDone ? 'تم الحفظ' : 'سجّلي الحفظ',
                  icon: d.taskDone
                      ? Icons.check_circle
                      : Icons.menu_book_rounded,
                  onTap: () => _open(
                      TodayTaskPage(circleId: widget.circle.id, user: widget.user)),
                ),
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

  Widget _nextSessionCard(Session? s) {
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
            s != null && s.title.trim().isNotEmpty
                ? s.title.trim()
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
                : '${_dayLabel(s.scheduledAt)} • ${DateFormat('h:mm a', 'ar').format(s.scheduledAt)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _open(const CirclesListPage()),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: BorderSide(color: _green.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('عرض الحلقة',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── جدول الأسبوع ───────────────────────────────────────────

  Widget _weekCard(List<Session> todaySessions) {
    final now = DateTime.now();
    final saturday = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(7, (i) => saturday.add(Duration(days: i)));
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
              for (final day in days) _dayChip(day, _sameDay(day, now)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          if (todaySessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('لا أنشطة مجدولة اليوم',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            for (final s in todaySessions) _scheduleRow(s),
        ],
      ),
    );
  }

  Widget _dayChip(DateTime day, bool today) {
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
      ],
    );
  }

  Widget _scheduleRow(Session s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: _green, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(s.title.trim().isEmpty ? 'جلسة' : s.title.trim(),
                style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
          ),
          Text(DateFormat('h:mm a', 'ar').format(s.scheduledAt),
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ── التذكيرات ──────────────────────────────────────────────

  Widget _remindersCard(List<Session> upcoming) {
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

  Widget _reminderRow(Session s) {
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
                Text(s.title.trim().isEmpty ? 'جلسة' : s.title.trim(),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                Text(
                  '${_dayLabel(s.scheduledAt)} • ${DateFormat('h:mm a', 'ar').format(s.scheduledAt)}',
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
  }) {
    return Material(
      color: _green,
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

/// Splits «سورة الملك ١-١٠» into (surah, ayahRange) best-effort.
(String, String) _splitRange(String raw) {
  final r = raw.trim();
  if (r.isEmpty) return ('', '');
  final m = RegExp(r'([\d٠-٩][\d٠-٩\s\-–—,]*)$').firstMatch(r);
  if (m != null) {
    final ayah = m.group(0)!.trim();
    final surah = r.substring(0, m.start).trim();
    if (surah.isNotEmpty) return (surah, _arDigits(ayah).replaceAll('-', ' إلى '));
  }
  return (r, '');
}

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
