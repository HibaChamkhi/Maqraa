import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/auth/models/app_user.dart';
import '../../../presentation/auth/bloc/auth_bloc.dart';
import '../../../presentation/circle/pages/circles_list_page.dart';
import '../../../presentation/help/help_page.dart';
import '../../../presentation/notification/pages/notifications_page.dart';
import '../../../presentation/profile/pages/profile_page.dart';
import '../../../presentation/profile/pages/settings_page.dart';
import '../styles/theme.dart';

/// The green «ورْد» side navigation drawer (the sidebar in the reference).
/// Opened by the ≡ button; on RTL it slides in from the right.
class WardDrawer extends StatelessWidget {
  final AppUser user;

  /// Label of the currently-open section, to highlight it.
  final String current;

  /// When true, renders as a fixed full-height side rail (wide screens)
  /// instead of a pop-over drawer.
  final bool permanent;

  const WardDrawer({
    super.key,
    required this.user,
    this.current = 'الرئيسية',
    this.permanent = false,
  });

  bool get _isTeacher =>
      user.role == UserRole.teacher || user.role == UserRole.supervisor;

  @override
  Widget build(BuildContext context) {
    final panel = _panel(context);
    if (permanent) {
      return SizedBox(width: 272, child: panel);
    }
    return Drawer(
      width: 272,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(26)),
      ),
      child: panel,
    );
  }

  Widget _panel(BuildContext context) {
    final items = _isTeacher
        ? const [
            ('الرئيسية', Icons.home_outlined),
            ('الحلقات', Icons.groups_2_outlined),
            ('الطالبات', Icons.people_outline),
            ('الجدول', Icons.calendar_month_outlined),
            ('الاختبارات والتقارير', Icons.assignment_outlined),
            ('التقارير', Icons.bar_chart_outlined),
            ('الإشعارات', Icons.notifications_outlined),
            ('الإعدادات', Icons.settings_outlined),
            ('المساعدة', Icons.help_outline),
          ]
        : const [
            ('الرئيسية', Icons.home_outlined),
            ('حلقتي', Icons.groups_2_outlined),
            ('واجب اليوم', Icons.today_outlined),
            ('تقدّمي', Icons.timeline_outlined),
            ('الإشعارات', Icons.notifications_outlined),
            ('الإعدادات', Icons.settings_outlined),
            ('المساعدة', Icons.help_outline),
          ];

    final radius = permanent
        ? BorderRadius.zero
        : const BorderRadius.horizontal(left: Radius.circular(26));

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F6B5B), Color(0xFF09463A)],
        ),
        borderRadius: radius,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('وِصَال',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.spa_outlined, color: Colors.white, size: 26),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in items)
                    _DrawerItem(
                      label: item.$1,
                      icon: item.$2,
                      active: item.$1 == current,
                      onTap: () => _go(context, item.$1),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            _DrawerItem(
              label: 'الملف الشخصي',
              icon: Icons.person_outline,
              onTap: () {
                _closeIfDrawer(context);
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()));
              },
            ),
            _DrawerItem(
              label: 'تسجيل الخروج',
              icon: Icons.logout,
              onTap: () {
                _closeIfDrawer(context);
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Close the pop-over drawer if one is open (no-op for the permanent rail).
  void _closeIfDrawer(BuildContext context) {
    final s = Scaffold.maybeOf(context);
    if (s != null && s.isDrawerOpen) s.closeDrawer();
  }

  void _go(BuildContext context, String label) {
    _closeIfDrawer(context);
    switch (label) {
      case 'الرئيسية':
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 'الحلقات':
      case 'الطالبات':
      case 'حلقتي':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CirclesListPage()));
        break;
      case 'الإعدادات':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => SettingsPage(user: user)));
        break;
      case 'الإشعارات':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()));
        break;
      case 'المساعدة':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const HelpPage()));
        break;
      default:
        // الجدول / الاختبارات / الإشعارات / واجب اليوم / تقدّمي — reachable from
        // the home grid for now; deeper wiring comes with each section.
        Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon,
                    color: active ? AppColors.primaryDark : Colors.white,
                    size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? AppColors.primaryDark : Colors.white,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
