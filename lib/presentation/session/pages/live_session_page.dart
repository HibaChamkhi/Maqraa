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
                    ...state.attendance.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.sky,
                              child: Text(
                                  a.name.isNotEmpty
                                      ? a.name.characters.first
                                      : '؟',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F6B5B), Color(0xFF09463A)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.podcasts, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('جلسة مباشرة',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(session.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(dateFormat.format(session.scheduledAt),
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (session.link.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SelectableText(session.link,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.error,
            ),
            onPressed: onEnd,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('إنهاء الجلسة'),
          ),
        ],
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
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F1F2937), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.sky,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Icon(Icons.event_busy,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('لا توجد جلسات مجدولة', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('أضيفي جلسة من تبويب «الجدول» لبدئها هنا',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('جلسات مجدولة', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...scheduled.map((s) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: const Icon(Icons.event_outlined,
                      color: AppColors.primary),
                ),
                title: Text(s.title, style: theme.textTheme.titleSmall),
                subtitle: Text(dateFormat.format(s.scheduledAt),
                    style: theme.textTheme.bodySmall),
                trailing: FilledButton.icon(
                  onPressed: () => onStart(s),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('بدء'),
                ),
              ),
            )),
      ],
    );
  }
}
