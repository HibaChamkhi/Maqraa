import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';

/// التقارير — per-circle reports with three sections:
/// التسليم الأسبوعي (homework) · الحضور (sessions) · الاختبارات (exams).
/// The الاختبارات tab is built; the other two are placeholders for now.
class ReportsPage extends StatelessWidget {
  final String circleId;
  const ReportsPage({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 2, // open on الاختبارات (the built one)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'التسليم الأسبوعي'),
              Tab(text: 'الحضور'),
              Tab(text: 'الاختبارات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _ComingSoon(label: 'تقرير التسليم الأسبوعي'),
            const _ComingSoon(label: 'تقرير الحضور'),
            _ExamsReport(circleId: circleId),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insights_outlined,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('قريبًا',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  الاختبارات report
// ---------------------------------------------------------------------------

class _RepData {
  final List<CircleMember> students; // sorted lowest-average first
  final List<Exam> exams; // newest first
  final Map<String, Map<String, ExamResult>> byExam; // examId -> uid -> result
  _RepData(this.students, this.exams, this.byExam);
}

class _ExamsReport extends StatefulWidget {
  final String circleId;
  const _ExamsReport({required this.circleId});

  @override
  State<_ExamsReport> createState() => _ExamsReportState();
}

class _ExamsReportState extends State<_ExamsReport> {
  late Future<_RepData> _future = _load();

  Future<_RepData> _load() async {
    final members = await getIt<CircleRepository>().getMembers(widget.circleId);
    final students = members
        .where((m) =>
            m.role == UserRole.student && m.status == MemberStatus.active)
        .toList();
    final exams =
        await getIt<ExamRepository>().getExams(widget.circleId);
    exams.sort((a, b) => b.date.compareTo(a.date)); // newest first
    final byExam = <String, Map<String, ExamResult>>{};
    for (final e in exams) {
      final rs = await getIt<ExamRepository>()
          .getResults(circleId: widget.circleId, examId: e.id);
      byExam[e.id] = {for (final r in rs) r.uid: r};
    }
    students.sort((a, b) {
      final aa = _avg(exams, byExam, a.uid);
      final bb = _avg(exams, byExam, b.uid);
      if (aa == null && bb == null) return a.name.compareTo(b.name);
      if (aa == null) return 1;
      if (bb == null) return -1;
      return aa.compareTo(bb);
    });
    return _RepData(students, exams, byExam);
  }

  /// A student's average percent over exams she actually sat (absent excluded).
  static double? _avg(List<Exam> exams,
      Map<String, Map<String, ExamResult>> byExam, String uid) {
    final pcts = <double>[];
    for (final e in exams) {
      final r = byExam[e.id]?[uid];
      if (r == null || r.attendance != ExamAttendance.present) continue;
      if (e.totalMarks > 0) pcts.add(r.score / e.totalMarks * 100);
    }
    if (pcts.isEmpty) return null;
    return pcts.reduce((a, b) => a + b) / pcts.length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RepData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        if (d.exams.isEmpty) {
          return const _ComingSoon(label: 'لا توجد اختبارات بعد');
        }
        if (d.students.isEmpty) {
          return Center(
            child: Text('لا توجد طالبات في الحلقة',
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _kpis(context, d),
            const SizedBox(height: AppSpacing.md),
            _Matrix(
              data: d,
              onStudent: (m) => _showStudent(context, d, m),
              onExam: (e) => _showExam(context, d, e),
            ),
            const SizedBox(height: AppSpacing.sm),
            _legend(context),
          ],
        );
      },
    );
  }

  Widget _kpis(BuildContext context, _RepData d) {
    final present = <double>[]; // all present results as percent
    var passed = 0, recorded = 0, attended = 0;
    for (final e in d.exams) {
      for (final m in d.students) {
        final r = d.byExam[e.id]?[m.uid];
        if (r == null) continue;
        recorded++;
        if (r.attendance == ExamAttendance.present) {
          attended++;
          if (e.totalMarks > 0) present.add(r.score / e.totalMarks * 100);
          if (r.score >= e.passMark) passed++;
        }
      }
    }
    final avg = present.isEmpty
        ? 0
        : (present.reduce((a, b) => a + b) / present.length).round();
    final passRate =
        attended == 0 ? 0 : (passed / attended * 100).round();
    final attRate = recorded == 0 ? 0 : (attended / recorded * 100).round();
    return Row(
      children: [
        _kpi('${d.exams.length}', 'عدد الاختبارات', filled: true),
        const SizedBox(width: AppSpacing.sm),
        _kpi('$avg٪', 'متوسط الدرجات'),
        const SizedBox(width: AppSpacing.sm),
        _kpi('$passRate٪', 'نسبة النجاح'),
        const SizedBox(width: AppSpacing.sm),
        _kpi('$attRate٪', 'حضور الاختبارات'),
      ],
    );
  }

  Widget _kpi(String value, String label, {bool filled = false}) {
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
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: filled ? AppColors.primaryDark : AppColors.ink)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    Widget item(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 10,
              height: 10,
              margin: const EdgeInsetsDirectional.only(end: 4),
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(3))),
          Text(t,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]);
    return Wrap(spacing: 14, runSpacing: 6, children: [
      item(const Color(0xFFE1F5EE), 'ناجحة'),
      item(const Color(0xFFFCEBEB), 'راسبة'),
      item(AppColors.gray, 'غائبة / معذورة / لم تُرصد'),
    ]);
  }

  void _showStudent(BuildContext context, _RepData d, CircleMember m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.name),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in d.exams)
                _historyRow(e, d.byExam[e.id]?[m.uid]),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _historyRow(Exam e, ExamResult? r) {
    final fmt = DateFormat('d MMM y', 'ar');
    String trailing;
    Color color;
    if (r == null) {
      trailing = 'لم تُرصد';
      color = AppColors.textMuted;
    } else if (r.attendance != ExamAttendance.present) {
      trailing = r.attendance.arabicLabel;
      color = AppColors.textMuted;
    } else {
      trailing = '${r.score}/${e.totalMarks}';
      color = r.score >= e.passMark ? AppColors.success : AppColors.error;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: const TextStyle(fontSize: 13)),
                Text(fmt.format(e.date),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(trailing,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showExam(BuildContext context, _RepData d, Exam e) {
    final results = d.byExam[e.id] ?? const {};
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(e.title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${e.type.arabicLabel} · ${DateFormat('d MMM y', 'ar').format(e.date)} · من ${e.totalMarks}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.sm),
              for (final m in d.students) _historyRow2(e, results[m.uid], m),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _historyRow2(Exam e, ExamResult? r, CircleMember m) {
    String trailing;
    Color color;
    if (r == null) {
      trailing = 'لم تُرصد';
      color = AppColors.textMuted;
    } else if (r.attendance != ExamAttendance.present) {
      trailing = r.attendance.arabicLabel;
      color = AppColors.textMuted;
    } else {
      trailing = '${r.score}/${e.totalMarks}';
      color = r.score >= e.passMark ? AppColors.success : AppColors.error;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(m.name, style: const TextStyle(fontSize: 13))),
          Text(trailing,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Matrix extends StatelessWidget {
  final _RepData data;
  final void Function(CircleMember) onStudent;
  final void Function(Exam) onExam;
  const _Matrix(
      {required this.data, required this.onStudent, required this.onExam});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM', 'ar');
    const examW = 86.0, avgW = 70.0, baseNameW = 140.0;
    return LayoutBuilder(builder: (context, c) {
      final fixed = baseNameW + examW * data.exams.length + avgW;
      final nameW =
          fixed < c.maxWidth ? baseNameW + (c.maxWidth - fixed) : baseNameW;
      final totalW = nameW + examW * data.exams.length + avgW;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalW,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // header
                Container(
                  color: AppColors.gray,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: nameW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('الطالبة',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted)),
                        ),
                      ),
                      for (final e in data.exams)
                        SizedBox(
                          width: examW,
                          child: InkWell(
                            onTap: () => onExam(e),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink)),
                                Text('${fmt.format(e.date)} · ${e.totalMarks}',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(
                        width: avgW,
                        child: Center(
                          child: Text('المعدل',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                for (final m in data.students)
                  _RowTile(
                    data: data,
                    member: m,
                    nameW: nameW,
                    examW: examW,
                    avgW: avgW,
                    onTap: () => onStudent(m),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _RowTile extends StatelessWidget {
  final _RepData data;
  final CircleMember member;
  final double nameW, examW, avgW;
  final VoidCallback onTap;
  const _RowTile({
    required this.data,
    required this.member,
    required this.nameW,
    required this.examW,
    required this.avgW,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avg = _ExamsReportState._avg(data.exams, data.byExam, member.uid);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: .5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: nameW,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.sky,
                      child: Text(
                          member.name.isNotEmpty
                              ? member.name.characters.first
                              : '؟',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            for (final e in data.exams)
              SizedBox(
                width: examW,
                child: Center(child: _cell(e, data.byExam[e.id]?[member.uid])),
              ),
            SizedBox(
              width: avgW,
              child: Center(
                child: Text(avg == null ? '—' : '${avg.round()}٪',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: avg == null
                            ? AppColors.textMuted
                            : AppColors.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(Exam e, ExamResult? r) {
    String text;
    Color bg, fg;
    if (r == null) {
      text = '—';
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    } else if (r.attendance == ExamAttendance.absent) {
      text = 'غائبة';
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    } else if (r.attendance == ExamAttendance.excused) {
      text = 'معذورة';
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    } else {
      final pass = r.score >= e.passMark;
      text = '${r.score}';
      bg = (pass ? AppColors.success : AppColors.error).withValues(alpha: 0.14);
      fg = pass ? AppColors.success : AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text,
          style: TextStyle(
              color: fg,
              fontSize: text.length > 3 ? 9 : 11,
              fontWeight: FontWeight.w700)),
    );
  }
}
