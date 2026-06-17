import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/session/models/session.dart';
import '../bloc/session_bloc.dart';

/// US-32 + US-42: teacher/supervisor starts/ends a session and watches the
/// live attendance list of present students.
class LiveSessionPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const LiveSessionPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SessionBloc>()..add(SessionActiveRequested(circleId)),
      child: _LiveSessionView(circleId: circleId, user: user),
    );
  }
}

class _LiveSessionView extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const _LiveSessionView({required this.circleId, required this.user});

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
          final active = state.activeSession;
          if (active != null && active.status == SessionStatus.live) {
            context.read<SessionBloc>().add(SessionAttendanceRequested(
                  circleId: circleId,
                  sessionId: active.id,
                ));
          }
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final active = state.activeSession;
          final scheduled = state.sessions
              .where((s) => s.status == SessionStatus.scheduled)
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (active != null && active.status == SessionStatus.live)
                  _ActiveCard(
                    session: active,
                    dateFormat: dateFormat,
                    onEnd: () => context.read<SessionBloc>().add(
                          SessionEndRequested(
                            circleId: circleId,
                            sessionId: active.id,
                          ),
                        ),
                  )
                else
                  _NoActiveCard(
                    scheduled: scheduled,
                    dateFormat: dateFormat,
                    onStart: (s) => context.read<SessionBloc>().add(
                          SessionStartRequested(
                            circleId: circleId,
                            sessionId: s.id,
                          ),
                        ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (active != null && active.status == SessionStatus.live) ...[
                  Text('الحاضرات الآن (${state.attendance.length})',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.attendance.isEmpty)
                    Text('لا توجد حاضرات بعد',
                        style: theme.textTheme.bodySmall)
                  else
                    ...state.attendance.map((a) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(a.name),
                            trailing: const Icon(Icons.check_circle,
                                color: AppColors.success),
                          ),
                        )),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.read<SessionBloc>().add(
                          SessionAttendanceRequested(
                            circleId: circleId,
                            sessionId: active.id,
                          ),
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث قائمة الحضور'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final Session session;
  final DateFormat dateFormat;
  final VoidCallback onEnd;

  const _ActiveCard({
    required this.session,
    required this.dateFormat,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.success.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.podcasts, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text('جلسة مباشرة', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(session.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(dateFormat.format(session.scheduledAt),
                style: theme.textTheme.bodySmall),
            if (session.link.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SelectableText(session.link,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.primary)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              onPressed: onEnd,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('إنهاء الجلسة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveCard extends StatelessWidget {
  final List<Session> scheduled;
  final DateFormat dateFormat;
  final ValueChanged<Session> onStart;

  const _NoActiveCard({
    required this.scheduled,
    required this.dateFormat,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (scheduled.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(Icons.event_busy,
                  size: 40, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.sm),
              Text('لا توجد جلسات مجدولة',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('أضيفي جلسة من التقويم لبدئها هنا',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('جلسات مجدولة', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...scheduled.map((s) => Card(
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(s.title),
                subtitle: Text(dateFormat.format(s.scheduledAt)),
                trailing: FilledButton(
                  onPressed: () => onStart(s),
                  child: const Text('بدء'),
                ),
              ),
            )),
      ],
    );
  }
}
