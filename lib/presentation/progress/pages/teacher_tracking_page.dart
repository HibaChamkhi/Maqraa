import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../bloc/progress_bloc.dart';

/// US-12: teacher dashboard — who submitted today vs who is late, plus each
/// student's attendance % over the last 4 weeks (loaded once as a batch).
class TeacherTrackingPage extends StatefulWidget {
  final String circleId;

  const TeacherTrackingPage({super.key, required this.circleId});

  @override
  State<TeacherTrackingPage> createState() => _TeacherTrackingPageState();
}

class _TeacherTrackingPageState extends State<TeacherTrackingPage> {
  late final Future<Map<String, int?>> _rates = _loadRates();

  static const _order = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];

  /// One batched read of the last 4 weeks → attendance % per student uid.
  Future<Map<String, int?>> _loadRates() async {
    final repo = getIt<CircleRepository>();
    final circle = await repo.getCircle(widget.circleId);
    final days = circle.days.isNotEmpty ? circle.days : _order;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSat = (today.weekday - DateTime.saturday) % 7;
    final thisWeekStart = today.subtract(Duration(days: daysSinceSat));
    final dateIds = <String>[];
    for (var w = 0; w < 4; w++) {
      final ws = thisWeekStart.subtract(Duration(days: 7 * w));
      for (final d in days) {
        final idx = _order.indexOf(d);
        if (idx < 0) continue;
        final date = ws.add(Duration(days: idx));
        if (!date.isAfter(today)) {
          dateIds.add(DateFormat('yyyy-MM-dd').format(date));
        }
      }
    }
    final data =
        await repo.getWeekAttendance(circleId: widget.circleId, dateIds: dateIds);
    final counts = <String, List<int>>{}; // uid -> [present, recorded]
    for (final id in dateIds) {
      (data[id] ?? const <String, AttendanceState>{}).forEach((uid, st) {
        final c = counts.putIfAbsent(uid, () => [0, 0]);
        c[1]++;
        if (st == AttendanceState.present || st == AttendanceState.late_) {
          c[0]++;
        }
      });
    }
    return counts.map((uid, c) =>
        MapEntry(uid, c[1] == 0 ? null : (c[0] / c[1] * 100).round()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ProgressBloc>()..add(LoadTodaySubmissions(widget.circleId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('متابعة التسليم اليومي')),
        body: FutureBuilder<Map<String, int?>>(
          future: _rates,
          builder: (context, rateSnap) {
            final rates = rateSnap.data ?? const <String, int?>{};
            return BlocBuilder<ProgressBloc, ProgressState>(
              builder: (context, state) {
                if (state.status == UIStatus.loading &&
                    state.submissions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.submissions.isEmpty) {
                  return const Center(
                      child: Text('لا توجد طالبات في الحلقة بعد'));
                }
                final done = state.submissions.where((s) => s.done).length;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'سلّمت اليوم: $done من ${state.submissions.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: state.submissions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = state.submissions[i];
                          final pct = rates[s.uid];
                          final pctLabel = !rateSnap.hasData
                              ? '…'
                              : (pct == null ? '—' : '$pct%');
                          return ListTile(
                            leading: Icon(
                              s.done ? Icons.check_circle : Icons.schedule,
                              color: s.done ? Colors.green : Colors.orange,
                            ),
                            title: Text(s.name),
                            subtitle: Text('نسبة الحضور (٤ أسابيع): $pctLabel'),
                            trailing: Text(s.done ? 'سلّمت' : 'متأخرة'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
