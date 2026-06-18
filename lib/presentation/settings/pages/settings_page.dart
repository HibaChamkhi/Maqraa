import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../profile/pages/profile_page.dart';
import '../../reminder/pages/reminder_settings_page.dart';

/// Global settings hub (الإعدادات).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _AccountCard(user: user),
          const SizedBox(height: AppSpacing.md),
          _Group(
            title: 'الحساب',
            children: [
              _Row(
                icon: Icons.person_outline,
                label: 'الملف الشخصي',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage())),
              ),
              _Row(
                icon: Icons.notifications_active_outlined,
                label: 'التذكير اليومي',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReminderSettingsPage())),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Group(
            title: 'عن التطبيق',
            children: [
              _Row(
                icon: Icons.info_outline,
                label: 'وِصَال',
                trailing: Text('الإصدار 1.0.0',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: const Icon(Icons.logout, color: AppColors.error),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AppUser? user;
  const _AccountCard({required this.user});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user?.name ?? '—';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.sky,
            child: Text(initial,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                if (email.isNotEmpty)
                  Text(email,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.textMuted)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Row(
      {required this.icon, required this.label, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_left, color: AppColors.textMuted)
              : null),
    );
  }
}
