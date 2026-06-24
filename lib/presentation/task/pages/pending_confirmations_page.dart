import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/task/models/daily_task.dart';
import '../bloc/task_bloc.dart';

/// US-10: list of pending confirmations addressed to the current user
/// (tasks where partnerId == my uid and not yet confirmed), with a confirm action.
class PendingConfirmationsPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const PendingConfirmationsPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskBloc>()
        ..add(PendingConfirmationsLoadRequested(
            circleId: circleId, partnerUid: user.uid)),
      child: _PendingView(circleId: circleId, user: user),
    );
  }
}

class _PendingView extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const _PendingView({required this.circleId, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات تأكيد التسميع')),
      body: BlocConsumer<TaskBloc, TaskState>(
        listenWhen: (p, c) => p.message != c.message && c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading &&
              state.pendingConfirmations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final pending = state.pendingConfirmations;
          if (pending.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.done_all_outlined,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.sm),
                    Text('لا توجد طلبات تأكيد حالياً',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final task = pending[i];
              return _ConfirmTile(
                task: task,
                onConfirm: () => context.read<TaskBloc>().add(
                      PeerTaskConfirmed(
                        circleId: circleId,
                        dateId: state.dateId,
                        studentUid: task.uid,
                      ),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConfirmTile extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onConfirm;

  const _ConfirmTile({required this.task, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.pink.withValues(alpha: 0.25),
                  child: Text(
                    task.name.isNotEmpty ? task.name.characters.first : '؟',
                    style: const TextStyle(color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.name, style: theme.textTheme.titleMedium),
                      Text(
                        task.range.isNotEmpty ? task.range : '—',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: onConfirm,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تأكيد التسميع'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
