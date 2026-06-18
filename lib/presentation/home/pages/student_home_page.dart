import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/progress/models/progress_info.dart';
import '../../../domain/progress/repositories/progress_repository.dart';
import '../../../domain/schedule/repositories/schedule_repository.dart';
import '../../notification/pages/notifications_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../progress/pages/my_progress_page.dart';
import '../../reminder/pages/reminder_settings_page.dart';
import '../../schedule/pages/weekly_schedule_page.dart';
import '../../task/pages/today_task_page.dart';

/// Student experience matching the «وِرد» mobile mockups: a quick daily
/// overview with a bottom navigation bar.
class StudentHomePage extends StatefulWidget {
  final AppUser user;
  final Circle circle;
  final Widget more;

  const StudentHomePage({
    super.key,
    required this.user,
    required this.circle,
    required this.more,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(user: widget.user, circle: widget.circle),
      WeeklySchedulePage(circleId: widget.circle.id),
      const MyProgressPage(),
      widget.more,
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'الحلقات'),
          NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined),
              selectedIcon: Icon(Icons.insert_chart_rounded),
              label: 'التقارير'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }
}

/// Holds the fetched-once data for the home tab.
typedef _HomeData = ({ProgressInfo progress, String todayRange});

class _HomeTab extends StatefulWidget {
  final AppUser user;
  final Circle circle;
  const _HomeTab({required this.user, required this.circle});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final progress = await getIt<ProgressRepository>().getMyProgress();
    String range = '';
    try {
      final now = DateTime.now();
      final saturday = now.subtract(Duration(days: (now.weekday) % 7));
      final weekId =
          '${saturday.year}-${saturday.month.toString().padLeft(2, '0')}-${saturday.day.toString().padLeft(2, '0')}';
      final schedule = await getIt<ScheduleRepository>()
          .getSchedule(circleId: widget.circle.id, weekId: weekId);
      range = schedule?.days[_todayCode()] ?? '';
    } catch (_) {/* schedule optional */}
    return (progress: progress, todayRange: range);
  }

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

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = widget.circle.id;

    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snap) {
          final progress = snap.data?.progress;
          final todayRange = snap.data?.todayRange ?? '';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Header(user: widget.user, onProfile: () => _open(const ProfilePage())),
              const SizedBox(height: AppSpacing.lg),

              // واجب اليوم
              _TodayTaskCard(
                range: todayRange,
                onTap: () => _open(TodayTaskPage(circleId: id, user: widget.user)),
              ),
              const SizedBox(height: AppSpacing.md),

              // تقدمي العام
              _ProgressCard(
                progress: progress,
                onTap: () => _open(const MyProgressPage()),
              ),
              const SizedBox(height: AppSpacing.lg),

              // التذكيرات
              SectionHeader(
                title: 'التذكيرات',
                actionLabel: 'الكل',
                onAction: () => _open(const ReminderSettingsPage()),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _InfoTile(
                icon: Icons.notifications_active_outlined,
                title: 'مراجعة الحفظ',
                subtitle: 'اليوم • 7:00 م',
              ),
              const SizedBox(height: AppSpacing.lg),

              // الجلسة القادمة
              Text('الجلسة القادمة', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(
                icon: Icons.event_available_outlined,
                title: 'حلقة ${widget.circle.name}',
                subtitle: 'غدًا • 4:30 م',
                accent: AppColors.primaryLight,
              ),
              const SizedBox(height: AppSpacing.lg),

              // إجراءات سريعة
              Text('إجراءات سريعة', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _QuickAction(
                      icon: Icons.mic_none_rounded,
                      label: 'تلاوة',
                      onTap: () =>
                          _open(TodayTaskPage(circleId: id, user: widget.user))),
                  _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: 'حفظ جديد',
                      onTap: () =>
                          _open(TodayTaskPage(circleId: id, user: widget.user))),
                  _QuickAction(
                      icon: Icons.replay_rounded,
                      label: 'مراجعة',
                      onTap: () => _open(WeeklySchedulePage(circleId: id))),
                  _QuickAction(
                      icon: Icons.insert_chart_outlined,
                      label: 'تقارير',
                      onTap: () => _open(const MyProgressPage())),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppUser user;
  final VoidCallback onProfile;
  const _Header({required this.user, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Notification bell with badge.
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('السلام عليكم 👋', style: theme.textTheme.bodySmall),
            Text(user.name, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onProfile,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.sky,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
        ),
      ],
    );
  }
}

class _TodayTaskCard extends StatelessWidget {
  final String range;
  final VoidCallback onTap;
  const _TodayTaskCard({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRange = range.isNotEmpty;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('واجب اليوم', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(hasRange ? range : 'لا يوجد تكليف لهذا اليوم',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProgressInfo? progress;
  final VoidCallback onTap;
  const _ProgressCard({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progress;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ProgressRing(
                value: p?.ratio ?? 0,
                size: 92,
                stroke: 10,
                center: Text('${p?.percent ?? 0}%',
                    style: theme.textTheme.titleLarge),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تقدّمي العام', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('أنتِ على الطريق الصحيح',
                        style: theme.textTheme.bodySmall),
                    if (p != null) ...[
                      const SizedBox(height: 4),
                      Text('${p.pagesDone} من ${p.totalPages} صفحة',
                          style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
