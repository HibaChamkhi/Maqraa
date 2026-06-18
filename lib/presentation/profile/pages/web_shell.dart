import 'package:flutter/material.dart';

import '../../../core/ui/widgets/ward_drawer.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../notification/pages/notifications_page.dart';
import 'profile_theme.dart';

/// Shared chrome for the web teacher pages: green side rail (permanent on wide
/// screens, pop-over drawer on narrow), a cream canvas, and a top bar with the
/// breadcrumb on the left and the notification bell + user chip on the right.
class WebShell extends StatelessWidget {
  const WebShell({
    super.key,
    required this.user,
    required this.breadcrumb,
    required this.child,
    this.current = 'الإعدادات',
  });

  final AppUser user;
  final String breadcrumb;
  final String current;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final body = Container(
        color: ProfileTheme.bg,
        child: Column(
          children: [
            _TopBar(user: user, breadcrumb: breadcrumb, showMenu: !wide),
            Expanded(child: child),
          ],
        ),
      );
      if (wide) {
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WardDrawer(user: user, permanent: true, current: current),
              Expanded(child: body),
            ],
          ),
        );
      }
      return Scaffold(
        backgroundColor: ProfileTheme.bg,
        drawer: WardDrawer(user: user, current: current),
        body: body,
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.user, required this.breadcrumb, required this.showMenu});

  final AppUser user;
  final String breadcrumb;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ProfileTheme.border)),
          ),
          child: Row(
            children: [
              // Menu button on the right (RTL leading) on narrow screens.
              if (showMenu)
                Builder(
                  builder: (context) => IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.menu, color: ProfileTheme.ink),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              if (showMenu) const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: ProfileTheme.greenSoft,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? const Icon(Icons.person,
                        size: 20, color: ProfileTheme.green)
                    : null,
              ),
              const SizedBox(width: 10),
              // Hide the name on narrow screens to avoid overflow.
              if (!showMenu)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            color: ProfileTheme.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(user.role?.arabicLabel ?? '',
                        style: ProfileTheme.hint.copyWith(fontSize: 11)),
                  ],
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: ProfileTheme.muted),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  breadcrumb,
                  style: ProfileTheme.hint,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
