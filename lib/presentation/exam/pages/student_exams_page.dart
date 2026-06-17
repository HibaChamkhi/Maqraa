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
/// score for each one.
class StudentExamsPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const StudentExamsPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExamBloc>()..add(ExamsRequested(circleId)),
      child: _StudentExamsView(circleId: circleId),
    );
  }
}

class _StudentExamsView extends StatelessWidget {
  final String circleId;

  const _StudentExamsView({required this.circleId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM y', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('اختباراتي')),
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
                  leading: const Icon(Icons.quiz_outlined),
                  title: Text(exam.title),
                  subtitle:
                      Text('${exam.range}\n${dateFormat.format(exam.date)}'),
                  isThreeLine: true,
                  trailing: _ScoreBadge(circleId: circleId, examId: exam.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Loads & shows the current student's own score for one exam (US-21).
class _ScoreBadge extends StatefulWidget {
  final String circleId;
  final String examId;

  const _ScoreBadge({required this.circleId, required this.examId});

  @override
  State<_ScoreBadge> createState() => _ScoreBadgeState();
}

class _ScoreBadgeState extends State<_ScoreBadge> {
  late final Future<ExamResult?> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<ExamRepository>().getMyResult(
      circleId: widget.circleId,
      examId: widget.examId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text('${result.score}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: AppColors.success)),
        );
      },
    );
  }
}
