import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';

/// الرئيسية — overview dashboard aggregated across ALL the teacher's circles,
/// laid out to match the «ورْد» reference (welcome, stat cards, progress chart,
/// circle-status donut, today's tasks). Responsive: 3-column on wide screens.
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
  final List<double> week; // recitations per weekday (Sun..Sat)
  final List<({String title, String circle, DateTime at})> tasks;

  _Data(this.totalStudents, this.avgPercent, this.memorizedJuz,
      this.circleCount, this.circleStatus, this.week, this.tasks);
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
    final circles = widget.circles;
    final members =
        await Future.wait(circles.map((c) => circleRepo.getMembers(c.id)));
    final sessions =
        await Future.wait(circles.map((c) => calRepo.getSessions(c.id)));

    var totalStudents = 0, totalPercent = 0, totalPages = 0;
    final status = _Status();
    final week = List<double>.filled(7, 0);
    final tasks = <({String title, String circle, DateTime at})>[];
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));

    for (var i = 0; i < circles.length; i++) {
      final students = members[i]
          .where((m) =>
              m.role == UserRole.student && m.status == MemberStatus.active)
          .toList();
      totalStudents += students.length;
      var sum = 0;
      for (final s in students) {
        totalPercent += s.memorizedPercent;
        totalPages += s.memorizedPages;
        sum += s.memorizedPercent;
        final last = s.lastRecitationAt;
        if (last != null && !last.isBefore(weekStart)) {
          week[last.weekday % 7] += 1;
        }
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
          tasks.add(
              (title: ses.title, circle: circles[i].name, at: ses.scheduledAt));
        }
      }
    }
    tasks.sort((a, b) => a.at.compareTo(b.at));
    return _Data(
      totalStudents,
      totalStudents == 0 ? 0 : (totalPercent / totalStudents).round(),
      (totalPages / 20).round(),
      circles.length,
      status,
      week,
      tasks,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Data>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        final wide = MediaQuery.of(context).size.width >= 900;
        final charts = [
          _ProgressCard(week: d.week),
          _StatusDonut(status: d.circleStatus, circleCount: d.circleCount),
          _TasksCard(tasks: d.tasks),
        ];
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
                    Expanded(flex: 2, child: charts[0]),
                    const SizedBox(width: 12),
                    Expanded(child: charts[1]),
                    const SizedBox(width: 12),
                    Expanded(child: charts[2]),
                  ],
                ),
              )
            else ...[
              charts[0],
              const SizedBox(height: AppSpacing.md),
              charts[1],
              const SizedBox(height: AppSpacing.md),
              charts[2],
            ],
          ],
        );
      },
    );
  }
}

// ---- Welcome row (light, with plant) ----
class _Welcome extends StatelessWidget {
  final String name;
  const _Welcome({required this.name});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: AppColors.sky, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Icon(Icons.spa_outlined, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحبًا $name',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('استمر في متابعة طلابك وتحفيزهم',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- 4 stat tiles ----
class _StatsRow extends StatelessWidget {
  final _Data d;
  const _StatsRow({required this.d});
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(icon: Icons.groups_2_outlined, value: '${d.totalStudents}', unit: 'طالب', label: 'إجمالي الطلاب', delta: 'في كل الحلقات'),
      _StatTile(icon: Icons.speed_outlined, value: '${d.avgPercent}%', unit: '', label: 'معدل الحفظ', delta: 'المتوسط العام'),
      _StatTile(icon: Icons.menu_book_outlined, value: '${d.memorizedJuz}', unit: 'جزءًا', label: 'الأجزاء المحفوظة', delta: 'مجموع الطلاب'),
      _StatTile(icon: Icons.workspaces_outline, value: '${d.circleCount}', unit: 'حلقات', label: 'الحلقات النشطة', delta: 'نشطة الآن'),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 124, // fixed compact height regardless of width
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Icon(icon, size: 18, color: AppColors.primary),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: theme.textTheme.headlineMedium),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(delta,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ---- Progress line/area chart ----
class _ProgressCard extends StatelessWidget {
  final List<double> week;
  const _ProgressCard({required this.week});
  static const _days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = (week.fold<double>(4, (m, v) => v > m ? v : m)).ceilToDouble();
    return _CardShell(
      title: 'نشاط التسميع هذا الأسبوع',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY / 4).clamp(1, 1000)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: (maxY / 4).clamp(1, 1000),
                      getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 26, getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i > 6) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 6), child: Text(_days[i], style: const TextStyle(fontSize: 9, color: AppColors.ink)));
              })),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < 7; i++) FlSpot(i.toDouble(), week[i])],
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Circle status donut ----
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
          : Column(
              children: [
                SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        centerSpaceRadius: 44,
                        sectionsSpace: 2,
                        sections: [
                          for (final e in entries)
                            PieChartSectionData(value: e.count.toDouble(), color: e.color, showTitle: false, radius: 22),
                        ],
                      )),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$circleCount', style: theme.textTheme.headlineSmall),
                          Text('حلقات', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.label, style: theme.textTheme.bodySmall)),
                      Text('${e.count}', style: theme.textTheme.titleSmall),
                    ]),
                  ),
              ],
            ),
    );
  }
}

// ---- Today's tasks ----
class _TasksCard extends StatelessWidget {
  final List<({String title, String circle, DateTime at})> tasks;
  const _TasksCard({required this.tasks});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('h:mm a', 'ar');
    return _CardShell(
      title: 'مهام اليوم',
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('لا توجد مهام اليوم', style: theme.textTheme.bodySmall))
          : Column(
              children: [
                for (final t in tasks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outline_blank, size: 20, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${t.title} · ${t.circle}', style: theme.textTheme.titleSmall),
                              Text(fmt.format(t.at), style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardShell({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
