import 'package:flutter/material.dart';

import '../../../domain/auth/models/app_user.dart';
import '../../notification/pages/notifications_page.dart';
import 'profile_theme.dart';

/// Chrome for the full-screen teacher pages (settings / help / notifications):
/// a top bar with a back button, the user chip + bell, and a breadcrumb, over a
/// cream canvas. Rendered as a simple Column so the content always has bounded
/// width/height (no rail-beside-content row, which broke layout on web).
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
    final screen = MediaQuery.of(context).size;
    return LayoutBuilder(builder: (context, c) {
      // Force a finite width/height even if an unbounded constraint comes in
      // (the cause of the blank/“infinite width” crash on web). Fall back to
      // the screen size whenever the incoming constraint is infinite.
      final width = c.maxWidth.isFinite ? c.maxWidth : screen.width;
      final height = c.maxHeight.isFinite ? c.maxHeight : screen.height;
      return SizedBox(
        width: width,
        height: height,
        child: Scaffold(
          backgroundColor: ProfileTheme.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(user: user, breadcrumb: breadcrumb),
                Expanded(
                    child: Container(color: ProfileTheme.bg, child: child)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.user, required this.breadcrumb});

  final AppUser user;
  final String breadcrumb;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ProfileTheme.border)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: ProfileTheme.ink),
              tooltip: 'رجوع',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 18,
              backgroundColor: ProfileTheme.greenSoft,
              backgroundImage: (user.photoUrl != null &&
                      user.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: ProfileTheme.green)
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: ProfileTheme.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(user.role?.arabicLabel ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ProfileTheme.hint.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: ProfileTheme.muted),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),
            const Spacer(),
            Flexible(
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
    );
  }
}
