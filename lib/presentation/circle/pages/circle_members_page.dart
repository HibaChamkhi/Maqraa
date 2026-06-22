import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';
import '../bloc/circle_bloc.dart';

/// US-05: list circle members with their status.
/// US-40: a teacher may promote an active student member to supervisor.
class CircleMembersPage extends StatelessWidget {
  final Circle circle;
  final AppUser user;

  const CircleMembersPage({
    super.key,
    required this.circle,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CircleBloc>()..add(CircleMembersRequested(circle.id)),
      child: _CircleMembersView(circle: circle, user: user),
    );
  }
}

class _CircleMembersView extends StatelessWidget {
  final Circle circle;
  final AppUser user;

  const _CircleMembersView({required this.circle, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Promotion is allowed only for an owner/supervisor of THIS circle.
    final canManage = circle.canManage(user);
    return Scaffold(
      appBar: AppBar(title: const Text('أعضاء الحلقة')),
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
          if (state.status == UIStatus.loading && state.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.members.isEmpty) {
            return Center(
              child: Text('لا يوجد أعضاء بعد',
                  style: theme.textTheme.bodyMedium),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.members.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final m = state.members[index];
              return _MemberTile(
                member: m,
                canPromote: canManage &&
                    m.role == UserRole.student &&
                    m.status == MemberStatus.active,
                onPromote: () => context.read<CircleBloc>().add(
                      CircleMemberPromoted(circleId: circle.id, uid: m.uid),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CircleMember member;
  final bool canPromote;
  final VoidCallback onPromote;

  const _MemberTile({
    required this.member,
    required this.canPromote,
    required this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = member.status == MemberStatus.pending;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Text(
            member.name.isNotEmpty ? member.name.characters.first : '؟',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        title: Text(member.name.isNotEmpty ? member.name : 'عضوة',
            style: theme.textTheme.titleMedium),
        subtitle: Text(member.role.arabicLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: (isPending ? AppColors.warning : AppColors.success)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                member.status.arabicLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isPending ? AppColors.warning : AppColors.success,
                ),
              ),
            ),
            if (canPromote)
              IconButton(
                tooltip: 'ترقية إلى مشرفة',
                icon: const Icon(Icons.arrow_upward),
                onPressed: onPromote,
              ),
          ],
        ),
      ),
    );
  }
}
