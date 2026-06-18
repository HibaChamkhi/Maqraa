import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';

/// الرئيسية — overview dashboard matching the «ورْد» reference.
class TeacherOverviewPage extends StatefulWidget {
  final AppUser user;
  final List<Circle> circles;
  const TeacherOverviewPage(
      {super.key, required this.user, required this.circles});

  @override
  State<TeacherOverviewPage> createState() => _TeacherOverviewPageState();
}

class _Status {
  int excellent = 0, good = 0, average = 0, follow = 0;
  int get total => excellent + good + average + follow;
}

class _Data {
  final int totalStudents;
  final int avgPercent;
  final int memorizedJuz;
  final int circleCount;
  final _Status circleStatus;
  final List<double?> thisWeek;
  final List<double?> lastWeek;
  final List<({String title, String circle, DateTime at})> tasks;
  _Data(this.totalStudents, this.avgPercent, this.memorizedJuz,
      this.circleCount, this.circleStatus, this.thisWeek, this.lastWeek, this.tasks);
}

class _TeacherOverviewPageState extends State<TeacherOverviewPage> {
  late final Future<_Data> _future = _load();

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Future<_Data> _load() async {
    final circleRepo = getIt<CircleRepository>();
    final calRepo = getIt<CalendarRepository>();
    final fs = getIt<FirebaseFirestore>();
    final uid = getIt<FirebaseAuth>().currentUser?.uid;
    final circles = widget.circles;

    final members = await Future.wait(circles.map((c) async {
      try {
        return await circleRepo.getMembers(c.id);
      } catch (_) {
        return <CircleMember>[];
      }
    }));
    final sessions = await Future.wait(circles.map((c) async {
      try {
        return await calRepo.getSessions(c.id);
      } catch (_) {
        return <Session>[];
      }
    }));

    var totalStudents = 0, totalPercent = 0, totalPages = 0;
    final status = _Status();
    final tasks = <({String title, String circle, DateTime at})>[];

    for (var i = 0; i < circles.length; i++) {
      final students = members[i]
          .where((m) => m.role == UserRole.student && m.status == MemberStatus.active)
          .toList();
      totalStudents += students.length;
      var sum = 0;
      for (final s in students) {
        totalPercent += s.memorizedPercent;
        totalPages += s.memorizedPages;
        sum += s.memorizedPercent;
      }
      final avg = students.isEmpty ? 0 : (sum / students.length).round();
      if (avg >= 85) {
        status.excellent++;
      } else if (avg >= 70) {
        status.good++;
      } else if (avg >= 50) {
        status.average++;
      } else {
        status.follow++;
      }
      for (final ses in sessions[i]) {
        if (_isToday(ses.scheduledAt)) {
          tasks.add((title: ses.title, circle: circles[i].name, at: ses.scheduledAt));
        }
      }
    }
    tasks.sort((a, b) => a.at.compareTo(b.at));
    final avgPercent = totalStudents == 0 ? 0 : (totalPercent / totalStudents).round();

    // --- daily history snapshot (real week-over-week data) ---
    final thisWeek = List<double?>.filled(7, null);
    final lastWeek = List<double?>.filled(7, null);
    if (uid != null) {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday % 7));
      final lastWeekStart = weekStart.subtract(const Duration(days: 7));
      final col = fs.collection('users').doc(uid).collection('dailyStats');
      try {
        // write today's snapshot
        final todayId = DateFormat('yyyy-MM-dd').format(now);
        await col.doc(todayId).set(
            {'avg': avgPercent, 'date': Timestamp.fromDate(now)},
            SetOptions(merge: true));
        // read history (one tiny doc per day)
        final snap = await col.get();
        for (final doc in snap.docs) {
          final ts = (doc.data()['date'] as Timestamp?)?.toDate();
          final avgV = (doc.data()['avg'] as num?)?.toDouble();
          if (ts == null || avgV == null) continue;
          final day = DateTime(ts.year, ts.month, ts.day);
          final idx = day.weekday % 7;
          if (!day.isBefore(weekStart)) {
            thisWeek[idx] = avgV;
          } else if (!day.isBefore(lastWeekStart)) {
            lastWeek[idx] = avgV;
          }
        }
      } catch (_) {/* history is best-effort */}
    }

    return _Data(totalStudents, avgPercent, (totalPages / 20).round(),
        circles.length, status, thisWeek, lastWeek, tasks);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Data>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('تعذّر تحميل لوحة المعلومات',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        }
        final d = snap.data!;
        final wide = MediaQuery.of(context).size.width >= 900;
        final progress = _ProgressCard(thisWeek: d.thisWeek, lastWeek: d.lastWeek);
        final donut = _StatusDonut(status: d.circleStatus, circleCount: d.circleCount);
        final tasks = _TasksCard(tasks: d.tasks);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Welcome(name: widget.user.name),
            const SizedBox(height: AppSpacing.md),
            _StatsRow(d: d),
            const SizedBox(height: AppSpacing.md),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: progress),
                    const SizedBox(width: 12),
                    Expanded(child: donut),
                    const SizedBox(width: 12),
                    Expanded(child: tasks),
                  ],
                ),
              )
            else ...[
              progress,
              const SizedBox(height: AppSpacing.md),
              donut,
              const SizedBox(height: AppSpacing.md),
              tasks,
            ],
          ],
        );
      },
    );
  }
}

// ---------- shared card shell with soft shadow ----------
class _Shell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Shell({required this.child, this.padding = const EdgeInsets.all(AppSpacing.md)});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1F2937), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardShell({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ---------- welcome ----------
class _Welcome extends StatelessWidget {
  final String name;
  const _Welcome({required this.name});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Shell(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحبًا $name', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('استمر في متابعة طلابك وتحفيزهم', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
                color: AppColors.sky, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Icon(Icons.spa_outlined, color: AppColors.primary, size: 32),
          ),
        ],
      ),
    );
  }
}

// ---------- stat cards ----------
class _StatsRow extends StatelessWidget {
  final _Data d;
  const _StatsRow({required this.d});
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(icon: Icons.groups_2_outlined, value: '${d.totalStudents}', unit: 'طالب', label: 'إجمالي الطلاب', delta: 'هذا الأسبوع'),
      _StatTile(icon: Icons.speed_outlined, value: '${d.avgPercent}%', unit: '', label: 'معدل الحفظ', delta: 'المتوسط العام'),
      _StatTile(icon: Icons.menu_book_outlined, value: '${d.memorizedJuz}', unit: 'جزءًا', label: 'الأجزاء المحفوظة', delta: 'مجموع الطلاب'),
      _StatTile(icon: Icons.workspaces_outline, value: '${d.circleCount}', unit: 'حلقات', label: 'الحلقات النشطة', delta: 'نشطة الآن'),
    ];
    return LayoutBuilder(builder: (context, c) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: c.maxWidth >= 900 ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 128,
        children: tiles,
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value, unit, label, delta;
  const _StatTile({required this.icon, required this.value, required this.unit, required this.label, required this.delta});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textMuted))),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: AppColors.sky, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_upward, size: 13, color: AppColors.primary),
              const SizedBox(width: 3),
              Text(delta, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- progress chart (two area lines) ----------
class _ProgressCard extends StatelessWidget {
  final List<double?> thisWeek;
  final List<double?> lastWeek;
  const _ProgressCard({required this.thisWeek, required this.lastWeek});
  static const _days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

  List<FlSpot> _spots(List<double?> a) =>
      [for (var i = 0; i < 7; i++) if (a[i] != null) FlSpot(i.toDouble(), a[i]!)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thisSpots = _spots(thisWeek);
    final lastSpots = _spots(lastWeek);
    return _CardShell(
      title: 'تقدّم الحفظ (جميع الحلقات)',
      child: Column(
        children: [
          Row(
            children: [
              _legend(AppColors.primary, 'هذا الأسبوع'),
              const SizedBox(width: 16),
              _legend(AppColors.teal, 'الأسبوع الماضي'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: (thisSpots.isEmpty && lastSpots.isEmpty)
                ? Center(child: Text('سيظهر التقدّم بعد تسجيل الحفظ يوميًا', style: theme.textTheme.bodySmall))
                : LineChart(LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, interval: 25, reservedSize: 34,
                              getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 26, getTitlesWidget: (v, _) {
                        // Only label whole-number positions (0..6); fl_chart
                        // otherwise emits fractional ticks that repeat a label.
                        if (v != v.roundToDouble()) return const SizedBox.shrink();
                        final i = v.toInt();
                        if (i < 0 || i > 6) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 6), child: Text(_days[i], style: const TextStyle(fontSize: 9, color: AppColors.ink)));
                      })),
                    ),
                    lineBarsData: [
                      if (lastSpots.isNotEmpty)
                        _bar(lastSpots, AppColors.teal),
                      if (thisSpots.isNotEmpty)
                        _bar(thisSpots, AppColors.primary),
                    ],
                  )),
          ),
        ],
      ),
    );
  }

  LineChartBarData _bar(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
      );

  Widget _legend(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ]);
}

// ---------- donut ----------
class _StatusDonut extends StatelessWidget {
  final _Status status;
  final int circleCount;
  const _StatusDonut({required this.status, required this.circleCount});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <({String label, int count, Color color})>[
      (label: 'ممتاز', count: status.excellent, color: AppColors.success),
      (label: 'جيد', count: status.good, color: AppColors.teal),
      (label: 'متوسط', count: status.average, color: AppColors.warning),
      (label: 'يحتاج متابعة', count: status.follow, color: AppColors.error),
    ].where((e) => e.count > 0).toList();
    return _CardShell(
      title: 'حالة الحلقات',
      child: status.total == 0
          ? Text('لا توجد حلقات بعد', style: theme.textTheme.bodySmall)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: Stack(alignment: Alignment.center, children: [
                    PieChart(PieChartData(
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      sections: [
                        for (final e in entries)
                          PieChartSectionData(value: e.count.toDouble(), color: e.color, showTitle: false, radius: 20),
                      ],
                    )),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$circleCount', style: theme.textTheme.headlineSmall),
                      Text('حلقات', style: theme.textTheme.bodySmall),
                    ]),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.label, style: theme.textTheme.bodySmall)),
                            Text('${e.count}', style: theme.textTheme.titleSmall),
                          ]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------- tasks ----------
class _TasksCard extends StatelessWidget {
  final List<({String title, String circle, DateTime at})> tasks;
  const _TasksCard({required this.tasks});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('h:mm a', 'ar');
    return _CardShell(
      title: 'مهام اليوم',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('لا توجد مهام اليوم', style: theme.textTheme.bodySmall),
            )
          else
            for (final t in tasks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  const Icon(Icons.check_box_outline_blank, size: 20, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${t.title} · ${t.circle}', style: theme.textTheme.titleSmall),
                      Text(fmt.format(t.at), style: theme.textTheme.bodySmall),
                    ]),
                  ),
                ]),
              ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () {}, child: const Text('عرض كل المهام')),
          ),
        ],
      ),
    );
  }
}
