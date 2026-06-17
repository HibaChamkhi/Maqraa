import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../bloc/circle_bloc.dart';
import 'circle_info_page.dart';
import 'qr_join_page.dart';

/// US-04: join a circle via invite code (with a shortcut to QR scanning, US-29).
class JoinCirclePage extends StatelessWidget {
  final AppUser user;

  const JoinCirclePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CircleBloc>(),
      child: _JoinCircleView(user: user),
    );
  }
}

class _JoinCircleView extends StatefulWidget {
  final AppUser user;

  const _JoinCircleView({required this.user});

  @override
  State<_JoinCircleView> createState() => _JoinCircleViewState();
}

class _JoinCircleViewState extends State<_JoinCircleView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() != true) return;
    context
        .read<CircleBloc>()
        .add(CircleJoinByCodeRequested(_codeController.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الانضمام إلى حلقة')),
      body: BlocConsumer<CircleBloc, CircleState>(
        listenWhen: (prev, curr) =>
            curr.status == UIStatus.error ||
            curr.message.isNotEmpty ||
            (curr.actionDone && curr.circle != null),
        listener: (context, state) {
          if (state.status == UIStatus.error || state.message.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state.actionDone && state.circle != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                  const SnackBar(content: Text('تم الانضمام إلى الحلقة')));
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
                    Text('أدخلي رمز الدعوة',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text('رمز مكوّن من 6 خانات تحصلين عليه من معلّمة الحلقة',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      style: theme.textTheme.headlineSmall,
                      decoration: const InputDecoration(
                        labelText: 'رمز الدعوة',
                        counterText: '',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.length != 6) return 'الرمز مكوّن من 6 خانات';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: loading ? null : () => _submit(context),
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('انضمام'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QrJoinPage(user: widget.user),
                                ),
                              ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('مسح رمز QR'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('حلقات عامة',
                            style: theme.textTheme.titleMedium),
                        TextButton.icon(
                          onPressed: loading
                              ? null
                              : () => context
                                  .read<CircleBloc>()
                                  .add(const CircleDiscoverRequested()),
                          icon: const Icon(Icons.travel_explore),
                          label: const Text('اكتشاف'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DiscoverList(circles: state.discoverCircles),
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

/// List of discoverable public circles, each with a "request to join" action (US-39).
class _DiscoverList extends StatelessWidget {
  final List<Circle> circles;

  const _DiscoverList({required this.circles});

  @override
  Widget build(BuildContext context) {
    if (circles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'اضغطي «اكتشاف» لعرض الحلقات العامة',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      children: [
        for (final circle in circles)
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_2_outlined),
              title: Text(circle.name),
              trailing: TextButton(
                onPressed: () => context
                    .read<CircleBloc>()
                    .add(CircleJoinRequestSent(circle.id)),
                child: const Text('طلب انضمام'),
              ),
            ),
          ),
      ],
    );
  }
}
