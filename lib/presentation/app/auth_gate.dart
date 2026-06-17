import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/model /ui_state.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/pages/login_page.dart';
import '../home/pages/home_page.dart';

/// Decides which screen to show based on the current auth state:
///   no user   -> Login
///   signed in -> Home (the account type is chosen at registration, so the
///                home menu is shown directly without a separate role step)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // First boot check still running.
        if (state.status == UIStatus.loading && state.user == null) {
          return const _Splash();
        }
        if (state.user == null) {
          return const LoginPage();
        }
        return const HomePage();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.menu_book_rounded, size: 48, color: primary),
            ),
            const SizedBox(height: 20),
            Text('وِصَال', style: theme.textTheme.displayMedium),
            const SizedBox(height: 4),
            Text('لحفظ القرآن الكريم', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
