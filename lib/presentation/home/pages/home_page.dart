import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/util/last_location_store.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../../core/ui/widgets/ward_drawer.dart';
import '../../announcement/pages/announcements_page.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../achievement/pages/achievement_page.dart';
import '../../calendar/pages/manage_calendar_page.dart';
import '../../calendar/pages/student_calendar_page.dart';
import '../../call/pages/weekly_call_page.dart';
import '../../circle/pages/circle_info_page.dart';
import '../../circle/pages/circles_list_page.dart';
import '../../circle/pages/circle_workspace_page.dart';
import '../../circle/pages/create_circle_page.dart';
import '../../circle/pages/join_circle_page.dart';
import '../../circle/pages/join_requests_page.dart';
import '../../circle/pages/qr_join_page.dart';
import '../../exam/pages/student_exams_page.dart';
import '../../exam/pages/teacher_exams_page.dart';
import '../../partner/pages/my_partner_page.dart';
import '../../partner/pages/pairing_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../progress/pages/my_progress_page.dart';
import '../../progress/pages/teacher_tracking_page.dart';
import '../../reminder/pages/reminder_settings_page.dart';
import '../../schedule/pages/publish_schedule_page.dart';
import '../../schedule/pages/weekly_schedule_page.dart';
import '../../session/pages/live_session_page.dart';
import '../../session/pages/student_session_page.dart';
import '../../task/pages/assignments_page.dart';
import '../../task/pages/pending_confirmations_page.dart';
import '../../task/pages/today_task_page.dart';
import 'student_home_page.dart';
import 'teacher_overview_page.dart';

/// Role-based home. Loads the user's circles, then shows a dashboard whose
/// tiles route to the relevant feature pages for that role.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Circle>> _circlesFuture;

  /// Whether the permanent side rail is shown (wide screens). The ≡ button
  /// toggles it.
  bool _railOpen = true;

  /// Nested navigator for the content area on wide screens, so the rail + top
  /// bar persist while the section content swaps.
  final GlobalKey<NavigatorState> _contentNav = GlobalKey<NavigatorState>();

  /// Currently-selected sidebar section (drives the active highlight).
  String _section = 'الرئيسية';

  /// Restores the last-open circle/tab once after a (web) refresh.
  bool _restored = false;

  void _maybeRestore(
      BuildContext context, List<Circle> circles, AppUser user) {
    if (_restored) return;
    _restored = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved = await LastLocationStore.load();
      if (saved.circleId == null || !mounted) return;
      Circle? circle;
      for (final c in circles) {
        if (c.id == saved.circleId) {
          circle = c;
          break;
        }
      }
      if (circle == null || !mounted) return;
      final wide = MediaQuery.of(context).size.width >= 900;
      final nav = wide
          ? _contentNav.currentState
          : Navigator.of(context, rootNavigator: true);
      nav?.push(MaterialPageRoute(
        builder: (_) => CircleWorkspacePage(
            circle: circle!, user: user, initialTab: saved.tab),
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    _circlesFuture = getIt<CircleRepository>().getMyCircles();
  }

  void _reload() => setState(() {
        _circlesFuture = getIt<CircleRepository>().getMyCircles();
      });

  /// Responsive shell: on wide screens the green sidebar is a permanent
  /// right-side rail (like the reference); on narrow screens it's a pop-over
  /// drawer opened from the ≡ button.
  Widget _shell({required AppUser user, required Widget content}) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 900) {
        return Scaffold(
          body: Column(children: [
            _TopBar(onMenu: () => setState(() => _railOpen = !_railOpen)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _railOpen
                        ? WardDrawer(
                            user: user,
                            permanent: true,
                            contentNavigator: _contentNav,
                            current: _section,
                            onSelect: (l) => setState(() => _section = l),
                          )
                        : const SizedBox(height: double.infinity),
                  ),
                  Expanded(
                    child: Navigator(
                      key: _contentNav,
                      onGenerateRoute: (_) =>
                          MaterialPageRoute(builder: (_) => content),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        );
      }
      return Scaffold(
        drawer: WardDrawer(
          user: user,
          current: _section,
          onSelect: (l) => setState(() => _section = l),
        ),
        body: Column(children: [
          const _TopBar(),
          Expanded(child: content),
        ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<Circle>>(
      future: _circlesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final circles = snap.data ?? [];
        if (circles.isEmpty) {
          return _shell(
            user: user,
            content: _EmptyState(user: user, onChanged: _reload),
          );
        }
        final circle = circles.first;

        // Students get the «وِرد» daily home with bottom navigation; the full
        // feature grid lives behind the "المزيد" tab.
        if (user.role == UserRole.student) {
          return StudentHomePage(
            user: user,
            circle: circle,
            more: Scaffold(
              body: Column(children: [
                const _TopBar(menu: false),
                Expanded(child: _Dashboard(user: user, circle: circle)),
              ]),
            ),
          );
        }

        // Teachers / supervisors get the overview dashboard (الرئيسية).
        _maybeRestore(context, circles, user);
        return _shell(
          user: user,
          content: TeacherOverviewPage(user: user, circles: circles),
        );
      },
    );
  }

}

/// Top bar rendered INSIDE the Scaffold body (not as `appBar:`) so the side
/// menu's scrim covers it too when the drawer is open. The ≡ button opens the
/// drawer via [Scaffold.of] (this widget sits below the Scaffold).
class _TopBar extends StatelessWidget {
  /// Whether to show the ≡ menu button (false on screens without a drawer).
  final bool menu;

  /// If provided, the ≡ button calls this (used to toggle the permanent rail)
  /// instead of opening the pop-over drawer.
  final VoidCallback? onMenu;
  const _TopBar({this.menu = true, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (onMenu != null)
                IconButton(icon: const Icon(Icons.menu), onPressed: onMenu)
              else if (menu)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
              else
                const SizedBox(width: 8),
              Text('وِصَال', style: theme.textTheme.titleLarge),
              const SizedBox(width: 6),
              const Icon(Icons.spa_outlined, color: AppColors.primary),
              const Spacer(),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined)),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline)),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'profile') {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()));
                  } else if (v == 'logout') {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'profile', child: Text('الملف الشخصي')),
                  PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.sky,
                        child: Icon(Icons.person,
                            size: 18, color: AppColors.primary),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the user isn't in any circle yet.
class _EmptyState extends StatelessWidget {
  final AppUser user;
  final VoidCallback onChanged;

  const _EmptyState({required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isTeacher = user.role == UserRole.teacher;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_outlined,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              isTeacher ? 'لا توجد حلقة بعد' : 'لم تنضمّي إلى حلقة بعد',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            if (isTeacher)
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateCirclePage()),
                  );
                  onChanged();
                },
                icon: const Icon(Icons.add),
                label: const Text('إنشاء حلقة'),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => JoinCirclePage(user: user)),
                  );
                  onChanged();
                },
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('الانضمام برمز دعوة'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => QrJoinPage(user: user)),
                  );
                  onChanged();
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('الانضمام بمسح QR'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tile {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Tile(this.label, this.icon, this.onTap);
}

class _Section {
  final String title;
  final List<_Tile> tiles;
  const _Section(this.title, this.tiles);
}

class _Dashboard extends StatelessWidget {
  final AppUser user;
  final Circle circle;

  const _Dashboard({required this.user, required this.circle});

  bool get _canManage =>
      user.role == UserRole.teacher || user.role == UserRole.supervisor;

  void _push(BuildContext context, Widget page) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => page));

  Future<void> _openPairing(BuildContext context) async {
    final members = await getIt<CircleRepository>().getMembers(circle.id);
    if (!context.mounted) return;
    _push(context,
        PairingPage(circleId: circle.id, user: user, members: members));
  }

  @override
  Widget build(BuildContext context) =>
      _canManage ? _teacherView(context) : _studentView(context);

  // -------------------- TEACHER / SUPERVISOR --------------------

  Widget _teacherView(BuildContext context) {
    final id = circle.id;
    final sections = <_Section>[
      _Section('إدارة الحلقة', [
        _Tile('كل الحلقات', Icons.groups_2_outlined,
            () => _push(context, const CirclesListPage())),
        _Tile('الطالبات', Icons.group_outlined,
            () => _push(context, CircleWorkspacePage(circle: circle, user: user))),
        _Tile('معلومات الحلقة', Icons.info_outline,
            () => _push(context, CircleInfoPage(circleId: id, user: user))),
        _Tile('طلبات الانضمام', Icons.how_to_reg_outlined,
            () => _push(context, JoinRequestsPage(circleId: id))),
        _Tile('إقران الرفيقات', Icons.handshake_outlined,
            () => _openPairing(context)),
      ]),
      _Section('المتابعة اليومية', [
        _Tile('متابعة التسليم', Icons.fact_check_outlined,
            () => _push(context, TeacherTrackingPage(circleId: id))),
        _Tile('نشر الجدول', Icons.edit_calendar_outlined,
            () => _push(context, PublishSchedulePage(circleId: id))),
        _Tile('التقويم', Icons.calendar_month_outlined,
            () => _push(context, ManageCalendarPage(circleId: id, user: user))),
        _Tile('الجلسة المباشرة', Icons.podcasts_outlined,
            () => _push(context, LiveSessionPage(circleId: id, user: user))),
      ]),
      _Section('التقييم والتواصل', [
        _Tile('الاختبارات', Icons.assignment_outlined,
            () => _push(context, TeacherExamsPage(circleId: id, user: user))),
        _Tile('المكالمة الأسبوعية', Icons.video_call_outlined,
            () => _push(context, WeeklyCallPage(circleId: id, user: user))),
        _Tile('الإعلانات', Icons.campaign_outlined,
            () => _push(context, AnnouncementsPage(circleId: id, user: user))),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _WelcomeBanner(user: user, circle: circle),
        const SizedBox(height: AppSpacing.md),
        _StatsRow(circle: circle, user: user),
        for (final s in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, AppSpacing.lg, 4, AppSpacing.sm),
            child: SectionHeader(title: s.title),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < s.tiles.length; i++)
                  _MenuRow(tile: s.tiles[i], showDivider: i != s.tiles.length - 1),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // -------------------- STUDENT (the "more" grid) --------------------

  Widget _studentView(BuildContext context) {
    final theme = Theme.of(context);
    final id = circle.id;
    final tiles = <_Tile>[
      _Tile('واجب اليوم', Icons.today_outlined,
          () => _push(context, TodayTaskPage(circleId: id, user: user))),
      _Tile('جدول الأسبوع', Icons.calendar_view_week_outlined,
          () => _push(context, WeeklySchedulePage(circleId: id))),
      _Tile('تقدّمي', Icons.timeline_outlined,
          () => _push(context, const MyProgressPage())),
      _Tile('تأكيد التسميع', Icons.verified_outlined,
          () => _push(context, PendingConfirmationsPage(circleId: id, user: user))),
      _Tile('مهامي', Icons.checklist_outlined,
          () => _push(context, AssignmentsPage(circleId: id, studentId: user.uid, studentName: user.name, user: user))),
      _Tile('رفيقتي', Icons.handshake_outlined,
          () => _push(context, MyPartnerPage(circleId: id, user: user))),
      _Tile('تقويمي', Icons.calendar_month_outlined,
          () => _push(context, StudentCalendarPage(circleId: id, user: user))),
      _Tile('الجلسة', Icons.podcasts_outlined,
          () => _push(context, StudentSessionPage(circleId: id, user: user))),
      _Tile('اختباراتي', Icons.assignment_turned_in_outlined,
          () => _push(context, StudentExamsPage(circleId: id, user: user))),
      _Tile('الإعلانات', Icons.campaign_outlined,
          () => _push(context, AnnouncementsPage(circleId: id, user: user))),
      _Tile('إنجازاتي', Icons.emoji_events_outlined,
          () => _push(context, const AchievementPage())),
      _Tile('التذكيرات', Icons.notifications_active_outlined,
          () => _push(context, const ReminderSettingsPage())),
    ];
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        for (final t in tiles)
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: t.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(t.icon, size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(t.label, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One row inside a menu group (icon chip + label + chevron).
class _MenuRow extends StatelessWidget {
  final _Tile tile;
  final bool showDivider;
  const _MenuRow({required this.tile, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: tile.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(tile.icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(tile.label, style: theme.textTheme.titleMedium),
                ),
                const Icon(Icons.chevron_left, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 56, endIndent: 14),
      ],
    );
  }
}

/// Green welcome banner at the top of the teacher dashboard.
class _WelcomeBanner extends StatelessWidget {
  final AppUser user;
  final Circle circle;
  const _WelcomeBanner({required this.user, required this.circle});

  @override
  Widget build(BuildContext context) {
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
                Text('مرحبًا ${user.name}',
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('تابعي طالبات «${circle.name}» وحفّزيهن على الإنجاز',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.spa_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

/// Stat cards row (live member count + circle + role).
class _StatsRow extends StatelessWidget {
  final Circle circle;
  final AppUser user;
  const _StatsRow({required this.circle, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CircleMember>>(
      future: getIt<CircleRepository>().getMembers(circle.id),
      builder: (context, snap) {
        final members = snap.data ?? const [];
        final students =
            members.where((m) => m.status == MemberStatus.active).length;
        final pending =
            members.where((m) => m.status == MemberStatus.pending).length;
        return Row(
          children: [
            Expanded(
              child: StatCard(
                value: snap.connectionState == ConnectionState.waiting ? '—' : '$students',
                label: 'الطالبات',
                icon: Icons.group_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                value: snap.connectionState == ConnectionState.waiting ? '—' : '$pending',
                label: 'طلبات الانضمام',
                icon: Icons.how_to_reg_outlined,
                accent: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                value: circle.privacy == Privacy.public ? 'عامة' : 'خاصة',
                label: 'خصوصية الحلقة',
                icon: Icons.lock_outline,
                accent: AppColors.primaryLight,
              ),
            ),
          ],
        );
      },
    );
  }
}
