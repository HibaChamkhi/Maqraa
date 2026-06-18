import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../bloc/exam_bloc.dart';

/// US-21 (student side): a student views the circle's exams and their own
/// result for each one — but only after the teacher publishes it.
class StudentExamsPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  /// When true, renders without its own AppBar (e.g. inside a tab).
  final bool embedded;

  const StudentExamsPage({
    super.key,
    required this.circleId,
    required this.user,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExamBloc>()..add(ExamsRequested(circleId)),
      child: _StudentExamsView(circleId: circleId, embedded: embedded),
    );
  }
}

class _StudentExamsView extends StatelessWidget {
  final String circleId;
  final bool embedded;

  const _StudentExamsView({required this.circleId, required this.embedded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM y • h:mm a', 'ar');
    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : null,
      appBar: embedded ? null : AppBar(title: const Text('اختباراتي')),
      body: BlocBuilder<ExamBloc, ExamState>(
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.exams.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == UIStatus.error) {
            return Center(
              child: Text(state.message, style: theme.textTheme.bodyMedium),
            );
          }
          if (state.exams.isEmpty) {
            return Center(
              child: Text('لا توجد اختبارات بعد',
                  style: theme.textTheme.titleMedium),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: state.exams.length,
            itemBuilder: (context, i) {
              final exam = state.exams[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.sky,
                    child: Icon(Icons.quiz_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(exam.title),
                  subtitle: Text(
                      '${exam.range}\n${dateFormat.format(exam.date)}'),
                  isThreeLine: true,
                  trailing: _ResultBadge(circleId: circleId, exam: exam),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shows the student's own outcome for one exam, gated by [Exam.resultsPublished].
class _ResultBadge extends StatefulWidget {
  final String circleId;
  final Exam exam;

  const _ResultBadge({required this.circleId, required this.exam});

  @override
  State<_ResultBadge> createState() => _ResultBadgeState();
}

class _ResultBadgeState extends State<_ResultBadge> {
  late final Future<ExamResult?> _future;

  @override
  void initState() {
    super.initState();
    // Only fetch the student's result when results are published.
    _future = widget.exam.resultsPublished
        ? getIt<ExamRepository>().getMyResult(
            circleId: widget.circleId,
            examId: widget.exam.id,
          )
        : Future<ExamResult?>.value(null);
  }

  void _showDetails(ExamResult result) {
    final exam = widget.exam;
    final present = result.attendance == ExamAttendance.present;
    final grade =
        present ? examGradeLabel(result.score, exam.totalMarks) : '';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(exam.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (present) ...[
              Text('الدرجة: ${result.score} من ${exam.totalMarks}'),
              if (grade.isNotEmpty) Text('التقدير: $grade'),
              Text(result.passed(exam.passMark) ? 'النتيجة: ناجحة' : 'النتيجة: راسبة'),
            ] else
              Text('الحالة: ${result.attendance.arabicLabel}'),
            if (result.feedback.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('ملاحظة المعلّمة:',
                  style: Theme.of(ctx).textTheme.titleSmall),
              Text(result.feedback),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.exam.resultsPublished) {
      return Chip(
        label: const Text('لم تُنشر'),
        backgroundColor: AppColors.warning.withValues(alpha: 0.15),
        labelStyle: theme.textTheme.bodySmall
            ?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
      );
    }

    return FutureBuilder<ExamResult?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final result = snapshot.data;
        if (result == null) {
          return Chip(
            label: const Text('لم تُرصد'),
            backgroundColor: AppColors.sky,
            labelStyle: theme.textTheme.bodySmall,
          );
        }
        if (result.attendance != ExamAttendance.present) {
          return ActionChip(
            label: Text(result.attendance.arabicLabel),
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.12),
            labelStyle: theme.textTheme.bodySmall,
            onPressed: () => _showDetails(result),
          );
        }
        final passed = result.passed(widget.exam.passMark);
        final color = passed ? AppColors.success : AppColors.error;
        return InkWell(
          onTap: () => _showDetails(result),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text('${result.score}/${widget.exam.totalMarks}',
                style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ),
        );
      },
    );
  }
}
