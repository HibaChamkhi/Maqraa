import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/announcement/models/announcement.dart';
import '../../../domain/announcement/repositories/announcement_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/task/models/daily_task.dart';
import '../../../domain/task/repositories/task_repository.dart';

const Color _green = AppColors.primary;

/// الرئيسية — teacher overview dashboard.
class TeacherOverviewPage extends StatefulWidget {
  final AppUser user;
  final List<Circle> circles;
  const TeacherOverviewPage(
      {super.key, required this.user, required this.circles});

  @override
  State<TeacherOverviewPage> createState() => _TeacherOverviewPageState();
}

typedef _Delivery = ({String name, String circle, String range, String date, int state});
typedef _Upcoming = ({String circle, DateTime at});
typedef _Note = ({String text, String sub, DateTime? at});

class _Data {
  final int activeStudents, totalStudents, attendancePct, joinRequests, activeExams;
  final List<_Delivery> delivery;
  final Map<String, int> grades; // label -> count
  final List<_Upcoming> upcoming;
  final List<_Note> announcements;
  _Data(this.activeStudents, this.totalStudents, this.attendancePct,
      this.joinRequests, this.activeExams, this.delivery, this.grades,
      this.upcoming, this.announcements);
}

class _TeacherOverviewPageState extends State<TeacherOverviewPage> {
  late final Future<_Data> _future = _load();

  Future<_Data> _load() async {
    final circleRepo = getIt<CircleRepository>();
    final calRepo = getIt<CalendarRepository>();
    final examRepo = getIt<ExamRepository>();
    final taskRepo = getIt<TaskRepository>();
    final noteRepo = getIt<AnnouncementRepository>();
    final circles = widget.circles;
    final now = DateTime.now();
    final todayId = _ymd(now);
    final sat = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));
    final weekIds = [for (var i = 0; i < 7; i++) _ymd(sat.add(Duration(days: i)))];

    Future<T> guard<T>(Future<T> Function() f, T fallback) async {
      try {
        return await f();
      } catch (_) {
        return fallback;
      }
    }

    // --- per-circle parallel reads ---
    final members = await Future.wait(circles.map(
        (c) => guard(() => circleRepo.getMembers(c.id), <CircleMember>[])));
    final pending = await Future.wait(circles.map(
        (c) => guard(() => circleRepo.getPendingRequests(c.id), <CircleMember>[])));
    final sessions = await Future.wait(circles.map(
        (c) => guard(() => calRepo.getSessions(c.id), <Session>[])));
    final exams = await Future.wait(circles.map(
        (c) => guard(() => examRepo.getExams(c.id), <Exam>[])));
    final tasks = await Future.wait(circles.map(
        (c) => guard(() => taskRepo.getTasksForDay(circleId: c.id, dateId: todayId),
            <DailyTask>[])));
    final notes = await Future.wait(circles.map(
        (c) => guard(() => noteRepo.getAnnouncements(c.id), <Announcement>[])));
    final attendance = await Future.wait(circles.map((c) => guard(
        () => circleRepo.getWeekAttendance(circleId: c.id, dateIds: weekIds),
        <String, Map<String, AttendanceState>>{})));

    // --- KPIs ---
    var active = 0, total = 0, joinRequests = 0, activeExams = 0;
    var present = 0, marked = 0;
    for (var i = 0; i < circles.length; i++) {
      final students = members[i]
          .where((m) => m.role == UserRole.student)
          .toList();
      total += students.length;
      active += students.where((m) => m.status == MemberStatus.active).length;
      joinRequests += pending[i].length;
      activeExams += exams[i]
          .where((e) => !e.date.isBefore(DateTime(now.year, now.month, now.day)))
          .length;
      for (final byUid in attendance[i].values) {
        for (final st in byUid.values) {
          marked++;
          if (st == AttendanceState.present) present++;
        }
      }
    }
    final attendancePct = marked == 0 ? 0 : (present * 100 / marked).round();

    // --- delivery tracking (today) ---
    final delivery = <_Delivery>[];
    for (var i = 0; i < circles.length; i++) {
      for (final t in tasks[i]) {
        final state = t.status == TaskStatus.done
            ? 0
            : t.awaitingConfirmation
                ? 1
                : 2;
        delivery.add((
          name: t.name,
          circle: circles[i].name,
          range: t.range,
          date: t.dateId,
          state: state,
        ));
      }
    }

    // --- exam analysis (results of completed exams) ---
    final grades = <String, int>{};
    final past = <({String circleId, Exam exam})>[];
    for (var i = 0; i < circles.length; i++) {
      for (final e in exams[i]) {
        if (e.date.isBefore(now)) past.add((circleId: circles[i].id, exam: e));
      }
    }
    past.sort((a, b) => b.exam.date.compareTo(a.exam.date));
    for (final p in past.take(10)) {
      final results = await guard(
          () => examRepo.getResults(circleId: p.circleId, examId: p.exam.id),
          <ExamResult>[]);
      for (final r in results) {
        if (r.attendance != ExamAttendance.present) continue;
        final label = examGradeLabel(r.score, p.exam.totalMarks);
        if (label.isEmpty) continue;
        grades[label] = (grades[label] ?? 0) + 1;
      }
    }

    // --- upcoming sessions ---
    final upcoming = <_Upcoming>[];
    for (var i = 0; i < circles.length; i++) {
      for (final s in sessions[i]) {
        if (s.scheduledAt.isAfter(now) && s.status != SessionStatus.ended) {
          upcoming.add((circle: circles[i].name, at: s.scheduledAt));
        }
      }
    }
    upcoming.sort((a, b) => a.at.compareTo(b.at));

    // --- announcements ---
    final ann = <_Note>[];
    for (var i = 0; i < circles.length; i++) {
      for (final n in notes[i]) {
        ann.add((text: n.text, sub: circles[i].name, at: n.createdAt));
      }
    }
    ann.sort((a, b) =>
        (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));

    return _Data(active, total, attendancePct, joinRequests, activeExams,
        delivery, grades, upcoming, ann);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Data>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 860;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _kpis(d, wide),
                  const SizedBox(height: 16),
                  _DeliveryCard(rows: d.delivery),
                  const SizedBox(height: 16),
                  if (wide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _AnnouncementsCard(notes: d.announcements)),
                          const SizedBox(width: 16),
                          Expanded(child: _UpcomingCard(items: d.upcoming)),
                          const SizedBox(width: 16),
                          Expanded(child: _AnalysisCard(grades: d.grades)),
                        ],
                      ),
                    )
                  else ...[
                    _AnalysisCard(grades: d.grades),
                    const SizedBox(height: 16),
                    _UpcomingCard(items: d.upcoming),
                    const SizedBox(height: 16),
                    _AnnouncementsCard(notes: d.announcements),
                  ],
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _kpis(_Data d, bool wide) {
    final tiles = [
      _Kpi(icon: Icons.groups_2_outlined, value: '${d.activeStudents}', sub: 'من ${d.totalStudents} طالبة', label: 'الطالبات النشطات'),
      _Kpi(icon: Icons.verified_outlined, value: '${d.attendancePct}%', sub: 'هذا الأسبوع', label: 'نسبة الحضور'),
      _Kpi(icon: Icons.person_add_alt, value: '${d.joinRequests}', sub: 'طلب جديد', label: 'طلبات الانضمام'),
      _Kpi(icon: Icons.assignment_outlined, value: '${d.activeExams}', sub: 'اختبار نشط', label: 'الاختبارات'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 4 : 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      mainAxisExtent: 122,
      children: tiles,
    );
  }
}

// ── KPI tile ──────────────────────────────────────────────

class _Kpi extends StatelessWidget {
  final IconData icon;
  final String value, sub, label;
  const _Kpi({required this.icon, required this.value, required this.sub, required this.label});

  @override
  Widget build(BuildContext context) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 17, color: _green),
              ),
            ],
          ),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── متابعة التسليم ────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  final List<_Delivery> rows;
  const _DeliveryCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('متابعة التسليم',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('لا تسليمات اليوم',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            )
          else
            for (final r in rows.take(8)) _row(r),
        ],
      ),
    );
  }

  Widget _row(_Delivery r) {
    const labels = ['تم التسليم', 'في المراجعة', 'لم يتم التسليم'];
    const colors = [AppColors.success, AppColors.warning, AppColors.error];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.sky,
              child: Icon(Icons.person, size: 17, color: _green)),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                Text(r.circle,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(r.range.isEmpty ? '—' : r.range,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors[r.state].withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(labels[r.state],
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors[r.state])),
          ),
        ],
      ),
    );
  }
}

// ── تحليل الاختبارات (donut) ──────────────────────────────

class _AnalysisCard extends StatelessWidget {
  final Map<String, int> grades;
  const _AnalysisCard({required this.grades});

  static const _order = ['ممتاز', 'جيد جدًا', 'جيد', 'مقبول', 'راسب'];
  static const _colors = {
    'ممتاز': AppColors.success,
    'جيد جدًا': AppColors.teal,
    'جيد': Color(0xFF6FBF73),
    'مقبول': AppColors.warning,
    'راسب': AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final total = grades.values.fold<int>(0, (a, b) => a + b);
    final entries = [
      for (final k in _order)
        if ((grades[k] ?? 0) > 0)
          (label: k, count: grades[k]!, color: _colors[k]!),
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحليل الاختبارات',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('لا نتائج اختبارات بعد',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        centerSpaceRadius: 36,
                        sectionsSpace: 2,
                        sections: [
                          for (final e in entries)
                            PieChartSectionData(
                                value: e.count.toDouble(),
                                color: e.color,
                                showTitle: false,
                                radius: 18),
                        ],
                      )),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$total',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          const Text('نتيجة',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                      color: e.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(e.label,
                                      style: const TextStyle(
                                          fontSize: 12.5, color: AppColors.ink))),
                              Text('${(e.count * 100 / total).round()}%',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── الجدول القادم ─────────────────────────────────────────

class _UpcomingCard extends StatelessWidget {
  final List<_Upcoming> items;
  const _UpcomingCard({required this.items});

  String _when(DateTime d) {
    final now = DateTime.now();
    final t = DateFormat('h:mm a', 'ar').format(d);
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'اليوم • $t';
    }
    if (d.difference(DateTime(now.year, now.month, now.day)).inDays == 1) {
      return 'غدًا • $t';
    }
    return '${DateFormat('EEEE', 'ar').format(d)} • $t';
  }

  @override
  Widget build(BuildContext context) {
    final list = items.take(3).toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الجدول القادم',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('لا جلسات قادمة',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            for (final s in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.event_note_outlined,
                          size: 18, color: _green),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.circle,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                          Text(_when(s.at),
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ── الإعلانات ─────────────────────────────────────────────

class _AnnouncementsCard extends StatelessWidget {
  final List<_Note> notes;
  const _AnnouncementsCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final list = notes.take(3).toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإعلانات',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('لا إعلانات',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            for (final n in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.campaign_outlined,
                          size: 18, color: AppColors.warning),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                          Text(
                            n.at == null
                                ? n.sub
                                : '${n.sub} • ${DateFormat('d MMM', 'ar').format(n.at!)}',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ── shared card ───────────────────────────────────────────

Widget _card({required Widget child, EdgeInsets? padding}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
      ],
    ),
    child: child,
  );
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
