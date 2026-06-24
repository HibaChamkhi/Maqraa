import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/model /ui_state.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/pages/welcome_page.dart';
import '../home/pages/home_page.dart';
import 'splash_screen.dart';

/// Decides which screen to show based on the current auth state:
///   no user   -> Login
///   signed in -> Home (the account type is chosen at registration, so the
///                home menu is shown directly without a separate role step)
///
/// The branded splash is shown for at least [_minSplash] so it is always
/// visible, even when the auth check resolves almost instantly.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const Duration _minSplash = Duration(milliseconds: 2200);

  bool _minElapsed = false;

  @override
  void initState() {
    super.initState();
    Timer(_minSplash, () {
      if (mounted) setState(() => _minElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // On logout (user went from signed-in to null) clear any pushed routes
      // (settings, profile, workspace…) so the login screen actually shows.
      listenWhen: (prev, curr) => prev.user != null && curr.user == null,
      listener: (context, state) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((r) => r.isFirst);
      },
      builder: (context, state) {
        final checking = state.status == UIStatus.loading && state.user == null;
        // Keep the splash until BOTH the minimum time has passed and the
        // first-boot auth check has finished.
        if (!_minElapsed || checking) {
          return const WesalSplash();
        }
        if (state.user == null) {
          return const WelcomePage();
        }
        return const HomePage();
      },
    );
  }
}
