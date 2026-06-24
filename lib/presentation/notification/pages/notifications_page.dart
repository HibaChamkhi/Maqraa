import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/notification/models/app_notification.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../profile/pages/profile_theme.dart';
import '../../profile/pages/web_shell.dart';
import '../bloc/notification_bloc.dart';
import 'notification_detail_page.dart';
import 'notification_settings_page.dart';
import 'notification_ui.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    if (user == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => getIt<NotificationBloc>()..add(const NotificationsRequested()),
      child: _NotificationsView(user: user),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView({required this.user});
  final AppUser user;

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  int _tab = 0;
  String _query = '';

  bool get _isTeacher =>
      widget.user.role == UserRole.teacher ||
      widget.user.role == UserRole.supervisor;

  List<(String, NotificationCategory?)> get _tabs => _isTeacher
      ? const [
          ('الكل', null),
          ('النظام', NotificationCategory.system),
          ('الحلقات', NotificationCategory.circles),
          ('التنبيهات', NotificationCategory.alerts),
        ]
      : const [
          ('الكل', null),
          ('الواجبات', NotificationCategory.homework),
          ('النظام', NotificationCategory.system),
          ('التنبيهات', NotificationCategory.alerts),
        ];

  List<AppNotification> _filter(List<AppNotification> all) {
    final cat = _tabs[_tab].$2;
    var items = cat == null
        ? all
        : all.where((n) => n.type.category == cat).toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim();
      items = items
          .where((n) => n.title.contains(q) || n.body.contains(q))
          .toList();
    }
    return items;
  }

  void _openSettings() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
      );

  void _markAll(BuildContext context) =>
      context.read<NotificationBloc>().add(const NotificationsAllReadMarked());

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900 || ShellScope.of(context);
      return wide ? _web(context) : _mobile(context);
    });
  }

  // ----------------------------- mobile -----------------------------

  Widget _mobile(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: ProfileTheme.ink),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text('الإشعارات',
                        textAlign: TextAlign.center,
                        style: ProfileTheme.appBarTitle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: ProfileTheme.ink),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),
            _Tabs(
              tabs: _tabs.map((e) => e.$1).toList(),
              current: _tab,
              onSelect: (i) => setState(() => _tab = i),
            ),
            Expanded(child: _list(context)),
            SafeArea(
              top: false,
              child: TextButton(
                onPressed: () => _markAll(context),
                child: const Text('تحديد الكل كمقروء',
                    style: TextStyle(
                        color: ProfileTheme.green,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------- web -----------------------------

  Widget _web(BuildContext context) {
    return WebShell(
      user: widget.user,
      current: 'الإشعارات',
      breadcrumb: 'الإشعارات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Text('الإشعارات', style: ProfileTheme.sectionTitle),
                const Spacer(),
                SizedBox(
                  width: 260,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: ProfileTheme.field('ابحث في الإشعارات...',
                        prefix: const Icon(Icons.search,
                            size: 20, color: ProfileTheme.muted)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileTheme.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _markAll(context),
                  child: const Text('تحديد الكل كمقروء'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: ProfileTheme.muted),
                  onPressed: _openSettings,
                ),
              ],
            ),
          ),
          _Tabs(
            tabs: _tabs.map((e) => e.$1).toList(),
            current: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 8),
          Expanded(child: _list(context)),
        ],
      ),
    );
  }

  // ----------------------------- shared list -----------------------------

  Widget _list(BuildContext context, {bool shrinkWrap = false}) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state.status == UIStatus.loading && state.notifications.isEmpty) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == UIStatus.error && state.notifications.isEmpty) {
          return SizedBox(
            height: 280,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            ),
          );
        }
        final items = _filter(state.notifications);
        if (items.isEmpty) {
          return const SizedBox(
            height: 280,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('لا توجد إشعارات',
                    style: TextStyle(color: ProfileTheme.muted)),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics:
              shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final n = items[i];
            return _NotificationTile(
              notification: n,
              onTap: () {
                context
                    .read<NotificationBloc>()
                    .add(NotificationReadMarked(n.id));
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => NotificationDetailPage(notification: n)));
              },
            );
          },
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs(
      {required this.tabs, required this.current, required this.onSelect});
  final List<String> tabs;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: i == current ? ProfileTheme.green : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: i == current
                          ? ProfileTheme.green
                          : ProfileTheme.border),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: i == current ? Colors.white : ProfileTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = NotifVisual.of(notification.type);
    final unread = !notification.read;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProfileTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: v.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(v.icon, color: v.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: ProfileTheme.ink,
                        fontWeight:
                            unread ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: ProfileTheme.muted, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(arabicTimeAgo(notification.createdAt),
                  style: const TextStyle(
                      color: ProfileTheme.muted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
