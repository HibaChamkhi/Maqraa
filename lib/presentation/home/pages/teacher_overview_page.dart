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
import '../../announcement/pages/announcements_page.dart';
import '../../calendar/pages/week_schedule_page.dart';
import '../../circle/pages/all_students_page.dart';
import '../../circle/pages/circle_workspace_page.dart';
import '../../circle/pages/circles_list_page.dart';
import '../../circle/pages/section_circle_picker_page.dart';
import '../../exam/pages/teacher_exams_page.dart';

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

typedef _Upcoming = ({String circle, DateTime at});
typedef _Note = ({String text, String sub, DateTime? at});

class _Data {
  final int activeStudents, totalStudents, attendancePct;
  final int joinRequests, activeExams, deliveriesToReview;
  final List<_Upcoming> upcoming;
  final List<_Note> announcements;
  _Data({
    required this.activeStudents,
    required this.totalStudents,
    required this.attendancePct,
    required this.joinRequests,
    required this.activeExams,
    required this.deliveriesToReview,
    required this.upcoming,
    required this.announcements,
  });
}

class _TeacherOverviewPageState extends State<TeacherOverviewPage> {
  late final Future<_Data> _future = _load();

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<_Data> _load() async {
    final circleRepo = getIt<CircleRepository>();
    final calRepo = getIt<CalendarRepository>();
    final examRepo = getIt<ExamRepository>();
    final taskRepo = getIt<TaskRepository>();
    final noteRepo = getIt<AnnouncementRepository>();
    final circles = widget.circles;
    final now = DateTime.now();
    final todayId = _ymd(now);
    final today = DateTime(now.year, now.month, now.day);
    final sat = today.subtract(Duration(days: now.weekday % 7));
    final weekIds = [for (var i = 0; i < 7; i++) _ymd(sat.add(Duration(days: i)))];

    Future<T> guard<T>(Future<T> Function() f, T fallback) async {
      try {
        return await f();
      } catch (_) {
        return fallback;
      }
    }

    final members = await Future.wait(circles.map(
        (c) => guard(() => circleRepo.getMembers(c.id), <CircleMember>[])));
    final pending = await Future.wait(circles.map((c) =>
        guard(() => circleRepo.getPendingRequests(c.id), <CircleMember>[])));
    final sessions = await Future.wait(circles
        .map((c) => guard(() => calRepo.getSessions(c.id), <Session>[])));
    final exams = await Future.wait(
        circles.map((c) => guard(() => examRepo.getExams(c.id), <Exam>[])));
    final tasks = await Future.wait(circles.map((c) => guard(
        () => taskRepo.getTasksForDay(circleId: c.id, dateId: todayId),
        <DailyTask>[])));
    final notes = await Future.wait(circles.map(
        (c) => guard(() => noteRepo.getAnnouncements(c.id), <Announcement>[])));
    final attendance = await Future.wait(circles.map((c) => guard(
        () => circleRepo.getWeekAttendance(circleId: c.id, dateIds: weekIds),
        <String, Map<String, AttendanceState>>{})));

    var active = 0, total = 0, joinRequests = 0, activeExams = 0;
    var present = 0, marked = 0, deliveriesToReview = 0;
    for (var i = 0; i < circles.length; i++) {
      final students =
          members[i].where((m) => m.role == UserRole.student).toList();
      total += students.length;
      active += students.where((m) => m.status == MemberStatus.active).length;
      joinRequests += pending[i].length;
      activeExams += exams[i].where((e) => !e.date.isBefore(today)).length;
      for (final byUid in attendance[i].values) {
        for (final st in byUid.values) {
          marked++;
          if (st == AttendanceState.present) present++;
        }
      }
      for (final t in tasks[i]) {
        if (t.status != TaskStatus.done) deliveriesToReview++;
      }
    }
    final attendancePct = marked == 0 ? 0 : (present * 100 / marked).round();

    final upcoming = <_Upcoming>[];
    for (var i = 0; i < circles.length; i++) {
      for (final s in sessions[i]) {
        if (s.scheduledAt.isAfter(now) && s.status != SessionStatus.ended) {
          upcoming.add((circle: circles[i].name, at: s.scheduledAt));
        }
      }
    }
    upcoming.sort((a, b) => a.at.compareTo(b.at));

    final ann = <_Note>[];
    for (var i = 0; i < circles.length; i++) {
      for (final n in notes[i]) {
        ann.add((text: n.text, sub: circles[i].name, at: n.createdAt));
      }
    }
    ann.sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));

    return _Data(
      activeStudents: active,
      totalStudents: total,
      attendancePct: attendancePct,
      joinRequests: joinRequests,
      activeExams: activeExams,
      deliveriesToReview: deliveriesToReview,
      upcoming: upcoming,
      announcements: ann,
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'صباح الخير' : 'مساء الخير';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Data>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        final now = DateTime.now();
        final next = d.upcoming.isEmpty ? null : d.upcoming.first;
        final attention = d.joinRequests + d.deliveriesToReview;

        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 860;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(now, next, attention),
                  const SizedBox(height: 16),
                  _quickActions(d),
                  const SizedBox(height: 18),
                  if (wide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: _todayCard(next, now)),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _attentionCard(d)),
                        ],
                      ),
                    )
                  else ...[
                    _todayCard(next, now),
                    const SizedBox(height: 16),
                    _attentionCard(d),
                  ],
                  const SizedBox(height: 16),
                  _statsStrip(d, wide),
                  const SizedBox(height: 16),
                  if (wide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _circlesCard(d)),
                          const SizedBox(width: 16),
                          Expanded(child: _announcementsCard(d)),
                        ],
                      ),
                    )
                  else ...[
                    _circlesCard(d),
                    const SizedBox(height: 16),
                    _announcementsCard(d),
                  ],
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ── greeting ──────────────────────────────────────────────
  Widget _header(DateTime now, _Upcoming? next, int attention) {
    final date = DateFormat('EEEE d MMMM', 'ar').format(now);
    final bits = <String>[date];
    if (next != null && _sameDay(next.at, now)) {
      bits.add('لديك جلسة اليوم');
    }
    if (attention > 0) {
      bits.add('$attention ${attention == 1 ? 'أمر يحتاج' : 'أمور تحتاج'} انتباهك');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting، ${widget.user.name} 🌿',
            style: const TextStyle(
                fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 3),
        Text(bits.join(' · '),
            style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
      ],
    );
  }

  // ── quick actions ─────────────────────────────────────────
  Widget _quickActions(_Data d) {
    final circles = widget.circles;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionChip(
          icon: Icons.play_circle_outline,
          label: 'بدء جلسة',
          onTap: () => _push(WeekSchedulePage(user: widget.user)),
        ),
        _ActionChip(
          icon: Icons.person_add_alt,
          label: 'إضافة طالبة',
          onTap: () => _push(const CirclesListPage()),
        ),
        _ActionChip(
          icon: Icons.assignment_outlined,
          label: 'إنشاء اختبار',
          onTap: () => _push(SectionCirclePickerPage(
            title: 'الاختبارات',
            icon: Icons.assignment_outlined,
            pageBuilder: (cir) =>
                TeacherExamsPage(circleId: cir.id, user: widget.user),
          )),
        ),
        _ActionChip(
          icon: Icons.campaign_outlined,
          label: 'إعلان',
          onTap: () {
            if (circles.length == 1) {
              _push(AnnouncementsPage(
                  circleId: circles.first.id, user: widget.user));
            } else {
              _push(SectionCirclePickerPage(
                title: 'الإعلانات',
                icon: Icons.campaign_outlined,
                pageBuilder: (cir) =>
                    AnnouncementsPage(circleId: cir.id, user: widget.user),
              ));
            }
          },
        ),
      ],
    );
  }

  // ── today's session hero ──────────────────────────────────
  Widget _todayCard(_Upcoming? next, DateTime now) {
    final isToday = next != null && _sameDay(next.at, now);
    final title = next == null
        ? 'لا جلسات قادمة'
        : (isToday ? 'جلسة اليوم' : 'الجلسة القادمة');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title${next != null ? ' · حلقة ${next.circle}' : ''}',
              style: const TextStyle(
                  color: Color(0xCCFFFFFF), fontSize: 12.5)),
          const SizedBox(height: 8),
          Text(
            next == null
                ? '—'
                : DateFormat('h:mm a', 'ar').format(next.at),
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          if (next != null) ...[
            const SizedBox(height: 2),
            Text(
              isToday
                  ? 'تبدأ اليوم'
                  : DateFormat('EEEE d MMMM', 'ar').format(next.at),
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _push(WeekSchedulePage(user: widget.user)),
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: Text(next == null ? 'فتح الجدول' : 'بدء الجلسة',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ── needs attention ───────────────────────────────────────
  Widget _attentionCard(_Data d) {
    final items = <Widget>[];
    if (d.joinRequests > 0) {
      items.add(_AttentionRow(
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.primary,
        label: 'طلبات انضمام (${d.joinRequests})',
        onTap: () => _push(const CirclesListPage()),
      ));
    }
    if (d.deliveriesToReview > 0) {
      items.add(_AttentionRow(
        icon: Icons.fact_check_outlined,
        color: AppColors.warning,
        label: 'تسليمات تحتاج متابعة (${d.deliveriesToReview})',
        onTap: () => _push(AllStudentsPage(user: widget.user)),
      ));
    }
    if (d.activeExams > 0) {
      items.add(_AttentionRow(
        icon: Icons.assignment_outlined,
        color: AppColors.teal,
        label: 'اختبارات نشطة (${d.activeExams})',
        onTap: () => _push(SectionCirclePickerPage(
          title: 'الاختبارات',
          icon: Icons.assignment_outlined,
          pageBuilder: (cir) =>
              TeacherExamsPage(circleId: cir.id, user: widget.user),
        )),
      ));
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('يحتاج انتباهك',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('كل شيء على ما يرام، لا مهام عاجلة',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              items[i],
            ],
        ],
      ),
    );
  }

  // ── compact stats ─────────────────────────────────────────
  Widget _statsStrip(_Data d, bool wide) {
    final tiles = [
      _Stat(label: 'حلقاتي', value: '${widget.circles.length}'),
      _Stat(label: 'الطالبات', value: '${d.totalStudents}'),
      _Stat(label: 'حضور الأسبوع', value: '${d.attendancePct}٪'),
      _Stat(label: 'اختبارات نشطة', value: '${d.activeExams}'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: 78,
      children: tiles,
    );
  }

  // ── halaqat ───────────────────────────────────────────────
  Widget _circlesCard(_Data d) {
    String? nextOf(String name) {
      for (final u in d.upcoming) {
        if (u.circle == name) {
          final now = DateTime.now();
          final t = DateFormat('h:mm a', 'ar').format(u.at);
          if (_sameDay(u.at, now)) return 'القادمة: اليوم $t';
          return 'القادمة: ${DateFormat('EEEE', 'ar').format(u.at)} $t';
        }
      }
      return null;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('حلقاتي',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const Spacer(),
              TextButton(
                onPressed: () => _push(const CirclesListPage()),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    foregroundColor: _green),
                child: const Text('عرض الكل',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.circles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('لا حلقات بعد',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          else
            for (final ci in widget.circles)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _push(
                    CircleWorkspacePage(circle: ci, user: widget.user)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.sky,
                        child: Text(
                            ci.name.isNotEmpty ? ci.name.characters.first : '؟',
                            style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ci.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink)),
                            Text(nextOf(ci.name) ?? 'لا جلسات قادمة',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left,
                          size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ── announcements ─────────────────────────────────────────
  Widget _announcementsCard(_Data d) {
    final list = d.announcements.take(3).toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('آخر الإعلانات',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Text('لا إعلانات بعد',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {
                      final circles = widget.circles;
                      if (circles.length == 1) {
                        _push(AnnouncementsPage(
                            circleId: circles.first.id, user: widget.user));
                      } else if (circles.isNotEmpty) {
                        _push(SectionCirclePickerPage(
                          title: 'الإعلانات',
                          icon: Icons.campaign_outlined,
                          pageBuilder: (cir) => AnnouncementsPage(
                              circleId: cir.id, user: widget.user),
                        ));
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('أنشئ إعلانًا'),
                    style: TextButton.styleFrom(foregroundColor: _green),
                  ),
                ],
              ),
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

// ── small pieces ──────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: _green),
              const SizedBox(width: 7),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _AttentionRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ),
            const Icon(Icons.chevron_left, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
