import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/model /ui_state.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_widget.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const Color _cream = Color(0xFFF6F1E8);
  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == UIStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state.status == UIStatus.success && state.user != null) {
          // Signed in — drop the auth stack so the gate shows Home.
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: _ink, size: 30),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              const Expanded(child: LoginWidget()),
            ],
          ),
        ),
      ),
    );
  }
}
