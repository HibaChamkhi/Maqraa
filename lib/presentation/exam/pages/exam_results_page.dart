import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/exam/models/exam.dart';
import '../bloc/exam_bloc.dart';

/// US-21: teacher records a score per student for an [Exam].
/// Loads the circle's active student members and lets the teacher enter a
/// score for each, writing it to the exam's results subcollection.
class ExamResultsPage extends StatelessWidget {
  final String circleId;
  final Exam exam;
  final AppUser user;

  const ExamResultsPage({
    super.key,
    required this.circleId,
    required this.exam,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExamBloc>()
        ..add(ExamResultsRequested(circleId: circleId, examId: exam.id)),
      child: _ExamResultsView(circleId: circleId, exam: exam),
    );
  }
}

class _ExamResultsView extends StatefulWidget {
  final String circleId;
  final Exam exam;

  const _ExamResultsView({required this.circleId, required this.exam});

  @override
  State<_ExamResultsView> createState() => _ExamResultsViewState();
}

class _ExamResultsViewState extends State<_ExamResultsView> {
  late Future<List<CircleMember>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture =
        getIt<CircleRepository>().getMembers(widget.circleId).then(
              (members) => members
                  .where((m) =>
                      m.role == UserRole.student &&
                      m.status == MemberStatus.active)
                  .toList(growable: false),
            );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('درجات ${widget.exam.title}')),
      body: BlocConsumer<ExamBloc, ExamState>(
        listenWhen: (prev, curr) => curr.message.isNotEmpty && curr.actionDone,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          return FutureBuilder<List<CircleMember>>(
            future: _membersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final students = snapshot.data!;
              if (students.isEmpty) {
                return Center(
                  child: Text('لا توجد طالبات في الحلقة',
                      style: theme.textTheme.bodyMedium),
                );
              }
              final scores = {for (final r in state.results) r.uid: r.score};
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(widget.exam.range,
                        style: theme.textTheme.bodyMedium),
                  ),
                  ...students.map((student) => _ResultTile(
                        student: student,
                        score: scores[student.uid],
                        onSave: (value) => context.read<ExamBloc>().add(
                              ExamResultRecorded(
                                circleId: widget.circleId,
                                examId: widget.exam.id,
                                uid: student.uid,
                                name: student.name,
                                score: value,
                              ),
                            ),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ResultTile extends StatefulWidget {
  final CircleMember student;
  final num? score;
  final ValueChanged<num> onSave;

  const _ResultTile({
    required this.student,
    required this.score,
    required this.onSave,
  });

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.score?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ResultTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score && widget.score != null) {
      _controller.text = widget.score.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = num.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('أدخلي درجة صحيحة')));
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person_outline)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(widget.student.name)),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'الدرجة',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined, color: AppColors.primary),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
