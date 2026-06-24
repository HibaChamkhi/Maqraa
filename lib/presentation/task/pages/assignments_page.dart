import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/task/models/assignment.dart';
import '../bloc/task_bloc.dart';

/// US-35: assignments view.
///
/// - The student sees their own to-dos and can mark each done.
/// - A teacher/supervisor additionally gets a "+" to create a per-student to-do
///   for the [studentId] in scope.
class AssignmentsPage extends StatelessWidget {
  final String circleId;

  /// The student whose assignments are shown (own uid for students).
  final String studentId;
  final String studentName;

  /// The viewing user — drives whether the create action is shown.
  final AppUser user;

  const AssignmentsPage({
    super.key,
    required this.circleId,
    required this.studentId,
    required this.studentName,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskBloc>()
        ..add(AssignmentsLoadRequested(
            circleId: circleId, studentId: studentId)),
      child: _AssignmentsView(
        circleId: circleId,
        studentId: studentId,
        studentName: studentName,
        user: user,
      ),
    );
  }
}

class _AssignmentsView extends StatelessWidget {
  final String circleId;
  final String studentId;
  final String studentName;
  final AppUser user;

  const _AssignmentsView({
    required this.circleId,
    required this.studentId,
    required this.studentName,
    required this.user,
  });

  bool get _canCreate =>
      user.role == UserRole.teacher || user.role == UserRole.supervisor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('التكاليف')),
      floatingActionButton: _canCreate
          ? Builder(
              builder: (innerCtx) => FloatingActionButton(
                onPressed: () => _create(innerCtx),
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: BlocConsumer<TaskBloc, TaskState>(
        listenWhen: (p, c) => p.message != c.message && c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          context.read<TaskBloc>().add(AssignmentsLoadRequested(
              circleId: circleId, studentId: studentId));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.assignments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final assignments = state.assignments;
          if (assignments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.checklist_outlined,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.sm),
                    Text('لا توجد تكاليف بعد',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: assignments.length,
            itemBuilder: (context, i) {
              final a = assignments[i];
              final isOwner = a.studentId == user.uid;
              return _AssignmentTile(
                assignment: a,
                // Only the student themself toggles done.
                onToggle: isOwner
                    ? (value) => context.read<TaskBloc>().add(
                          AssignmentDoneToggled(
                            circleId: circleId,
                            assignmentId: a.id,
                            done: value,
                          ),
                        )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _create(BuildContext context) {
    final titleCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('تكليف جديد لـ $studentName'),
        content: TextField(
          controller: titleCtrl,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'عنوان التكليف',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              context.read<TaskBloc>().add(
                    AssignmentCreateRequested(
                      circleId: circleId,
                      assignment: Assignment(
                        id: '',
                        studentId: studentId,
                        studentName: studentName,
                        title: title,
                        date: DateTime.now(),
                      ),
                    ),
                  );
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final Assignment assignment;
  final ValueChanged<bool>? onToggle;

  const _AssignmentTile({required this.assignment, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: assignment.done,
          onChanged: onToggle == null
              ? null
              : (v) => onToggle!(v ?? false),
        ),
        title: Text(
          assignment.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration:
                assignment.done ? TextDecoration.lineThrough : null,
            color: assignment.done ? AppColors.textMuted : null,
          ),
        ),
        subtitle: Text(DateFormat('yyyy/MM/dd').format(assignment.date)),
      ),
    );
  }
}
