import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/util/notify.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../../../domain/notification/models/app_notification.dart';
import 'exam_results_page.dart';

/// Read-only analysis of one exam: KPIs, grade distribution, per-student
/// results, plus edit + publish actions.
class ExamAnalysisPage extends StatefulWidget {
  final String circleId;
  final Exam exam;
  final AppUser user;
  final bool canManage;

  const ExamAnalysisPage({
    super.key,
    required this.circleId,
    required this.exam,
    required this.user,
    this.canManage = true,
  });

  @override
  State<ExamAnalysisPage> createState() => _ExamAnalysisPageState();
}

class _ExamAnalysisPageState extends State<ExamAnalysisPage> {
  late bool _published = widget.exam.resultsPublished;
  late Future<_Data> _future = _load();

  Exam get _exam => widget.exam;

  Future<_Data> _load() async {
    final members = await getIt<CircleRepository>().getMembers(widget.circleId);
    final students = members
        .where((m) =>
            m.role == UserRole.student && m.status == MemberStatus.active)
        .toList();
    final results = await getIt<ExamRepository>()
        .getResults(circleId: widget.circleId, examId: _exam.id);
    final byUid = {for (final r in results) r.uid: r};
    int rank(CircleMember m) {
      final r = byUid[m.uid];
      if (r == null) return 2;
      return r.attendance == ExamAttendance.present ? 0 : 1;
    }

    students.sort((a, b) {
      final ra = rank(a), rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      if (ra == 0) {
        return byUid[b.uid]!.score.compareTo(byUid[a.uid]!.score); // desc
      }
      return a.name.compareTo(b.name);
    });
    return _Data(students, byUid);
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExamResultsPage(
          circleId: widget.circleId, exam: _exam, user: widget.user),
    ));
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _togglePublish() async {
    final next = !_published;
    setState(() => _published = next);
    try {
      await getIt<ExamRepository>().setResultsPublished(
          circleId: widget.circleId, examId: _exam.id, published: next);
      if (next) {
        await notifyCircleStudents(
          circleId: widget.circleId,
          title: 'نتيجة اختبار جاهزة',
          body: 'ظهرت نتيجتك في اختبار «${_exam.title}» — تفقّدي قسم الاختبارات',
          type: NotificationType.exam,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(next ? 'تم نشر النتائج' : 'تم إخفاء النتائج')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _published = !next);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('تعذّر تحديث النشر')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحليل الاختبار')),
      body: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          final present = <num>[];
          var passed = 0;
          final dist = <String, int>{
            'ممتاز': 0,
            'جيد جدًا': 0,
            'جيد': 0,
            'مقبول': 0,
            'راسب': 0,
          };
          for (final m in d.students) {
            final r = d.byUid[m.uid];
            if (r == null) continue;
            if (r.attendance == ExamAttendance.present) {
              present.add(r.score);
              if (r.score >= _exam.passMark) passed++;
              final g = examGradeLabel(r.score, _exam.totalMarks);
              if (dist.containsKey(g)) dist[g] = dist[g]! + 1;
            }
          }
          final hasScores = present.isNotEmpty;
          final avg = hasScores
              ? (present.reduce((a, b) => a + b) / present.length).round()
              : 0;
          final maxS = hasScores ? present.reduce((a, b) => a > b ? a : b) : 0;
          final minS = hasScores ? present.reduce((a, b) => a < b ? a : b) : 0;
          final passRate =
              present.isEmpty ? 0 : (passed / present.length * 100).round();
          final attended = present.length;
          final total = d.students.length;
          final maxBand =
              dist.values.fold<int>(0, (m, v) => v > m ? v : m);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _header(),
              const SizedBox(height: AppSpacing.md),
              _kpis(hasScores, avg, maxS, minS, passRate, attended, total),
              const SizedBox(height: AppSpacing.md),
              _distribution(dist, maxBand),
              const SizedBox(height: AppSpacing.md),
              _resultsList(d),
              const SizedBox(height: AppSpacing.md),
              if (widget.canManage) _actions(),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_exam.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${_exam.type.arabicLabel} · ${DateFormat('EEEE d MMMM', 'ar').format(_exam.date)} · من ${_exam.totalMarks} · النجاح ${_exam.passMark}',
                  style: const TextStyle(color: Color(0xFFE3F0EC), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(_published ? 'منشورة' : 'مخفية',
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _kpis(bool hasScores, int avg, num maxS, num minS, int passRate,
      int attended, int total) {
    Widget k(String v, String l, {bool filled = false}) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: filled ? AppColors.sky : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: filled ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(v,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color:
                            filled ? AppColors.primaryDark : AppColors.ink)),
                const SizedBox(height: 2),
                Text(l,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        );
    final dash = hasScores ? null : '—';
    return Row(
      children: [
        k(dash ?? '$avg', 'المتوسط', filled: true),
        const SizedBox(width: 6),
        k(dash ?? '$maxS', 'أعلى'),
        const SizedBox(width: 6),
        k(dash ?? '$minS', 'أدنى'),
        const SizedBox(width: 6),
        k('$passRate٪', 'النجاح'),
        const SizedBox(width: 6),
        k('$attended/$total', 'الحضور'),
      ],
    );
  }

  Widget _distribution(Map<String, int> dist, int maxBand) {
    Color barColor(String g) {
      if (g == 'راسب') return AppColors.error;
      if (g == 'مقبول') return AppColors.warning;
      return AppColors.success;
    }

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
          const Text('توزيع التقديرات',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          for (final entry in dist.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                      width: 64,
                      child: Text(entry.key,
                          style: TextStyle(
                              fontSize: 12, color: barColor(entry.key)))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: maxBand == 0 ? 0 : entry.value / maxBand,
                        minHeight: 14,
                        backgroundColor: AppColors.gray,
                        valueColor:
                            AlwaysStoppedAnimation(barColor(entry.key)),
                      ),
                    ),
                  ),
                  SizedBox(
                      width: 22,
                      child: Text('${entry.value}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultsList(_Data d) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.gray,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: const Row(
              children: [
                Expanded(
                    child: Text('الطالبة',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted))),
                Text('الدرجة',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          for (final m in d.students)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.border, width: .5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                      child: Text(m.name,
                          style: const TextStyle(fontSize: 13))),
                  _resultChip(d.byUid[m.uid]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultChip(ExamResult? r) {
    String text;
    Color bg, fg;
    if (r == null) {
      text = 'لم تُرصد';
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    } else if (r.attendance != ExamAttendance.present) {
      text = r.attendance.arabicLabel;
      bg = AppColors.gray;
      fg = AppColors.textMuted;
    } else {
      final pass = r.score >= _exam.passMark;
      final g = examGradeLabel(r.score, _exam.totalMarks);
      text = '${r.score} · $g';
      bg = (pass ? AppColors.success : AppColors.error).withValues(alpha: 0.14);
      fg = pass ? AppColors.success : AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('تعديل الدرجات'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _togglePublish,
            icon: Icon(
                _published
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18),
            label: Text(_published ? 'إخفاء النتائج' : 'نشر النتائج'),
          ),
        ),
      ],
    );
  }
}

class _Data {
  final List<CircleMember> students;
  final Map<String, ExamResult> byUid;
  _Data(this.students, this.byUid);
}
