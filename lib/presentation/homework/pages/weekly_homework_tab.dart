import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/homework/models/weekly_homework.dart';

/// «الواجب الأسبوعي» — the الجدول tab. Teacher fills الواجب + ملاحظات per day
/// for the week; each student ticks «تمّ» (with رفيقتها). Per-circle.
class WeeklyHomeworkTab extends StatefulWidget {
  final Circle circle;
  final AppUser user;
  final bool canManage;
  const WeeklyHomeworkTab(
      {super.key,
      required this.circle,
      required this.user,
      required this.canManage});

  @override
  State<WeeklyHomeworkTab> createState() => _WeeklyHomeworkTabState();
}

class _WeeklyHomeworkTabState extends State<WeeklyHomeworkTab> {
  late final HomeworkRepository _repo =
      HomeworkRepository(getIt<FirebaseFirestore>(), getIt<FirebaseAuth>());
  late DateTime _weekStart = WeeklyHomework.weekStartOf(DateTime.now());

  String get _weekId => DateFormat('yyyy-MM-dd').format(_weekStart);

  void _shift(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('d MMM', 'ar');
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_right)),
              Text('${fmt.format(_weekStart)} – ${fmt.format(weekEnd)}',
                  style: theme.textTheme.titleMedium),
              IconButton(
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_left)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<WeeklyHomework>(
            stream: _repo.weekStream(widget.circle.id, _weekId, _weekStart),
            builder: (context, weekSnap) {
              final week = weekSnap.data ??
                  WeeklyHomework(weekId: _weekId, weekStart: _weekStart);
              return StreamBuilder<List<HomeworkCompletion>>(
                stream:
                    _repo.completionsStream(widget.circle.id, _weekId),
                builder: (context, compSnap) {
                  final comps = compSnap.data ?? const [];
                  final mine = comps
                      .where((c) => c.uid == widget.user.uid)
                      .cast<HomeworkCompletion?>()
                      .fold<HomeworkCompletion?>(null, (p, e) => e);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                    children: [
                      for (final code in WeeklyHomework.dayOrder)
                        _DayCard(
                          code: code,
                          date: week.dateOf(code),
                          plan: week.planOf(code),
                          canManage: widget.canManage,
                          doneCount:
                              comps.where((c) => c.isDone(code)).length,
                          myDone: mine?.isDone(code) ?? false,
                          myPartner: mine?.partners[code] ?? '',
                          onEdit: widget.canManage
                              ? () => _editDay(week, code)
                              : null,
                          onTick: widget.canManage
                              ? null
                              : () => _tickDay(code, mine?.isDone(code) ?? false,
                                  mine?.partners[code] ?? ''),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editDay(WeeklyHomework week, String code) async {
    final plan = week.planOf(code);
    final wajib = TextEditingController(text: plan.wajib);
    final notes = TextEditingController(text: plan.notes);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${WeeklyHomework.dayLabels[code]} — الواجب'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wajib,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الواجب'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.saveDay(
        circleId: widget.circle.id,
        weekId: _weekId,
        weekStart: _weekStart,
        dayCode: code,
        wajib: wajib.text,
        notes: notes.text,
      );
    }
  }

  Future<void> _tickDay(String code, bool currentlyDone, String partner) async {
    if (currentlyDone) {
      await _repo.setDayDone(
        circleId: widget.circle.id,
        weekId: _weekId,
        dayCode: code,
        done: false,
        studentName: widget.user.name,
      );
      return;
    }
    final partnerC = TextEditingController(text: partner);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد إنجاز واجب ${WeeklyHomework.dayLabels[code]}'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: partnerC,
            decoration: const InputDecoration(
                labelText: 'سمّعت على رفيقتي (اختياري)'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تمّ ✓')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.setDayDone(
        circleId: widget.circle.id,
        weekId: _weekId,
        dayCode: code,
        done: true,
        partnerName: partnerC.text.trim(),
        studentName: widget.user.name,
      );
    }
  }
}

class _DayCard extends StatelessWidget {
  final String code;
  final DateTime date;
  final DayPlan plan;
  final bool canManage;
  final int doneCount;
  final bool myDone;
  final String myPartner;
  final VoidCallback? onEdit;
  final VoidCallback? onTick;
  const _DayCard({
    required this.code,
    required this.date,
    required this.plan,
    required this.canManage,
    required this.doneCount,
    required this.myDone,
    required this.myPartner,
    this.onEdit,
    this.onTick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dFmt = DateFormat('d MMM', 'ar');
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: isToday ? AppColors.primary : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(WeeklyHomework.dayLabels[code]!,
                      style: theme.textTheme.titleSmall),
                  Text(dFmt.format(date),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.wajib.isEmpty ? '— لا واجب —' : plan.wajib,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: plan.wajib.isEmpty
                              ? AppColors.textMuted
                              : AppColors.ink)),
                  if (plan.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(plan.notes,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                  ],
                  if (!canManage && myDone && myPartner.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('رفيقتي: $myPartner',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.primary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (canManage)
              Column(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                  Text('تمّ $doneCount',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.success)),
                ],
              )
            else
              IconButton(
                onPressed: plan.wajib.isEmpty ? null : onTick,
                icon: Icon(
                  myDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: myDone ? AppColors.success : AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
