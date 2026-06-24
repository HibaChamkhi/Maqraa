import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/util/notify.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/homework/models/weekly_homework.dart';
import '../../../domain/notification/models/app_notification.dart';

/// «الجدول الأسبوعي» — a weekly plan grid (3 columns): day+date, الواجب, ملاحظات.
/// The teacher fills it; the student taps her row to confirm «تمّ» (the
/// completion analytics live in التقارير, not here).
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
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right,
                      textDirection: TextDirection.ltr)),
              Text('${fmt.format(_weekStart)} – ${fmt.format(weekEnd)}',
                  style: theme.textTheme.titleMedium),
              IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left,
                      textDirection: TextDirection.ltr)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<WeeklyHomework>(
            stream: _repo.weekStream(widget.circle.id, _weekId, _weekStart),
            builder: (context, weekSnap) {
              final week = weekSnap.data ??
                  WeeklyHomework(weekId: _weekId, weekStart: _weekStart);
              if (widget.canManage) {
                return _grid(week, myDone: const {});
              }
              // student: also watch own completion for the personal ✓
              return StreamBuilder<List<HomeworkCompletion>>(
                stream: _repo.completionsStream(widget.circle.id, _weekId),
                builder: (context, compSnap) {
                  final comps = compSnap.data ?? const [];
                  final mine = comps
                      .where((c) => c.uid == widget.user.uid)
                      .fold<HomeworkCompletion?>(null, (p, e) => e);
                  return _grid(week, myDone: mine?.doneDays ?? const {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _grid(WeeklyHomework week, {required Set<String> myDone}) {
    Widget head(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(children: [
                head('اليوم والتاريخ', 3),
                head('الواجب', 4),
                head('ملاحظات', 3),
              ]),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final code in WeeklyHomework.dayOrder)
                    _DayRow(
                      code: code,
                      date: week.dateOf(code),
                      plan: week.planOf(code),
                      canManage: widget.canManage,
                      myDone: myDone.contains(code),
                      onEdit: () => _editDay(week, code),
                      onTick: () => _tickDay(code, myDone.contains(code)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      if (wajib.text.trim().isNotEmpty) {
        await notifyCircleStudents(
          circleId: widget.circle.id,
          title: 'واجب جديد',
          body:
              'أضافت المعلّمة واجب ${WeeklyHomework.dayLabels[code] ?? ''} في حلقة ${widget.circle.name} — تفقّدي واجباتك',
          type: NotificationType.homework,
        );
      }
    }
  }

  Future<void> _tickDay(String code, bool done) async {
    if (done) {
      await _repo.setDayDone(
        circleId: widget.circle.id,
        weekId: _weekId,
        dayCode: code,
        done: false,
        studentName: widget.user.name,
      );
      return;
    }
    final partnerC = TextEditingController();
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

class _DayRow extends StatelessWidget {
  final String code;
  final DateTime date;
  final DayPlan plan;
  final bool canManage;
  final bool myDone;
  final VoidCallback onEdit;
  final VoidCallback onTick;
  const _DayRow({
    required this.code,
    required this.date,
    required this.plan,
    required this.canManage,
    required this.myDone,
    required this.onEdit,
    required this.onTick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dFmt = DateFormat('d MMM', 'ar');
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final empty = plan.wajib.isEmpty;

    return InkWell(
      onTap: canManage ? onEdit : (empty ? null : onTick),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isToday ? AppColors.sky : null,
          border: const Border(
              top: BorderSide(color: AppColors.border, width: .5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(WeeklyHomework.dayLabels[code]!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (isToday) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(99)),
                        child: const Text('اليوم',
                            style:
                                TextStyle(color: Colors.white, fontSize: 8)),
                      ),
                    ],
                  ]),
                  Text(dFmt.format(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted, fontSize: 10)),
                  if (!canManage && myDone)
                    Row(children: const [
                      Icon(Icons.check_circle,
                          size: 12, color: AppColors.success),
                      SizedBox(width: 3),
                      Text('تمّ',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.success)),
                    ]),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(empty ? (canManage ? '— اضغطي للإضافة —' : '—') : plan.wajib,
                  style: empty
                      ? theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted)
                      : theme.textTheme.bodyMedium),
            ),
            Expanded(
              flex: 3,
              child: Text(plan.notes.isEmpty ? '—' : plan.notes,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: plan.notes.isEmpty
                          ? AppColors.textMuted
                          : AppColors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
