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

/// US-20: teacher schedules an exam (title, range, type, marks, date) and lists
/// exams. Tapping an exam opens its grading/results screen (US-21).
class TeacherExamsPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  /// When true, renders without its own AppBar (e.g. inside a tab).
  final bool embedded;

  const TeacherExamsPage({
    super.key,
    required this.circleId,
    required this.user,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExamBloc>()..add(ExamsRequested(circleId)),
      child:
          _TeacherExamsView(circleId: circleId, user: user, embedded: embedded),
    );
  }
}

class _TeacherExamsView extends StatelessWidget {
  final String circleId;
  final AppUser user;
  final bool embedded;

  const _TeacherExamsView({
    required this.circleId,
    required this.user,
    required this.embedded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM y • h:mm a', 'ar');
    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : null,
      appBar: embedded
          ? null
          : AppBar(title: const Text('الاختبارات')),
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
                    const SizedBox(height: AppSpacing.xs),
                    Text('أضيفي اختبارًا جديدًا للحلقة',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 96),
            itemCount: state.exams.length,
            itemBuilder: (context, i) {
              final exam = state.exams[i];
              return _ExamCard(
                exam: exam,
                dateText: dateFormat.format(exam.date),
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExamResultsPage(
                      circleId: circleId,
                      exam: exam,
                      user: user,
                    ),
                  ),
                ),
                onEdit: () => _openEditor(context, exam),
                onDelete: () => _confirmDelete(context, exam),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Exam exam) async {
    final bloc = context.read<ExamBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الاختبار'),
        content: Text('سيتم حذف «${exam.title}» وجميع نتائجه. هل أنتِ متأكدة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(ExamDeleted(circleId: circleId, examId: exam.id));
    }
  }

  Future<void> _openScheduler(BuildContext context) async {
    final bloc = context.read<ExamBloc>();
    final result = await showDialog<_ExamFormResult>(
      context: context,
      builder: (_) => const _ExamForm(),
    );
    if (result == null) return;
    bloc.add(ExamScheduled(
      circleId: circleId,
      title: result.title,
      range: result.range,
      date: result.date,
      type: result.type,
      totalMarks: result.totalMarks,
      passMark: result.passMark,
    ));
  }

  Future<void> _openEditor(BuildContext context, Exam exam) async {
    final bloc = context.read<ExamBloc>();
    final result = await showDialog<_ExamFormResult>(
      context: context,
      builder: (_) => _ExamForm(initial: exam),
    );
    if (result == null) return;
    bloc.add(ExamUpdated(
      circleId: circleId,
      examId: exam.id,
      title: result.title,
      range: result.range,
      date: result.date,
      type: result.type,
      totalMarks: result.totalMarks,
      passMark: result.passMark,
    ));
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final String dateText;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamCard({
    required this.exam,
    required this.dateText,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.sky,
                    child: const Icon(Icons.quiz_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.title, style: theme.textTheme.titleMedium),
                        Text(dateText, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('تعديل'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(exam.range, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _Tag(label: exam.type.arabicLabel, color: AppColors.primary),
                  _Tag(
                      label: 'من ${exam.totalMarks}',
                      color: AppColors.textMuted),
                  exam.resultsPublished
                      ? const _Tag(
                          label: 'النتائج منشورة',
                          color: AppColors.success,
                          icon: Icons.visibility_outlined)
                      : const _Tag(
                          label: 'النتائج مخفية',
                          color: AppColors.warning,
                          icon: Icons.visibility_off_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Tag({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ExamFormResult {
  final String title;
  final String range;
  final DateTime date;
  final ExamType type;
  final num totalMarks;
  final num passMark;

  const _ExamFormResult({
    required this.title,
    required this.range,
    required this.date,
    required this.type,
    required this.totalMarks,
    required this.passMark,
  });
}

class _ExamForm extends StatefulWidget {
  /// When non-null, the form opens in edit mode pre-filled with this exam.
  final Exam? initial;

  const _ExamForm({this.initial});

  @override
  State<_ExamForm> createState() => _ExamFormState();
}

class _ExamFormState extends State<_ExamForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _rangeController;
  late final TextEditingController _totalController;
  late final TextEditingController _passController;
  late ExamType _type;
  late DateTime _date;
  late TimeOfDay _time;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _titleController = TextEditingController(text: e?.title ?? '');
    _rangeController = TextEditingController(text: e?.range ?? '');
    _totalController =
        TextEditingController(text: (e?.totalMarks ?? 100).toString());
    _passController =
        TextEditingController(text: (e?.passMark ?? 50).toString());
    _type = e?.type ?? ExamType.juz;
    _date = e?.date ?? DateTime.now();
    _time = e != null
        ? TimeOfDay(hour: e.date.hour, minute: e.date.minute)
        : const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rangeController.dispose();
    _totalController.dispose();
    _passController.dispose();
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final total = num.parse(_totalController.text.trim());
    final pass = num.parse(_passController.text.trim());
    final dt = DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);
    Navigator.of(context).pop(_ExamFormResult(
      title: _titleController.text.trim(),
      range: _rangeController.text.trim(),
      date: dt,
      type: _type,
      totalMarks: total,
      passMark: pass,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM y', 'ar');
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
          AppSpacing.sm, 0),
      title: Row(
        children: [
          Expanded(
            child: Text(_isEditing ? 'تعديل الاختبار' : 'اختبار جديد'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'إلغاء',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                DropdownButtonFormField<ExamType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'نوع الاختبار',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ExamType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.arabicLabel),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? ExamType.juz),
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الدرجة الكاملة',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        validator: (v) {
                          final n = num.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'غير صالحة';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _passController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'درجة النجاح',
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                        validator: (v) {
                          final n = num.tryParse((v ?? '').trim());
                          final total =
                              num.tryParse(_totalController.text.trim());
                          if (n == null || n < 0) return 'غير صالحة';
                          if (total != null && n > total) return '> الكاملة';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('التاريخ'),
                  subtitle: Text(dateFormat.format(_date)),
                  trailing: TextButton(
                      onPressed: _pickDate, child: const Text('تغيير')),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_outlined),
                  title: const Text('وقت البدء'),
                  subtitle: Text(_time.format(context)),
                  trailing: TextButton(
                      onPressed: _pickTime, child: const Text('تغيير')),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'حفظ التعديلات' : 'جدولة الاختبار'),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: EdgeInsets.zero,
    );
  }
}
