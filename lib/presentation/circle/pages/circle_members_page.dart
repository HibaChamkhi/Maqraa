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
              final isOwnerUser = circle.isOwner(user);
              final active = m.status == MemberStatus.active;
              final isCircleOwner = m.uid == circle.teacherId;
              return _MemberTile(
                member: m,
                // Managing supervisors (promote/demote) is owner-only.
                onPromote:
                    (isOwnerUser && m.role == UserRole.student && active)
                        ? () => context.read<CircleBloc>().add(
                            CircleMemberPromoted(
                                circleId: circle.id, uid: m.uid))
                        : null,
                onDemote: (isOwnerUser && m.role == UserRole.supervisor)
                    ? () => context.read<CircleBloc>().add(
                        CircleMemberDemoted(circleId: circle.id, uid: m.uid))
                    : null,
                // Owner can remove anyone (not herself); a supervisor may only
                // remove students, never another supervisor.
                onRemove: (canManage &&
                        active &&
                        !isCircleOwner &&
                        m.uid != user.uid &&
                        (isOwnerUser || m.role == UserRole.student))
                    ? () => _confirmRemove(context, m)
                    : null,
                onTransfer: (isOwnerUser && active && !isCircleOwner)
                    ? () => _confirmTransfer(context, m)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, CircleMember m) async {
    final bloc = context.read<CircleBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إزالة من الحلقة'),
        content: Text('هل تريدين إزالة «${m.name}» من الحلقة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إزالة')),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(CircleMemberRemoved(circleId: circle.id, uid: m.uid));
    }
  }

  Future<void> _confirmTransfer(BuildContext context, CircleMember m) async {
    final bloc = context.read<CircleBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نقل ملكية الحلقة'),
        content: Text(
            'ستصبح «${m.name}» معلّمة الحلقة، وستصبحين أنتِ مشرفة. هل أنتِ متأكدة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نقل الملكية')),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(CircleOwnershipTransferred(
          circleId: circle.id, newTeacherId: m.uid));
    }
  }
}

class _MemberTile extends StatelessWidget {
  final CircleMember member;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onRemove;
  final VoidCallback? onTransfer;

  const _MemberTile({
    required this.member,
    this.onPromote,
    this.onDemote,
    this.onRemove,
    this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = member.status == MemberStatus.pending;
    final actions = <PopupMenuEntry<String>>[
      if (onPromote != null)
        const PopupMenuItem(value: 'promote', child: Text('ترقية إلى مشرفة')),
      if (onDemote != null)
        const PopupMenuItem(value: 'demote', child: Text('إرجاع إلى طالبة')),
      if (onTransfer != null)
        const PopupMenuItem(value: 'transfer', child: Text('نقل ملكية الحلقة')),
      if (onRemove != null)
        const PopupMenuItem(
          value: 'remove',
          child: Text('إزالة من الحلقة',
              style: TextStyle(color: AppColors.error)),
        ),
    ];
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
            if (actions.isNotEmpty)
              PopupMenuButton<String>(
                tooltip: 'إجراءات',
                itemBuilder: (_) => actions,
                onSelected: (v) {
                  switch (v) {
                    case 'promote':
                      onPromote?.call();
                      break;
                    case 'demote':
                      onDemote?.call();
                      break;
                    case 'transfer':
                      onTransfer?.call();
                      break;
                    case 'remove':
                      onRemove?.call();
                      break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
