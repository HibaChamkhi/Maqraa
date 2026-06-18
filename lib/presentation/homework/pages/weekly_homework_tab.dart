import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/homework/models/weekly_homework.dart';

/// «الجدول الأسبوعي» — weekly homework grid. Teacher fills الواجب/النوع/ملاحظات
/// per day; التمام shows done/total (tap → who). Student taps a row to confirm.
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
  List<CircleMember> _students = const [];

  String get _weekId => DateFormat('yyyy-MM-dd').format(_weekStart);

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final members =
          await getIt<CircleRepository>().getMembers(widget.circle.id);
      if (!mounted) return;
      setState(() => _students = members
          .where((m) =>
              m.role == UserRole.student && m.status == MemberStatus.active)
          .toList());
    } catch (_) {/* best effort */}
  }

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
                stream: _repo.completionsStream(widget.circle.id, _weekId),
                builder: (context, compSnap) {
                  final comps = compSnap.data ?? const [];
                  HomeworkCompletion? mine;
                  for (final c in comps) {
                    if (c.uid == widget.user.uid) mine = c;
                  }
                  return _Grid(
                    week: week,
                    comps: comps,
                    total: _students.length,
                    mine: mine,
                    canManage: widget.canManage,
                    onEditDay: (code) => _editDay(week, code),
                    onTickDay: (code) => _tickDay(
                        code,
                        mine?.isDone(code) ?? false,
                        mine?.partners[code] ?? ''),
                    onShowWho: (code) => _showWho(code, comps),
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

  Future<void> _tickDay(String code, bool done, String partner) async {
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

  void _showWho(String code, List<HomeworkCompletion> comps) {
    final doneByUid = {for (final c in comps) c.uid: c};
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('من أنجز واجب ${WeeklyHomework.dayLabels[code]}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in _students)
              ListTile(
                dense: true,
                leading: Icon(
                  (doneByUid[s.uid]?.isDone(code) ?? false)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: (doneByUid[s.uid]?.isDone(code) ?? false)
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
                title: Text(s.name),
                subtitle: (doneByUid[s.uid]?.partners[code] ?? '').isEmpty
                    ? null
                    : Text('رفيقتها: ${doneByUid[s.uid]!.partners[code]}'),
              ),
            if (_students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('لا توجد طالبات بعد'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final WeeklyHomework week;
  final List<HomeworkCompletion> comps;
  final int total;
  final HomeworkCompletion? mine;
  final bool canManage;
  final void Function(String code) onEditDay;
  final void Function(String code) onTickDay;
  final void Function(String code) onShowWho;
  const _Grid({
    required this.week,
    required this.comps,
    required this.total,
    required this.mine,
    required this.canManage,
    required this.onEditDay,
    required this.onTickDay,
    required this.onShowWho,
  });

  static const _flex = [3, 4, 3, 2];

  @override
  Widget build(BuildContext context) {
    Widget head(String t, int i) => Expanded(
        flex: _flex[i],
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)));
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(children: [
                head('اليوم والتاريخ', 0),
                head('الواجب', 1),
                head('ملاحظات', 2),
                head(canManage ? 'التمام' : 'تمّ', 3),
              ]),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final code in WeeklyHomework.dayOrder)
                    _Row(
                      code: code,
                      date: week.dateOf(code),
                      plan: week.planOf(code),
                      doneCount: comps.where((c) => c.isDone(code)).length,
                      total: total,
                      myDone: mine?.isDone(code) ?? false,
                      canManage: canManage,
                      onEdit: () => onEditDay(code),
                      onTick: () => onTickDay(code),
                      onWho: () => onShowWho(code),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String code;
  final DateTime date;
  final DayPlan plan;
  final int doneCount;
  final int total;
  final bool myDone;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onTick;
  final VoidCallback onWho;
  const _Row({
    required this.code,
    required this.date,
    required this.plan,
    required this.doneCount,
    required this.total,
    required this.myDone,
    required this.canManage,
    required this.onEdit,
    required this.onTick,
    required this.onWho,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isToday ? AppColors.sky : null,
          border: const Border(
              top: BorderSide(color: AppColors.border, width: .5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // day + date
            Expanded(
              flex: _Grid._flex[0],
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
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
            // wajib + type chip
            Expanded(
              flex: _Grid._flex[1],
              child: empty
                  ? Text(canManage ? '— اضغطي للإضافة —' : '—',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted))
                  : Text(plan.wajib, style: theme.textTheme.bodyMedium),
            ),
            // notes
            Expanded(
              flex: _Grid._flex[2],
              child: Text(plan.notes.isEmpty ? '—' : plan.notes,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: plan.notes.isEmpty
                          ? AppColors.textMuted
                          : AppColors.ink)),
            ),
            // tamam
            Expanded(
              flex: _Grid._flex[3],
              child: canManage
                  ? GestureDetector(
                      onTap: empty ? null : onWho,
                      child: empty
                          ? const Text('—',
                              style: TextStyle(color: AppColors.textMuted))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${total == 0 ? 0 : (doneCount / total * 100).round()}%',
                                    style: theme.textTheme.bodySmall),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value:
                                        total == 0 ? 0 : doneCount / total,
                                    minHeight: 5,
                                    backgroundColor: AppColors.border,
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                    )
                  : Icon(
                      myDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          myDone ? AppColors.success : AppColors.textMuted,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
