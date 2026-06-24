import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/session/models/session.dart';
import '../bloc/session_bloc.dart';

/// US-33: student joins the active (live) session — records attendance and
/// shows the join link.
class StudentSessionPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const StudentSessionPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SessionBloc>()..add(SessionActiveRequested(circleId)),
      child: _StudentSessionView(circleId: circleId),
    );
  }
}

class _StudentSessionView extends StatelessWidget {
  final String circleId;

  const _StudentSessionView({required this.circleId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM • h:mm a', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('الجلسة المباشرة')),
      body: BlocConsumer<SessionBloc, SessionState>(
        listenWhen: (prev, curr) => curr.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.activeSession == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final active = state.activeSession;
          if (active == null || active.status != SessionStatus.live) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.podcasts_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    Text('لا توجد جلسة مباشرة حالياً',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('سيظهر زر الانضمام عند بدء المعلّمة للجلسة',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: AppColors.success.withValues(alpha: 0.10),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.podcasts,
                                color: AppColors.success),
                            const SizedBox(width: AppSpacing.sm),
                            Text('جلسة مباشرة الآن',
                                style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(active.title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xs),
                        Text(dateFormat.format(active.scheduledAt),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.joined) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Text('تم تسجيل حضورك',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                  if (active.link.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('رابط الجلسة', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(active.link,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ] else
                  ElevatedButton.icon(
                    onPressed: state.status == UIStatus.loading
                        ? null
                        : () => context.read<SessionBloc>().add(
                              SessionJoinRequested(
                                circleId: circleId,
                                sessionId: active.id,
                              ),
                            ),
                    icon: const Icon(Icons.login),
                    label: const Text('الانضمام وتسجيل الحضور'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
