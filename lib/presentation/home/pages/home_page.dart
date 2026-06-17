import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../announcement/pages/announcements_page.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../achievement/pages/achievement_page.dart';
import '../../calendar/pages/manage_calendar_page.dart';
import '../../calendar/pages/student_calendar_page.dart';
import '../../call/pages/weekly_call_page.dart';
import '../../circle/pages/circle_info_page.dart';
import '../../circle/pages/circle_members_page.dart';
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

/// Role-based home. Loads the user's circles, then shows a dashboard whose
/// tiles route to the relevant feature pages for that role.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Circle>> _circlesFuture;

  @override
  void initState() {
    super.initState();
    _circlesFuture = getIt<CircleRepository>().getMyCircles();
  }

  void _reload() => setState(() {
        _circlesFuture = getIt<CircleRepository>().getMyCircles();
      });

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('وصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: FutureBuilder<List<Circle>>(
        future: _circlesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final circles = snap.data ?? [];
          if (circles.isEmpty) {
            return _EmptyState(user: user, onChanged: _reload);
          }
          return _Dashboard(user: user, circle: circles.first);
        },
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
  final Widget Function() page;
  const _Tile(this.label, this.icon, this.page);
}

class _Dashboard extends StatelessWidget {
  final AppUser user;
  final Circle circle;

  const _Dashboard({required this.user, required this.circle});

  bool get _canManage =>
      user.role == UserRole.teacher || user.role == UserRole.supervisor;

  Future<void> _openPairing(BuildContext context) async {
    final members = await getIt<CircleRepository>().getMembers(circle.id);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PairingPage(circleId: circle.id, user: user, members: members),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = circle.id;

    final tiles = _canManage
        ? <_Tile>[
            _Tile('معلومات الحلقة', Icons.info_outline,
                () => CircleInfoPage(circleId: id, user: user)),
            _Tile('الطالبات', Icons.group_outlined,
                () => CircleMembersPage(circleId: id, user: user)),
            _Tile('طلبات الانضمام', Icons.how_to_reg_outlined,
                () => JoinRequestsPage(circleId: id)),
            _Tile('نشر الجدول', Icons.edit_calendar_outlined,
                () => PublishSchedulePage(circleId: id)),
            _Tile('متابعة التسليم', Icons.fact_check_outlined,
                () => TeacherTrackingPage(circleId: id)),
            _Tile('الاختبارات', Icons.assignment_outlined,
                () => TeacherExamsPage(circleId: id, user: user)),
            _Tile('التقويم', Icons.calendar_month_outlined,
                () => ManageCalendarPage(circleId: id, user: user)),
            _Tile('الجلسة المباشرة', Icons.podcasts_outlined,
                () => LiveSessionPage(circleId: id, user: user)),
            _Tile('المكالمة الأسبوعية', Icons.video_call_outlined,
                () => WeeklyCallPage(circleId: id, user: user)),
            _Tile('الإعلانات', Icons.campaign_outlined,
                () => AnnouncementsPage(circleId: id, user: user)),
          ]
        : <_Tile>[
            _Tile('واجب اليوم', Icons.today_outlined,
                () => TodayTaskPage(circleId: id, user: user)),
            _Tile('جدول الأسبوع', Icons.calendar_view_week_outlined,
                () => WeeklySchedulePage(circleId: id)),
            _Tile('تقدّمي', Icons.timeline_outlined, () => const MyProgressPage()),
            _Tile('تأكيد التسميع', Icons.verified_outlined,
                () => PendingConfirmationsPage(circleId: id, user: user)),
            _Tile('مهامي', Icons.checklist_outlined,
                () => AssignmentsPage(
                    circleId: id, studentId: user.uid, studentName: user.name, user: user)),
            _Tile('رفيقتي', Icons.handshake_outlined,
                () => MyPartnerPage(circleId: id, user: user)),
            _Tile('تقويمي', Icons.calendar_month_outlined,
                () => StudentCalendarPage(circleId: id, user: user)),
            _Tile('الجلسة', Icons.podcasts_outlined,
                () => StudentSessionPage(circleId: id, user: user)),
            _Tile('اختباراتي', Icons.assignment_turned_in_outlined,
                () => StudentExamsPage(circleId: id, user: user)),
            _Tile('الإعلانات', Icons.campaign_outlined,
                () => AnnouncementsPage(circleId: id, user: user)),
            _Tile('إنجازاتي', Icons.emoji_events_outlined, () => const AchievementPage()),
            _Tile('التذكيرات', Icons.notifications_active_outlined,
                () => const ReminderSettingsPage()),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مرحبًا ${user.name} 🌿', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('حلقة: ${circle.name}  •  ${user.role?.arabicLabel ?? ''}',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final t in tiles)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => t.page()),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.icon, size: 38, color: theme.colorScheme.primary),
                        const SizedBox(height: 10),
                        Text(t.label, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              if (_canManage)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _openPairing(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handshake_outlined,
                            size: 38, color: theme.colorScheme.primary),
                        const SizedBox(height: 10),
                        const Text('إقران الرفيقات', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
