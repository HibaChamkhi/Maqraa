import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/announcement/models/announcement.dart';
import '../../../domain/auth/models/app_user.dart';
import '../bloc/announcement_bloc.dart';

/// US-14: announcements feed (newest first). Teachers/supervisors can post.
class AnnouncementsPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const AnnouncementsPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AnnouncementBloc>()..add(AnnouncementsRequested(circleId)),
      child: _AnnouncementsView(circleId: circleId, user: user),
    );
  }
}

class _AnnouncementsView extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const _AnnouncementsView({required this.circleId, required this.user});

  bool get _canPost =>
      user.role == UserRole.teacher || user.role == UserRole.supervisor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات')),
      floatingActionButton: _canPost
          ? Builder(
              builder: (ctx) => FloatingActionButton.extended(
                onPressed: () => _postDialog(ctx),
                icon: const Icon(Icons.campaign),
                label: const Text('إعلان جديد'),
              ),
            )
          : null,
      body: BlocConsumer<AnnouncementBloc, AnnouncementState>(
        listenWhen: (p, c) => c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading &&
              state.announcements.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.announcements.isEmpty) {
            return Center(
              child: Text('لا توجد إعلانات بعد',
                  style: theme.textTheme.bodyMedium),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.announcements.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _AnnouncementCard(announcement: state.announcements[index]),
          );
        },
      ),
    );
  }

  Future<void> _postDialog(BuildContext context) async {
    final bloc = context.read<AnnouncementBloc>();
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إعلان جديد'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'اكتبي نص الإعلان...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(AnnouncementPosted(
                circleId: circleId,
                text: ctrl.text,
              ));
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('نشر'),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = announcement.createdAt;
    final dateLabel = created == null
        ? ''
        : DateFormat('d MMM y • h:mm a', 'ar').format(created);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      theme.colorScheme.secondary.withValues(alpha: 0.15),
                  child: const Icon(Icons.campaign,
                      size: 18, color: AppColors.pink),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    announcement.authorName.isNotEmpty
                        ? announcement.authorName
                        : 'إدارة الحلقة',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (dateLabel.isNotEmpty)
                  Text(dateLabel, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(announcement.text, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
