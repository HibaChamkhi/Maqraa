import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/exam/models/exam.dart';
import '../bloc/exam_bloc.dart';
import 'exam_results_page.dart';

/// US-20: teacher schedules an exam (title, range, date) and lists exams.
/// Tapping an exam opens its results screen (US-21).
class TeacherExamsPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const TeacherExamsPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExamBloc>()..add(ExamsRequested(circleId)),
      child: _TeacherExamsView(circleId: circleId, user: user),
    );
  }
}

class _TeacherExamsView extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const _TeacherExamsView({required this.circleId, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM y', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('الاختبارات')),
      floatingActionButton: Builder(
        builder: (innerContext) => FloatingActionButton.extended(
          onPressed: () => _openScheduler(innerContext),
          icon: const Icon(Icons.add),
          label: const Text('اختبار جديد'),
        ),
      ),
      body: BlocConsumer<ExamBloc, ExamState>(
        listenWhen: (prev, curr) => curr.message.isNotEmpty && curr.actionDone,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.exams.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.exams.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    Text('لا توجد اختبارات بعد',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
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
                  subtitle: Text(
                      '${exam.range}\n${dateFormat.format(exam.date)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExamResultsPage(
                        circleId: circleId,
                        exam: exam,
                        user: user,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openScheduler(BuildContext context) async {
    final bloc = context.read<ExamBloc>();
    final result = await showModalBottomSheet<_ExamFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ExamForm(),
    );
    if (result == null) return;
    bloc.add(ExamScheduled(
      circleId: circleId,
      title: result.title,
      range: result.range,
      date: result.date,
    ));
  }
}

class _ExamFormResult {
  final String title;
  final String range;
  final DateTime date;

  const _ExamFormResult({
    required this.title,
    required this.range,
    required this.date,
  });
}

class _ExamForm extends StatefulWidget {
  const _ExamForm();

  @override
  State<_ExamForm> createState() => _ExamFormState();
}

class _ExamFormState extends State<_ExamForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _rangeController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_ExamFormResult(
      title: _titleController.text.trim(),
      range: _rangeController.text.trim(),
      date: _date,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM y', 'ar');
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('اختبار جديد',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الاختبار',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'يرجى إدخال عنوان الاختبار'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _rangeController,
              decoration: const InputDecoration(
                labelText: 'النطاق (مثال: البقرة ١-٢٠)',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'يرجى إدخال نطاق الاختبار'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(dateFormat.format(_date)),
              trailing: TextButton(
                  onPressed: _pickDate, child: const Text('تغيير')),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: _submit, child: const Text('جدولة')),
          ],
        ),
      ),
    );
  }
}
