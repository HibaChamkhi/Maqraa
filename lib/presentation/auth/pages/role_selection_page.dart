import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../bloc/auth_bloc.dart';

/// US-02: choose your role. The screen the user lands on differs by role.
/// (AuthGate routes to Home automatically once a role is set.)
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  static const _roles = [
    (UserRole.teacher, 'معلّمة', 'أنشئي الحلقات وتابعي الطالبات', Icons.school_outlined),
    (UserRole.supervisor, 'مشرفة', 'ساعدي في الإدارة وقبول الطلبات', Icons.verified_user_outlined),
    (UserRole.student, 'طالبة', 'تابعي واجبك اليومي وتقدّمك', Icons.menu_book_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختاري دورك'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final loading = state.status == UIStatus.loading;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('كيف ستستخدمين «وصال»؟',
                        textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 20),
                    for (final r in _roles) ...[
                      Card(
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                            child: Icon(r.$4, color: theme.colorScheme.primary),
                          ),
                          title: Text(r.$2, style: theme.textTheme.titleMedium),
                          subtitle: Text(r.$3),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: loading
                              ? null
                              : () => context.read<AuthBloc>().add(AuthRoleSelected(r.$1)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (loading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
