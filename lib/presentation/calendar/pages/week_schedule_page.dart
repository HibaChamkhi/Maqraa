import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/task/models/daily_task.dart';
import '../../../domain/task/repositories/task_repository.dart';
import '../../circle/pages/section_circle_picker_page.dart';
import 'manage_calendar_page.dart';

/// الجدول الأسبوعي والجلسات — a global weekly timetable that aggregates the
/// sessions of every circle the teacher runs, colour-coded per circle, with a
/// «جلسة اليوم» card and a today's-tasks reminders panel.
class WeekSchedulePage extends StatefulWidget {
  final AppUser user;
  const WeekSchedulePage({super.key, required this.user});

  @override
  State<WeekSchedulePage> createState() => _WeekSchedulePageState();
}

// ----- palette assigned per circle -----
const _palette = <(Color, Color)>[
  (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
  (Color(0xFFD6EEF1), Color(0xFF0F766E)),
  (Color(0xFFFAEEDA), Color(0xFF854F0B)),
  (Color(0xFFEDE9FB), Color(0xFF534AB7)),
  (Color(0xFFE6F1FB), Color(0xFF0C447C)),
  (Color(0xFFFBEAF0), Color(0xFF993556)),
];

class _Ev {
  final Session session;
  final String circleName;
  final int colorIndex;
  _Ev(this.session, this.circleName, this.colorIndex);
}

typedef _Reminder = ({String title, String subtitle});

class _Data {
  final List<Circle> circles;
  final List<_Ev> events;
  final List<_Reminder> reminders;
  _Data(this.circles, this.events, this.reminders);
}

class _WeekSchedulePageState extends State<WeekSchedulePage> {
  static const int _startHour = 7;
  static const int _endHour = 18;
  static const double _rowH = 56;

  late DateTime _weekStart = _sundayOf(DateTime.now());
  bool _listView = false;
  late Future<_Data> _future = _load();

  DateTime _sundayOf(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.subtract(Duration(days: midnight.weekday % 7));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<_Data> _load() async {
    final circleRepo = getIt<CircleRepository>();
    final calRepo = getIt<CalendarRepository>();
    final taskRepo = getIt<TaskRepository>();
    final circles = await circleRepo.getMyCircles();
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final events = <_Ev>[];
    final reminders = <_Reminder>[];
    for (var i = 0; i < circles.length; i++) {
      final c = circles[i];
      final color = i % _palette.length;
      final sessions = await calRepo.getSessions(c.id);
      for (final s in sessions) {
        events.add(_Ev(s, c.name, color));
      }
      try {
        final tasks = await taskRepo.getTasksForDay(circleId: c.id, dateId: todayId);
        for (final DailyTask t in tasks) {
          reminders.add((
            title: 'تسميع ${t.name}',
            subtitle: t.range.isEmpty ? c.name : '${t.range} · ${c.name}',
          ));
        }
      } catch (_) {/* circle may have no tasks yet */}
    }
    return _Data(circles, events, reminders);
  }

  void _reload() => setState(() => _future = _load());

  void _shiftWeek(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.user.role == UserRole.teacher ||
        widget.user.role == UserRole.supervisor;
    return Scaffold(
      appBar: AppBar(title: const Text('الجدول الأسبوعي والجلسات')),
      body: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          final days = [for (var i = 0; i < 7; i++) _weekStart.add(Duration(days: i))];
          final weekEvents = d.events
              .where((e) => !e.session.scheduledAt.isBefore(days.first) &&
                  e.session.scheduledAt.isBefore(days.last.add(const Duration(days: 1))))
              .toList();

          return LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;
            final main = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Toolbar(
                  weekStart: _weekStart,
                  listView: _listView,
                  isTeacher: isTeacher,
                  onPrev: () => _shiftWeek(-1),
                  onNext: () => _shiftWeek(1),
                  onToggle: (v) => setState(() => _listView = v),
                  onNew: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (_) => SectionCirclePickerPage(
                          title: 'جلسة جديدة',
                          icon: Icons.calendar_month_outlined,
                          pageBuilder: (circle) => ManageCalendarPage(
                              circleId: circle.id, user: widget.user),
                        ),
                      ))
                      .then((_) => _reload()),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _listView
                      ? _AgendaList(days: days, events: weekEvents)
                      : _WeekGrid(
                          days: days,
                          events: weekEvents,
                          startHour: _startHour,
                          endHour: _endHour,
                          rowH: _rowH,
                          sameDay: _sameDay,
                        ),
                ),
              ],
            );

            if (!wide) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: main,
              );
            }
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: main),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 300,
                    child: ListView(
                      children: [
                        _TodaySessionCard(
                            events: d.events, sameDay: _sameDay),
                        const SizedBox(height: AppSpacing.md),
                        _RemindersCard(reminders: d.reminders),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }
}

// ===================== toolbar =====================
class _Toolbar extends StatelessWidget {
  final DateTime weekStart;
  final bool listView;
  final bool isTeacher;
  final VoidCallback onPrev, onNext, onNew;
  final ValueChanged<bool> onToggle;
  const _Toolbar({
    required this.weekStart,
    required this.listView,
    required this.isTeacher,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final end = weekStart.add(const Duration(days: 6));
    final fmtDay = DateFormat('d', 'ar');
    final fmtMonthY = DateFormat('MMMM y', 'ar');
    final range = '${fmtDay.format(weekStart)} - ${fmtDay.format(end)} ${fmtMonthY.format(end)}';
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        _ViewToggle(listView: listView, onToggle: onToggle),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: onPrev, icon: const Icon(Icons.chevron_right)),
            Text(range, style: Theme.of(context).textTheme.titleMedium),
            IconButton(
                onPressed: onNext, icon: const Icon(Icons.chevron_left)),
          ],
        ),
        if (isTeacher)
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('جلسة جديدة'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16)),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool listView;
  final ValueChanged<bool> onToggle;
  const _ViewToggle({required this.listView, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, IconData icon, bool isList) {
      final active = listView == isList;
      return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => onToggle(isList),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 16,
                color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('قائمة', Icons.view_list_outlined, true),
        seg('تقويم', Icons.calendar_month_outlined, false),
      ]),
    );
  }
}

// ===================== week grid =====================
class _WeekGrid extends StatelessWidget {
  final List<DateTime> days;
  final List<_Ev> events;
  final int startHour, endHour;
  final double rowH;
  final bool Function(DateTime, DateTime) sameDay;
  const _WeekGrid({
    required this.days,
    required this.events,
    required this.startHour,
    required this.endHour,
    required this.rowH,
    required this.sameDay,
  });

  @override
  Widget build(BuildContext context) {
    const gutter = 48.0;
    final slots = endHour - startHour;
    final dayNames = DateFormat('EEEE', 'ar');
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F1F2937), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // header row
          Row(
            children: [
              const SizedBox(width: gutter),
              for (final d in days)
                Expanded(
                  child: _DayHeader(
                    name: dayNames.format(d),
                    day: d.day,
                    isToday: sameDay(d, today),
                  ),
                ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: slots * rowH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // time gutter
                    SizedBox(
                      width: gutter,
                      child: Column(
                        children: [
                          for (var h = startHour; h < endHour; h++)
                            SizedBox(
                              height: rowH,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2, right: 4),
                                child: Text(
                                  '${h.toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final d in days)
                      Expanded(
                        child: _DayColumn(
                          day: d,
                          events: events
                              .where((e) =>
                                  sameDay(e.session.scheduledAt, d))
                              .toList(),
                          startHour: startHour,
                          slots: slots,
                          rowH: rowH,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String name;
  final int day;
  final bool isToday;
  const _DayHeader(
      {required this.name, required this.day, required this.isToday});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text('$day',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final List<_Ev> events;
  final int startHour, slots;
  final double rowH;
  const _DayColumn({
    required this.day,
    required this.events,
    required this.startHour,
    required this.slots,
    required this.rowH,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border, width: .5)),
      ),
      child: Stack(
        children: [
          // hour lines
          Column(
            children: [
              for (var i = 0; i < slots; i++)
                Container(
                  height: rowH,
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: AppColors.border, width: .5)),
                  ),
                ),
            ],
          ),
          for (final e in events) _block(context, e),
        ],
      ),
    );
  }

  Widget _block(BuildContext context, _Ev e) {
    final start = e.session.scheduledAt;
    final end = start.add(const Duration(hours: 1)); // default 1h
    final minutesFromTop = (start.hour - startHour) * 60 + start.minute;
    final top = (minutesFromTop / 60) * rowH;
    final height = rowH - 4;
    final (bg, fg) = _palette[e.colorIndex];
    final fmt = DateFormat('HH:mm');
    return Positioned(
      top: top.clamp(0, slots * rowH).toDouble(),
      left: 3,
      right: 3,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.circleName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${fmt.format(start)} - ${fmt.format(end)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9, color: fg)),
                    ),
                    Icon(Icons.videocam_outlined, size: 12, color: fg),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== agenda (list view) =====================
class _AgendaList extends StatelessWidget {
  final List<DateTime> days;
  final List<_Ev> events;
  const _AgendaList({required this.days, required this.events});

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmtHeader = DateFormat('EEEE d MMMM', 'ar');
    final fmt = DateFormat('HH:mm');
    final sections = <Widget>[];
    for (final d in days) {
      final dayEvents = events
          .where((e) => _sameDay(e.session.scheduledAt, d))
          .toList()
        ..sort((a, b) => a.session.scheduledAt.compareTo(b.session.scheduledAt));
      if (dayEvents.isEmpty) continue;
      sections.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(fmtHeader.format(d), style: theme.textTheme.titleSmall),
      ));
      for (final e in dayEvents) {
        final (bg, fg) = _palette[e.colorIndex];
        sections.add(Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(Icons.videocam_outlined, color: fg),
            ),
            title: Text(e.circleName, style: theme.textTheme.titleSmall),
            subtitle: Text(
                '${fmt.format(e.session.scheduledAt)} - ${fmt.format(e.session.scheduledAt.add(const Duration(hours: 1)))} · ${e.session.title}'),
          ),
        ));
      }
    }
    if (sections.isEmpty) {
      return Center(
        child: Text('لا توجد جلسات هذا الأسبوع',
            style: theme.textTheme.bodyMedium),
      );
    }
    return ListView(children: sections);
  }
}

// ===================== side cards =====================
class _TodaySessionCard extends StatelessWidget {
  final List<_Ev> events;
  final bool Function(DateTime, DateTime) sameDay;
  const _TodaySessionCard({required this.events, required this.sameDay});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todays = events
        .where((e) => sameDay(e.session.scheduledAt, now))
        .toList()
      ..sort((a, b) => a.session.scheduledAt.compareTo(b.session.scheduledAt));
    final fmt = DateFormat('h:mm a', 'ar');

    final live = todays.where((e) => e.session.status == SessionStatus.live);
    final pick = live.isNotEmpty
        ? live.first
        : (todays.isNotEmpty ? todays.first : null);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F6B5B), Color(0xFF09463A)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جلسة اليوم',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          if (pick == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('لا توجد جلسة اليوم',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
            )
          else ...[
            Text(pick.circleName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                '${fmt.format(pick.session.scheduledAt)} - ${fmt.format(pick.session.scheduledAt.add(const Duration(hours: 1)))}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(pick.session.status.arabicLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('جلسة ${pick.circleName}')),
                ),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('انضمام للقاء'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemindersCard extends StatelessWidget {
  final List<_Reminder> reminders;
  const _RemindersCard({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = reminders.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F1F2937), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التذكيرات', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('لا توجد تذكيرات اليوم',
                  style: theme.textTheme.bodySmall),
            )
          else
            for (final r in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_none,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: theme.textTheme.titleSmall),
                          Text(r.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () {}, child: const Text('عرض كل التذكيرات')),
          ),
        ],
      ),
    );
  }
}
