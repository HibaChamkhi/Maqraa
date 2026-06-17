import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/circle/models/circle.dart';
import '../bloc/circle_bloc.dart';

/// US-41: supervisor/teacher views pending join requests and accepts/rejects.
class JoinRequestsPage extends StatelessWidget {
  final String circleId;

  const JoinRequestsPage({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CircleBloc>()..add(CirclePendingRequestsRequested(circleId)),
      child: _JoinRequestsView(circleId: circleId),
    );
  }
}

class _JoinRequestsView extends StatelessWidget {
  final String circleId;

  const _JoinRequestsView({required this.circleId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات الانضمام')),
      body: BlocConsumer<CircleBloc, CircleState>(
        listenWhen: (prev, curr) =>
            curr.status == UIStatus.error || curr.message.isNotEmpty,
        listener: (context, state) {
          if (state.message.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading &&
              state.pendingRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.pendingRequests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text('لا توجد طلبات معلّقة',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.pendingRequests.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final m = state.pendingRequests[index];
              return _RequestTile(
                member: m,
                onAccept: () => context.read<CircleBloc>().add(
                      CircleRequestAccepted(circleId: circleId, uid: m.uid),
                    ),
                onReject: () => context.read<CircleBloc>().add(
                      CircleRequestRejected(circleId: circleId, uid: m.uid),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final CircleMember member;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestTile({
    required this.member,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                member.name.isNotEmpty ? member.name.characters.first : '؟',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(member.name.isNotEmpty ? member.name : 'طالبة',
                  style: theme.textTheme.titleMedium),
            ),
            IconButton(
              tooltip: 'قبول',
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              onPressed: onAccept,
            ),
            IconButton(
              tooltip: 'رفض',
              icon: const Icon(Icons.cancel, color: AppColors.error),
              onPressed: onReject,
            ),
          ],
        ),
      ),
    );
  }
}
