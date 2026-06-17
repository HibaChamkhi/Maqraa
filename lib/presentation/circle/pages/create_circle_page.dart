import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/circle/models/circle.dart';
import '../bloc/circle_bloc.dart';
import 'circle_info_page.dart';

/// US-03: teacher creates a circle.
class CreateCirclePage extends StatelessWidget {
  const CreateCirclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CircleBloc>(),
      child: const _CreateCircleView(),
    );
  }
}

class _CreateCircleView extends StatefulWidget {
  const _CreateCircleView();

  @override
  State<_CreateCircleView> createState() => _CreateCircleViewState();
}

class _CreateCircleViewState extends State<_CreateCircleView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Privacy _privacy = Privacy.private;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() != true) return;
    context.read<CircleBloc>().add(
          CircleCreateRequested(
            name: _nameController.text,
            privacy: _privacy,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حلقة')),
      body: BlocConsumer<CircleBloc, CircleState>(
        listenWhen: (prev, curr) =>
            curr.status == UIStatus.error ||
            (curr.actionDone && curr.circle != null),
        listener: (context, state) {
          if (state.status == UIStatus.error) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state.actionDone && state.circle != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CircleInfoPage(circleId: state.circle!.id),
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state.status == UIStatus.loading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('أنشئي حلقتك القرآنية',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'اسم الحلقة',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'يرجى إدخال اسم الحلقة'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('خصوصية الحلقة', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    _PrivacyOption(
                      title: 'خاصة',
                      subtitle: 'الانضمام عبر رمز الدعوة فقط',
                      icon: Icons.lock_outline,
                      selected: _privacy == Privacy.private,
                      onTap: () => setState(() => _privacy = Privacy.private),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PrivacyOption(
                      title: 'عامة',
                      subtitle: 'يمكن اكتشافها وإرسال طلب انضمام',
                      icon: Icons.public,
                      selected: _privacy == Privacy.public,
                      onTap: () => setState(() => _privacy = Privacy.public),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: loading ? null : () => _submit(context),
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('إنشاء الحلقة'),
                    ),
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

class _PrivacyOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PrivacyOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? theme.colorScheme.primary
                    : AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
