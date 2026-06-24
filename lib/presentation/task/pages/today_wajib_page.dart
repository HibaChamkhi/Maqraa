import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../data/homework/homework_repository.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/homework/models/weekly_homework.dart';

/// «واجب اليوم» for a student: today's واجبات across ALL her حلقات (from the
/// homework plan), each tickable — no حلقة picker, the cards show directly.
class TodayWajibPage extends StatefulWidget {
  final AppUser user;
  const TodayWajibPage({super.key, required this.user});

  @override
  State<TodayWajibPage> createState() => _TodayWajibPageState();
}

class _Item {
  final String circleId;
  final String circleName;
  final DayPlan plan;
  final bool done;
  const _Item(this.circleId, this.circleName, this.plan, this.done);
}

class _TodayWajibPageState extends State<TodayWajibPage> {
  late Future<List<_Item>> _future = _load();
  final Map<String, bool> _override = {};

  HomeworkRepository get _hw =>
      HomeworkRepository(getIt<FirebaseFirestore>(), getIt<FirebaseAuth>());

  DateTime get _weekStart => WeeklyHomework.weekStartOf(DateTime.now());
  String get _weekId => DateFormat('yyyy-MM-dd').format(_weekStart);

  String _todayCode() {
    const map = {
      DateTime.saturday: 'sat',
      DateTime.sunday: 'sun',
      DateTime.monday: 'mon',
      DateTime.tuesday: 'tue',
      DateTime.wednesday: 'wed',
      DateTime.thursday: 'thu',
      DateTime.friday: 'fri',
    };
    return map[DateTime.now().weekday] ?? 'sat';
  }

  Future<List<_Item>> _load() async {
    final out = <_Item>[];
    try {
      final circles = await getIt<CircleRepository>().getMyCircles();
      final code = _todayCode();
      for (final c in circles) {
        try {
          final wk = await _hw.weekStream(c.id, _weekId, _weekStart).first;
          final plan = wk.planOf(code);
          if (!plan.isEmpty) {
            final comp = await _hw.myCompletion(c.id, _weekId);
            out.add(_Item(c.id, c.name, plan, comp.isDone(code)));
          }
        } catch (_) {/* skip */}
      }
    } catch (_) {/* circles optional */}
    return out;
  }

  Future<void> _toggle(_Item item) async {
    final cur = _override[item.circleId] ?? item.done;
    setState(() => _override[item.circleId] = !cur);
    var ok = true;
    try {
      await _hw.setDayDone(
        circleId: item.circleId,
        weekId: _weekId,
        dayCode: _todayCode(),
        done: !cur,
        studentName: widget.user.name,
      );
    } catch (_) {
      ok = false;
      if (mounted) setState(() => _override[item.circleId] = cur);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: ok
            ? (!cur ? AppColors.success : AppColors.textMuted)
            : AppColors.error,
        content: Text(ok
            ? (!cur ? 'تم تسجيل التسليم — ستراه المعلّمة' : 'أُلغي التسليم')
            : 'تعذّر حفظ التسليم، حاولي مجددًا'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLine = DateFormat('EEEE d MMMM yyyy', 'ar').format(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(title: const Text('واجب اليوم')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {
          _override.clear();
          _future = _load();
        }),
        child: FutureBuilder<List<_Item>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            final done =
                items.where((it) => _override[it.circleId] ?? it.done).length;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$dateLine م',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('$done / ${items.length} مكتمل',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.coffee_outlined,
                            size: 54, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('لا يوجد تكليف لهذا اليوم',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  )
                else
                  for (final it in items) ...[
                    _card(it),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(_Item item) {
    final done = _override[item.circleId] ?? item.done;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggle(item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: done ? AppColors.success : AppColors.primary,
                    width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('حلقة ${item.circleName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    if (item.plan.type.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.sky,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(item.plan.type,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.plan.wajib.isNotEmpty ? item.plan.wajib : 'واجب اليوم',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted)),
                if (item.plan.notes.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('ملاحظة المعلّمة: ${item.plan.notes}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: done ? const Color(0xFFE1F5EE) : AppColors.gray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(done ? 'تم التسليم' : 'بانتظار التسليم',
                      style: TextStyle(
                          fontSize: 11,
                          color: done
                              ? const Color(0xFF0F6E56)
                              : AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
