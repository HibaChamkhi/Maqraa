import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../achievement/bloc/achievement_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../progress/bloc/progress_bloc.dart';
import 'profile_theme.dart';
import 'settings_page.dart';
import 'teacher_profile_page.dart';
import 'web_shell.dart';

/// US-36 (view/edit profile) + US-37 (secure password change).
/// Routes to the student or teacher profile, both using the same card layout.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    if (user == null) return const SizedBox.shrink();

    final isTeacher =
        user.role == UserRole.teacher || user.role == UserRole.supervisor;
    if (isTeacher) {
      return TeacherProfilePage(user: user);
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ProgressBloc>()..add(const LoadMyProgress()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<AchievementBloc>()..add(const AchievementRequested()),
        ),
      ],
      child: _StudentProfileView(user: user),
    );
  }
}

class _StudentProfileView extends StatefulWidget {
  const _StudentProfileView({required this.user});

  final AppUser user;

  @override
  State<_StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<_StudentProfileView> {
  late final Future<List<Circle>> _circles;

  @override
  void initState() {
    super.initState();
    _circles = getIt<CircleRepository>().getMyCircles();
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final content = FutureBuilder<List<Circle>>(
      future: _circles,
      builder: (context, snap) {
        final circle = (snap.data ?? const []).isNotEmpty
            ? snap.data!.first
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            LayoutBuilder(builder: (context, c) {
              final identity = _IdentityCard(user: user);
              final account = _AccountCard(user: user);
              final circleCard = _CircleCard(circle: circle);
              if (c.maxWidth >= 820) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: circleCard),
                      const SizedBox(width: 16),
                      Expanded(child: account),
                      const SizedBox(width: 16),
                      Expanded(child: identity),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  identity,
                  const SizedBox(height: 16),
                  account,
                  const SizedBox(height: 16),
                  circleCard,
                ],
              );
            }),
            const SizedBox(height: 16),
            const _StudentStats(),
          ],
        );
      },
    );

    return LayoutBuilder(builder: (context, c) {
      // Web: keep the permanent rail so navigating here doesn't make the
      // sidebar vanish (which made page changes feel jumpy).
      if (c.maxWidth >= 900 || ShellScope.of(context)) {
        return WebShell(
          user: user,
          current: 'الملف الشخصي',
          breadcrumb: 'الملف الشخصي',
          child: content,
        );
      }
      return Scaffold(
        backgroundColor: ProfileTheme.bg,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                onBack: () => Navigator.of(context).maybePop(),
                onSettings: () => _push(SettingsPage(user: user)),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: ProfileTheme.ink),
            onPressed: onSettings,
          ),
          Expanded(
            child: Text('الملف الشخصي',
                textAlign: TextAlign.center, style: ProfileTheme.appBarTitle),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: ProfileTheme.ink),
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'الملف الشخصي',
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: ProfileTheme.greenSoft,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 44, color: ProfileTheme.green)
                : null,
          ),
          const SizedBox(height: 14),
          Text(user.name, style: ProfileTheme.name.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: ProfileTheme.greenSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              user.role?.arabicLabel ?? 'طالب',
              style: const TextStyle(
                  color: ProfileTheme.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'معلومات الحساب',
      child: Column(
        children: [
          InfoRow(label: 'البريد الإلكتروني', value: user.email),
          InfoRow(label: 'رقم الجوال', value: user.phone ?? '—'),
          const InfoRow(label: 'اللغة', value: 'العربية'),
          const InfoRow(label: 'تاريخ الانضمام', value: '—'),
          const InfoRow(label: 'آخر تسجيل دخول', value: '—'),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle});
  final Circle? circle;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      title: 'معلومات الحلقة',
      child: Column(
        children: [
          InfoRow(label: 'اسم الحلقة', value: circle?.name ?? 'لم تنضم لحلقة'),
          const InfoRow(label: 'المدينة', value: 'الرياض'),
          const InfoRow(label: 'المستوى', value: 'متوسط'),
        ],
      ),
    );
  }
}

/// Student KPI row: progress · streak · badges · pages — real data.
class _StudentStats extends StatelessWidget {
  const _StudentStats();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressBloc>().state.progress;
    final ach = context.watch<AchievementBloc>().state.achievement;
    final cards = <Widget>[
      StatCircle(
          icon: Icons.eco_outlined,
          value: '${progress?.percent ?? 0}%',
          label: 'من الإنجاز',
          title: 'إجمالي التقدم'),
      StatCircle(
          icon: Icons.local_fire_department_outlined,
          value: '${ach.streakCount}',
          label: 'يوم متتالي',
          title: 'سلسلة الالتزام'),
      StatCircle(
          icon: Icons.emoji_events_outlined,
          value: '${ach.badges.length}',
          label: 'وسام',
          title: 'الأوسمة'),
      StatCircle(
          icon: Icons.menu_book_outlined,
          value: '${progress?.pagesDone ?? 0}',
          label: 'صفحة',
          title: 'المحفوظ'),
    ];
    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth >= 560 ? 4 : 2;
      final width = (c.maxWidth - (perRow - 1) * 16) / perRow;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final card in cards) SizedBox(width: width, child: card),
        ],
      );
    });
  }
}
