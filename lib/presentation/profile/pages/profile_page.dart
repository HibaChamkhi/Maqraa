import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

/// US-36 (view/edit profile) + US-37 (secure password change).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _name = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save(AppUser user) {
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(uid: user.uid, name: _name.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == UIStatus.error) {
            ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state.status == UIStatus.success && state.user != null) {
            // Refresh the global user so the new data shows everywhere.
            context.read<AuthBloc>().add(const AuthCheckRequested());
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
          }
        },
        builder: (context, state) {
          final saving = state.status == UIStatus.loading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      backgroundImage:
                          user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null
                          ? Icon(Icons.person, size: 44, color: theme.colorScheme.primary)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text(user.role?.arabicLabel ?? '', style: theme.textTheme.bodyMedium)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReadOnlyTile(icon: Icons.email_outlined, label: 'البريد', value: user.email),
                  if (user.phone != null)
                    _ReadOnlyTile(icon: Icons.phone_outlined, label: 'الهاتف', value: user.phone!),
                  _ReadOnlyTile(
                    icon: Icons.wc_outlined,
                    label: 'الجنس',
                    value: user.gender?.arabicLabel ?? '-',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: saving ? null : () => _save(user),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ التعديلات'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthBloc>(),
                        child: const _ChangePasswordDialog(),
                      ),
                    ),
                    icon: const Icon(Icons.lock_reset_outlined),
                    label: const Text('تغيير كلمة المرور'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == UIStatus.error) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state.status == UIStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
        }
      },
      child: AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                validator: (v) => (v == null || v.length < 6) ? '٦ أحرف على الأقل' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                validator: (v) => v != _next.text ? 'غير متطابقة' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(
                      AuthPasswordChangeRequested(
                        currentPassword: _current.text,
                        newPassword: _next.text,
                      ),
                    );
              }
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }
}
