import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/session/models/session.dart';

/// الرئيسية — overview dashboard aggregated across ALL the teacher's circles.
class TeacherOverviewPage extends StatefulWidget {
  final AppUser user;
  final List<Circle> circles;

  const TeacherOverviewPage({super.key, required this.user, required this.circles});

  @override
  State<TeacherOverviewPage> createState() => _TeacherOverviewPageState();
}

class _OverviewData {
  final int totalStudents;
  final int avgMemPercent;
  final int memorizedJuz;
  final int circleCount;
  final Map<PerformanceTag, int> perf;
  final int noRating;
  final List<({String name, int avg})> perCircle;
  final List<({String title, String circle, DateTime at})> todaySessions;

  _OverviewData({
    required this.totalStudents,
    required this.avgMemPercent,
    required this.memorizedJuz,
    required this.circleCount,
    required this.perf,
    required this.noRating,
    required this.perCircle,
    required this.todaySessions,
  });
}

class _TeacherOverviewPageState extends State<TeacherOverviewPage> {
  late Future<_OverviewData> _future = _load();

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Future<_OverviewData> _load() async {
    final circleRepo = getIt<CircleRepository>();
    final calRepo = getIt<CalendarRepository>();
    final circles = widget.circles;

    final membersLists =
        await Future.wait(circles.map((c) => circleRepo.getMembers(c.id)));
    final sessionLists =
        await Future.wait(circles.map((c) => calRepo.getSessions(c.id)));

    var totalStudents = 0;
    var totalPercent = 0;
    var totalPages = 0;
    final perf = <PerformanceTag, int>{};
    var noRating = 0;
    final perCircle = <({String name, int avg})>[];
    final today = <({String title, String circle, DateTime at})>[];

    for (var i = 0; i < circles.length; i++) {
      final students = membersLists[i]
          .where((m) => m.role == UserRole.student && m.status == MemberStatus.active)
          .toList();
      totalStudents += students.length;
      var circleSum = 0;
      for (final s in students) {
        totalPercent += s.memorizedPercent;
        totalPages += s.memorizedPages;
        circleSum += s.memorizedPercent;
        if (s.performance == null) {
          noRating++;
        } else {
          perf[s.performance!] = (perf[s.performance!] ?? 0) + 1;
        }
      }
      perCircle.add((
        name: circles[i].name,
        avg: students.isEmpty ? 0 : (circleSum / students.length).round(),
      ));
      for (final ses in sessionLists[i]) {
        if (_isToday(ses.scheduledAt)) {
          today.add((title: ses.title, circle: circles[i].name, at: ses.scheduledAt));
        }
      }
    }
    today.sort((a, b) => a.at.compareTo(b.at));

    return _OverviewData(
      totalStudents: totalStudents,
      avgMemPercent: totalStudents == 0 ? 0 : (totalPercent / totalStudents).round(),
      memorizedJuz: (totalPages / 20).round(),
      circleCount: circles.length,
      perf: perf,
      noRating: noRating,
      perCircle: perCircle,
      todaySessions: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OverviewData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _banner(context),
            const SizedBox(height: AppSpacing.md),
            _statsGrid(d),
            const SizedBox(height: AppSpacing.md),
            _chartCard(context, d),
            const SizedBox(height: AppSpacing.md),
            _perfCard(context, d),
            const SizedBox(height: AppSpacing.md),
            _tasksCard(context, d),
          ],
        );
      },
    );
  }

  Widget _banner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحبًا ${widget.user.name}',
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('استمر في متابعة طلابك وتحفيزهم',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          const Icon(Icons.spa_outlined, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _statsGrid(_OverviewData d) {
    final cards = [
      StatCard(value: '${d.totalStudents}', label: 'إجمالي الطلاب', icon: Icons.groups_2_outlined),
      StatCard(value: '${d.avgMemPercent}%', label: 'معدل الحفظ', icon: Icons.speed_outlined, accent: AppColors.primaryLight),
      StatCard(value: '${d.memorizedJuz}', label: 'الأجزاء المحفوظة', icon: Icons.menu_book_outlined, accent: AppColors.warning),
      StatCard(value: '${d.circleCount}', label: 'الحلقات النشطة', icon: Icons.workspaces_outline, accent: AppColors.primary),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }

  Widget _chartCard(BuildContext context, _OverviewData d) {
    final theme = Theme.of(context);
    final data = d.perCircle;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'متوسط الحفظ لكل حلقة'),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? Center(child: Text('لا توجد بيانات بعد', style: theme.textTheme.bodySmall))
                  : BarChart(
                      BarChartData(
                        maxY: 100,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 25,
                              reservedSize: 34,
                              getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(data[i].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, color: AppColors.ink)),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < data.length; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: data[i].avg.toDouble(),
                                color: AppColors.primary,
                                width: 18,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ]),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfCard(BuildContext context, _OverviewData d) {
    final theme = Theme.of(context);
    final entries = <({String label, int count, Color color})>[
      (label: 'ممتاز', count: d.perf[PerformanceTag.excellent] ?? 0, color: AppColors.success),
      (label: 'جيد', count: d.perf[PerformanceTag.good] ?? 0, color: AppColors.primaryLight),
      (label: 'متوسط', count: d.perf[PerformanceTag.average] ?? 0, color: AppColors.warning),
      (label: 'يحتاج متابعة', count: d.perf[PerformanceTag.needsFollowUp] ?? 0, color: AppColors.error),
      (label: 'بلا تقييم', count: d.noRating, color: AppColors.textMuted),
    ].where((e) => e.count > 0).toList();
    final total = entries.fold<int>(0, (s, e) => s + e.count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'حالة الطالبات'),
            const SizedBox(height: AppSpacing.md),
            if (total == 0)
              Text('لا توجد طالبات بعد', style: theme.textTheme.bodySmall)
            else
              Row(
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 42,
                        sectionsSpace: 2,
                        sections: [
                          for (final e in entries)
                            PieChartSectionData(
                              value: e.count.toDouble(),
                              color: e.color,
                              title: '${e.count}',
                              radius: 28,
                              titleStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(3))),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.label, style: theme.textTheme.bodyMedium)),
                                Text('${e.count}', style: theme.textTheme.titleSmall),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tasksCard(BuildContext context, _OverviewData d) {
    final theme = Theme.of(context);
    final fmt = DateFormat('h:mm a', 'ar');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'مهام اليوم'),
            const SizedBox(height: 8),
            if (d.todaySessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('لا توجد جلسات اليوم', style: theme.textTheme.bodySmall),
              )
            else
              for (final t in d.todaySessions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.title} · ${t.circle}',
                                style: theme.textTheme.titleSmall),
                            Text(fmt.format(t.at), style: theme.textTheme.bodySmall),
                          ],
                        ),
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
