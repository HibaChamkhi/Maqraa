import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/progress/models/progress_info.dart';
import '../../../domain/progress/repositories/progress_repository.dart';
import '../../../domain/schedule/repositories/schedule_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../announcement/pages/announcements_page.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../exam/pages/student_exams_page.dart';
import '../../notification/pages/notifications_page.dart';
import '../../partner/pages/my_partner_page.dart';
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

/// Student sections shown in the web side-rail.
class _Section {
  final String label;
  final IconData icon;
  const _Section(this.label, this.icon);
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _tab = 0; // mobile bottom-nav index
  String _section = 'الرئيسية'; // web rail selection
  final GlobalKey<NavigatorState> _contentNav = GlobalKey<NavigatorState>();

  static const _railSections = [
    _Section('الرئيسية', Icons.home_outlined),
    _Section('واجبي', Icons.menu_book_outlined),
    _Section('الجدول', Icons.calendar_view_week_outlined),
    _Section('تقدّمي', Icons.insert_chart_outlined),
    _Section('اختباراتي', Icons.assignment_turned_in_outlined),
    _Section('رفيقتي', Icons.handshake_outlined),
    _Section('الإعلانات', Icons.campaign_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return c.maxWidth >= 900 ? _webShell() : _mobile();
    });
  }

  // ---------------------------------------------------------------- mobile
  Widget _mobile() {
    final id = widget.circle.id;
    final pages = [
      _HomeTab(user: widget.user, circle: widget.circle, showHeader: true),
      TodayTaskPage(circleId: id, user: widget.user),
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
              label: 'واجبي'),
          NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined),
              selectedIcon: Icon(Icons.insert_chart_rounded),
              label: 'تقدّمي'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- web
  Widget _webShell() {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                _WebTopBar(user: widget.user, circle: widget.circle),
                Expanded(
                  child: Navigator(
                    key: _contentNav,
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => _HomeTab(
                          user: widget.user,
                          circle: widget.circle,
                          showHeader: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _StudentRail(
            sections: _railSections,
            current: _section,
            onSelect: _goSection,
            onProfile: () => _push(const ProfilePage()),
            onLogout: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }

  void _push(Widget page) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => page));

  void _goSection(String label) {
    setState(() => _section = label);
    final nav = _contentNav.currentState!;
    nav.popUntil((r) => r.isFirst);
    final id = widget.circle.id;
    void push(Widget page) =>
        nav.push(MaterialPageRoute(builder: (_) => page));
    switch (label) {
      case 'الرئيسية':
        break; // dashboard is the root route
      case 'واجبي':
        push(TodayTaskPage(circleId: id, user: widget.user));
        break;
      case 'الجدول':
        push(WeeklySchedulePage(circleId: id));
        break;
      case 'تقدّمي':
        push(const MyProgressPage());
        break;
      case 'اختباراتي':
        push(StudentExamsPage(circleId: id, user: widget.user));
        break;
      case 'رفيقتي':
        push(MyPartnerPage(circleId: id, user: widget.user));
        break;
      case 'الإعلانات':
        push(AnnouncementsPage(circleId: id, user: widget.user));
        break;
    }
  }
}

/// The green side rail for the student web layout (mirrors the teacher rail).
class _StudentRail extends StatelessWidget {
  final List<_Section> sections;
  final String current;
  final ValueChanged<String> onSelect;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  const _StudentRail({
    required this.sections,
    required this.current,
    required this.onSelect,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F6B5B), Color(0xFF09463A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('وِصَال',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.spa_outlined, color: Colors.white, size: 22),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final s in sections)
                    _RailItem(
                      label: s.label,
                      icon: s.icon,
                      active: s.label == current,
                      onTap: () => onSelect(s.label),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            _RailItem(
                label: 'الملف الشخصي',
                icon: Icons.person_outline,
                onTap: onProfile),
            _RailItem(label: 'تسجيل الخروج', icon: Icons.logout, onTap: onLogout),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _RailItem({
    required this.label,
    required this.icon,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon,
                    size: 19,
                    color: active ? AppColors.primary : Colors.white),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.primary : Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar for the student web layout: avatar + greeting on the right,
/// bell + circle/teacher line on the left.
class _WebTopBar extends StatelessWidget {
  final AppUser user;
  final Circle circle;
  const _WebTopBar({required this.user, required this.circle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration:
            const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.sky,
              backgroundImage:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? const Icon(Icons.person, size: 18, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('السلام عليكم',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              ],
            ),
            const Spacer(),
            Text('حلقة ${circle.name}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.textMuted),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage())),
            ),
          ],
        ),
      ),
    );
  }
}

/// Holds the fetched-once data for the home tab.
typedef _HomeData = ({
  ProgressInfo progress,
  String todayRange,
  Session? nextSession,
});

class _HomeTab extends StatefulWidget {
  final AppUser user;
  final Circle circle;

  /// On mobile we show the in-page header (bell + avatar). On web the shell's
  /// top bar already shows them, so it's hidden.
  final bool showHeader;
  const _HomeTab(
      {required this.user, required this.circle, this.showHeader = true});

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

    // Next upcoming session — read live so teacher edits show immediately.
    Session? next;
    try {
      final sessions =
          await getIt<SessionRepository>().getSessions(widget.circle.id);
      final now = DateTime.now();
      final upcoming = sessions
          .where((s) =>
              s.scheduledAt.isAfter(now) && s.status != SessionStatus.ended)
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      next = upcoming.isEmpty ? null : upcoming.first;
    } catch (_) {/* sessions optional */}

    return (progress: progress, todayRange: range, nextSession: next);
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
          final nextSession = snap.data?.nextSession;
          final loadingSession = !snap.hasData;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (widget.showHeader) ...[
                _Header(
                    user: widget.user,
                    onProfile: () => _open(const ProfilePage())),
                const SizedBox(height: AppSpacing.lg),
              ],

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
                title: nextSession != null && nextSession.title.trim().isNotEmpty
                    ? nextSession.title.trim()
                    : 'حلقة ${widget.circle.name}',
                subtitle: loadingSession
                    ? '...'
                    : nextSession == null
                        ? 'لا توجد جلسة قادمة'
                        : '${DateFormat('EEEE d MMM', 'ar').format(nextSession.scheduledAt)} • ${DateFormat('h:mm a', 'ar').format(nextSession.scheduledAt)}',
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
              ),
            ),
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
    final hasRange = range.isNotEmpty;
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  Text('واجب اليوم',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text(hasRange ? range : 'لا يوجد تكليف لهذا اليوم',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: AppColors.primary, size: 15),
                      SizedBox(width: 6),
                      Text('فتح الواجب',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
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
