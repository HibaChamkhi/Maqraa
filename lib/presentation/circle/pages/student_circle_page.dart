import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/announcement/models/announcement.dart';
import '../../../domain/announcement/repositories/announcement_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../../../domain/homework/models/weekly_homework.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../announcement/pages/announcements_page.dart';

/// Read-only student view of ONE حلقة: circle info, the programmed week's
/// واجبات (tickable), her own stats, her رفيقة, and a names-only roster.
/// Classmates' grades/progress are never shown.
class StudentCirclePage extends StatefulWidget {
  final Circle circle;
  final AppUser user;
  const StudentCirclePage({super.key, required this.circle, required this.user});

  @override
  State<StudentCirclePage> createState() => _StudentCirclePageState();
}

class _CircleData {
  final List<CircleMember> students;
  final CircleMember? me;
  final CircleMember? partner;
  final WeeklyHomework week;
  final Set<String> doneDays;
  final int? examAvg;
  final int? attendancePct;
  final int weekSessions;
  final Announcement? announcement;
  const _CircleData({
    required this.students,
    required this.me,
    required this.partner,
    required this.week,
    required this.doneDays,
    required this.examAvg,
    required this.attendancePct,
    required this.weekSessions,
    required this.announcement,
  });
}

class _StudentCirclePageState extends State<StudentCirclePage> {
  late Future<_CircleData> _future = _load();

  /// Optimistic overlay for today's/this-week's ticks, so a tap updates
  /// instantly without reloading the whole (heavy) page.
  Set<String>? _doneOverride;
  Set<String> _baseDone = {};
  Set<String> get _effectiveDone => _doneOverride ?? _baseDone;

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

  bool _happened(Session s) =>
      s.status == SessionStatus.ended ||
      s.status == SessionStatus.live ||
      s.scheduledAt.isBefore(DateTime.now());

  Future<_CircleData> _load() async {
    final id = widget.circle.id;
    final now = DateTime.now();

    // --- members / roster ---
    final all = await getIt<CircleRepository>().getMembers(id);
    final students = all
        .where((m) =>
            m.role == UserRole.student && m.status == MemberStatus.active)
        .toList();
    CircleMember? me;
    for (final m in all) {
      if (m.uid == widget.user.uid) {
        me = m;
        break;
      }
    }
    CircleMember? partner;
    if (me?.partnerId != null && me!.partnerId!.isNotEmpty) {
      for (final m in all) {
        if (m.uid == me.partnerId) {
          partner = m;
          break;
        }
      }
    }

    // --- this week's plan + my completion ---
    WeeklyHomework week =
        WeeklyHomework(weekId: _weekId, weekStart: _weekStart);
    var doneDays = <String>{};
    try {
      week = await _hw.weekStream(id, _weekId, _weekStart).first;
      final comp = await _hw.myCompletion(id, _weekId);
      doneDays = comp.doneDays;
    } catch (_) {/* homework optional */}

    // --- exams: average of my published, present results ---
    int? examAvg;
    try {
      final exams = await getIt<ExamRepository>().getExams(id);
      final pcts = <double>[];
      for (final e in exams) {
        if (e.date.isAfter(now) || !e.resultsPublished) continue;
        final r = await getIt<ExamRepository>()
            .getMyResult(circleId: id, examId: e.id);
        if (r != null &&
            r.attendance == ExamAttendance.present &&
            e.totalMarks > 0) {
          pcts.add(r.score / e.totalMarks * 100);
        }
      }
      if (pcts.isNotEmpty) {
        examAvg = (pcts.reduce((a, b) => a + b) / pcts.length).round();
      }
    } catch (_) {/* exams optional */}

    // --- sessions: this-week count + my attendance % over held sessions ---
    var weekSessions = 0;
    int? attendancePct;
    try {
      final sessions = await getIt<SessionRepository>().getSessions(id);
      final weekEnd = _weekStart.add(const Duration(days: 7));
      weekSessions = sessions
          .where((s) =>
              !s.scheduledAt.isBefore(_weekStart) &&
              s.scheduledAt.isBefore(weekEnd))
          .length;
      final held = sessions.where(_happened).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      final considered = held.take(40).toList();
      if (considered.isNotEmpty) {
        var present = 0;
        for (final s in considered) {
          final att = await getIt<SessionRepository>()
              .getAttendance(circleId: id, sessionId: s.id);
          if (att.any((a) => a.uid == widget.user.uid && a.present)) {
            present++;
          }
        }
        attendancePct = (present / considered.length * 100).round();
      }
    } catch (_) {/* sessions optional */}

    // --- latest announcement ---
    Announcement? ann;
    try {
      final list = await getIt<AnnouncementRepository>().getAnnouncements(id);
      if (list.isNotEmpty) ann = list.first;
    } catch (_) {/* announcements optional */}

    return _CircleData(
      students: students,
      me: me,
      partner: partner,
      week: week,
      doneDays: doneDays,
      examAvg: examAvg,
      attendancePct: attendancePct,
      weekSessions: weekSessions,
      announcement: ann,
    );
  }

  Future<void> _toggle(String dayCode, bool currentlyDone) async {
    // Optimistic: flip the tick immediately, write in the background, revert on
    // failure. Avoids reloading the whole (heavy) page on every tick.
    final next = {..._effectiveDone};
    if (currentlyDone) {
      next.remove(dayCode);
    } else {
      next.add(dayCode);
    }
    setState(() => _doneOverride = next);
    try {
      await _hw.setDayDone(
        circleId: widget.circle.id,
        weekId: _weekId,
        dayCode: dayCode,
        done: !currentlyDone,
        studentName: widget.user.name,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final revert = {..._effectiveDone};
        if (currentlyDone) {
          revert.add(dayCode);
        } else {
          revert.remove(dayCode);
        }
        _doneOverride = revert;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ التسليم، حاولي مجددًا')),
      );
    }
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(title: Text('حلقة ${widget.circle.name}')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {
          _doneOverride = null;
          _future = _load();
        }),
        child: FutureBuilder<_CircleData>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = snap.data!;
            _baseDone = d.doneDays;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerCard(d),
                  const SizedBox(height: AppSpacing.md),
                  _weekCard(d),
                  const SizedBox(height: AppSpacing.md),
                  _statsGrid(d),
                  const SizedBox(height: AppSpacing.md),
                  _partnerAndAnnouncement(d),
                  const SizedBox(height: AppSpacing.md),
                  _roster(d),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------- header
  Widget _headerCard(_CircleData d) {
    final dayLabels = widget.circle.days
        .map((c) => WeeklyHomework.dayLabels[c] ?? c)
        .join('، ');
    final times = widget.circle.dayTimes.values.toSet();
    final time = times.isEmpty ? '' : times.first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_2_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.circle.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    if (widget.circle.teacherName.isNotEmpty)
                      Text('المعلّمة: ${widget.circle.teacherName}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('${d.students.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    Text('طالبة',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          if (dayLabels.isNotEmpty || time.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (dayLabels.isNotEmpty)
                  _headChip(Icons.calendar_month_outlined, dayLabels),
                if (time.isNotEmpty) _headChip(Icons.access_time, time),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _headChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      );

  // -------------------------------------------------- واجبات هذا الأسبوع
  Widget _weekCard(_CircleData d) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayCode = _todayCode();
    final planned = WeeklyHomework.dayOrder
        .where((c) => !d.week.planOf(c).isEmpty)
        .toList();
    final total = planned.length;
    final done = planned.where((c) => _effectiveDone.contains(c)).length;

    return _card(
      title: 'واجبات هذا الأسبوع',
      icon: Icons.menu_book_rounded,
      trailing: total > 0
          ? _pill('$done / $total مكتمل', AppColors.primary, Colors.white)
          : null,
      child: planned.isEmpty
          ? const _Empty(text: 'لم تُسجّل واجبات لهذا الأسبوع بعد')
          : Column(
              children: [
                for (var i = 0; i < planned.length; i++)
                  _dayRow(planned[i], d, today, todayCode,
                      last: i == planned.length - 1),
              ],
            ),
    );
  }

  Widget _dayRow(String code, _CircleData d, DateTime today, String todayCode,
      {required bool last}) {
    final plan = d.week.planOf(code);
    final date = d.week.dateOf(code);
    final isDone = _effectiveDone.contains(code);
    final isToday = code == todayCode;
    final isPast = date.isBefore(today);
    final isFuture = date.isAfter(today);
    final dF = DateFormat('d', 'ar');

    Widget status;
    if (isDone) {
      status = _checkBox(true, () => _toggle(code, true));
    } else if (isFuture) {
      status = _pill('قادم', AppColors.gray, AppColors.textMuted);
    } else {
      // today or past, not done -> tickable
      status = _checkBox(false, () => _toggle(code, false));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: .5)),
        color: isToday ? const Color(0xFFF6FBF9) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(WeeklyHomework.dayLabels[code] ?? code,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isToday ? AppColors.primary : AppColors.textMuted)),
                Text(isToday ? '${dF.format(date)} • اليوم' : dF.format(date),
                    style: TextStyle(
                        fontSize: 10,
                        color:
                            isToday ? AppColors.primary : AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                          plan.wajib.isNotEmpty ? plan.wajib : 'واجب',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.textMuted)),
                    ),
                    if (plan.type.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _typeChip(plan.type),
                    ],
                  ],
                ),
                if (plan.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('ملاحظة: ${plan.notes}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          status,
        ],
      ),
    );
  }

  Widget _checkBox(bool done, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: done ? AppColors.success : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: done ? AppColors.success : AppColors.primary, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      );

  // --------------------------------------------------------------- stats
  Widget _statsGrid(_CircleData d) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.8,
      children: [
        _stat(d.attendancePct == null ? '—' : '${d.attendancePct}٪', 'حضوري',
            AppColors.success),
        _stat(d.examAvg == null ? '—' : '${d.examAvg}٪', 'متوسط اختباراتي',
            AppColors.warning),
        _stat('${d.weekSessions}', 'جلسات الأسبوع', AppColors.primaryDark),
        _stat('${d.me?.memorizedPercent ?? 0}٪', 'تقدّمي', AppColors.primary),
      ],
    );
  }

  Widget _stat(String value, String label, Color tint) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: tint)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      );

  // ------------------------------------------------- partner + announcement
  Widget _partnerAndAnnouncement(_CircleData d) {
    final partnerCard = _card(
      title: 'رفيقتي',
      icon: Icons.handshake_outlined,
      child: d.partner == null
          ? const _Empty(text: 'لم تُحدَّد رفيقة بعد')
          : Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.sky,
                  child: Text(
                      d.partner!.name.isNotEmpty
                          ? d.partner!.name.characters.first
                          : '؟',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.partner!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const Text('شريكتك في التسميع',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
    );

    final annCard = InkWell(
      onTap: () => _open(
          AnnouncementsPage(circleId: widget.circle.id, user: widget.user)),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFAEEDA),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.campaign_outlined,
                  size: 16, color: Color(0xFF854F0B)),
              SizedBox(width: 6),
              Text('آخر إعلان',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF633806))),
            ]),
            const SizedBox(height: 8),
            Text(d.announcement?.text ?? 'لا إعلانات حاليًا',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF854F0B))),
          ],
        ),
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 520) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: partnerCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: annCard),
            ],
          ),
        );
      }
      return Column(children: [
        partnerCard,
        const SizedBox(height: AppSpacing.md),
        annCard,
      ]);
    });
  }

  // -------------------------------------------------------------- roster
  Widget _roster(_CircleData d) {
    return _card(
      title: 'طالبات الحلقة',
      icon: Icons.groups_outlined,
      trailing: Text('${d.students.length} طالبة',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final m in d.students) _rosterItem(m),
            ],
          ),
          const SizedBox(height: 10),
          const Text('الأسماء فقط — درجات وتقدّم زميلاتك خاصة',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _rosterItem(CircleMember m) {
    final isMe = m.uid == widget.user.uid;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: isMe ? AppColors.sky : AppColors.gray,
            child: Text(m.name.isNotEmpty ? m.name.characters.first : '؟',
                style: TextStyle(
                    color: isMe ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(isMe ? '${m.name} (أنا)' : m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: isMe ? AppColors.primary : AppColors.ink)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- shared bits
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(children: [
                  Icon(icon, size: 17, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );

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
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    );
  }
}
