import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/exam/models/exam.dart';
import '../bloc/exam_bloc.dart';

/// US-21: teacher records a result per student for an [Exam] — score,
/// attendance (present/absent/excused) and an optional feedback note — then
/// publishes the results so students can see them.
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
  late bool _published;

  @override
  void initState() {
    super.initState();
    _published = widget.exam.resultsPublished;
    _membersFuture =
        getIt<CircleRepository>().getMembers(widget.circleId).then(
              (members) => members
                  .where((m) =>
                      m.role == UserRole.student &&
                      m.status == MemberStatus.active)
                  .toList(growable: false),
            );
  }

  void _togglePublish(bool value) {
    setState(() => _published = value);
    context.read<ExamBloc>().add(ExamPublishToggled(
          circleId: widget.circleId,
          examId: widget.exam.id,
          published: value,
        ));
  }

  String _csvCell(String v) =>
      (v.contains(',') || v.contains('"') || v.contains('\n'))
          ? '"${v.replaceAll('"', '""')}"'
          : v;

  Future<void> _exportCsv() async {
    final exam = widget.exam;
    final examBloc = context.read<ExamBloc>();
    final students = await _membersFuture;
    final results = {for (final r in examBloc.state.results) r.uid: r};
    String outcome(ExamResult? r) {
      if (r == null) return '';
      if (r.attendance != ExamAttendance.present) return r.attendance.arabicLabel;
      return r.score >= exam.passMark ? 'ناجحة' : 'راسبة';
    }

    final rows = <List<String>>[
      ['الطالبة', 'الدرجة', 'من', 'الحضور', 'النتيجة', 'ملاحظات'],
      for (final s in students)
        [
          s.name,
          results[s.uid]?.score.toString() ?? '',
          exam.totalMarks.toString(),
          results[s.uid]?.attendance.arabicLabel ?? '',
          outcome(results[s.uid]),
          results[s.uid]?.feedback ?? '',
        ],
    ];
    final csv = rows.map((r) => r.map(_csvCell).join(',')).join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode('﻿$csv'));
    final safe = exam.title.replaceAll(RegExp(r'\s+'), '_');
    try {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: 'results_$safe.csv')],
        text: 'نتائج ${exam.title}',
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذّرت المشاركة — تم نسخ النتائج إلى الحافظة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exam = widget.exam;
    return Scaffold(
      appBar: AppBar(
        title: Text('درجات ${exam.title}'),
        actions: [
          IconButton(
            tooltip: 'تصدير النتائج CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportCsv,
          ),
        ],
      ),
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
              final results = {for (final r in state.results) r.uid: r};
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  _HeaderCard(exam: exam),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    color: _published
                        ? AppColors.success.withValues(alpha: 0.08)
                        : null,
                    child: SwitchListTile(
                      value: _published,
                      onChanged: _togglePublish,
                      secondary: Icon(
                        _published
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _published
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      title: const Text('نشر النتائج للطالبات'),
                      subtitle: Text(
                        _published
                            ? 'الطالبات يرين درجاتهن الآن'
                            : 'الدرجات مخفية حتى النشر',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (students.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Text('لا توجد طالبات في الحلقة',
                            style: theme.textTheme.bodyMedium),
                      ),
                    )
                  else
                    ...students.map((student) => _ResultTile(
                          student: student,
                          result: results[student.uid],
                          totalMarks: exam.totalMarks,
                          passMark: exam.passMark,
                          onSave: (score, attendance, feedback) =>
                              context.read<ExamBloc>().add(
                                    ExamResultRecorded(
                                      circleId: widget.circleId,
                                      examId: exam.id,
                                      uid: student.uid,
                                      name: student.name,
                                      score: score,
                                      attendance: attendance,
                                      feedback: feedback,
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

class _HeaderCard extends StatelessWidget {
  final Exam exam;

  const _HeaderCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.sky,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exam.range, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE d MMMM y • h:mm a', 'ar').format(exam.date),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${exam.type.arabicLabel} · الدرجة الكاملة ${exam.totalMarks} · النجاح ${exam.passMark}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatefulWidget {
  final CircleMember student;
  final ExamResult? result;
  final num totalMarks;
  final num passMark;
  final void Function(num score, ExamAttendance attendance, String feedback)
      onSave;

  const _ResultTile({
    required this.student,
    required this.result,
    required this.totalMarks,
    required this.passMark,
    required this.onSave,
  });

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;
  late ExamAttendance _attendance;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(
      text: widget.result?.score.toString() ?? '',
    );
    _feedbackController =
        TextEditingController(text: widget.result?.feedback ?? '');
    _attendance = widget.result?.attendance ?? ExamAttendance.present;
  }

  @override
  void didUpdateWidget(covariant _ResultTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final r = widget.result;
    if (oldWidget.result != r && r != null) {
      _scoreController.text = r.score.toString();
      _feedbackController.text = r.feedback;
      _attendance = r.attendance;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _save() {
    num score = 0;
    if (_attendance == ExamAttendance.present) {
      final value = num.tryParse(_scoreController.text.trim());
      if (value == null || value < 0 || value > widget.totalMarks) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('أدخلي درجة بين 0 و ${widget.totalMarks}')));
        return;
      }
      score = value;
    }
    FocusScope.of(context).unfocus();
    widget.onSave(score, _attendance, _feedbackController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = _attendance == ExamAttendance.present;
    final score = num.tryParse(_scoreController.text.trim());
    final grade =
        (isPresent && score != null) ? examGradeLabel(score, widget.totalMarks) : '';
    final passed = isPresent && score != null && score >= widget.passMark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.sky,
                  child: Text(
                    widget.student.name.isNotEmpty
                        ? widget.student.name.characters.first
                        : '؟',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(widget.student.name)),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _scoreController,
                    enabled: isPresent,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'الدرجة',
                      helperText: 'من ${widget.totalMarks}',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.save_outlined, color: AppColors.primary),
                  onPressed: _save,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ExamAttendance.values
                  .map((a) => ChoiceChip(
                        label: Text(a.arabicLabel),
                        selected: _attendance == a,
                        onSelected: (_) => setState(() => _attendance = a),
                      ))
                  .toList(),
            ),
            if (grade.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (passed ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$grade · ${passed ? 'ناجحة' : 'راسبة'}',
                      style: TextStyle(
                        color: passed ? AppColors.success : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _feedbackController,
              minLines: 1,
              maxLines: 3,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                labelText: 'ملاحظة للطالبة (اختياري)',
                isDense: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
