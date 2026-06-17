import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/model /ui_state.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/pages/login_page.dart';
import '../auth/pages/role_selection_page.dart';
import '../home/pages/home_page.dart';

/// Decides which screen to show based on the current auth state:
///   no user            -> Login
///   user without role  -> Role selection (US-02)
///   user with role     -> Home (routed by role)
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
        if (state.user!.role == null) {
          return const RoleSelectionPage();
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('وصال', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
