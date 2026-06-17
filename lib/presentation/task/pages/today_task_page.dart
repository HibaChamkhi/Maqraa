import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/task/models/daily_task.dart';
import '../bloc/task_bloc.dart';

/// US-08: the student sees today's task prominently.
/// US-09: records completion and requests partner confirmation.
class TodayTaskPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const TodayTaskPage({super.key, required this.circleId, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskBloc>()
        ..add(TaskTodayLoadRequested(circleId: circleId, uid: user.uid)),
      child: _TodayTaskView(circleId: circleId, user: user),
    );
  }
}

class _TodayTaskView extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const _TodayTaskView({required this.circleId, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('مهمة اليوم')),
      body: BlocConsumer<TaskBloc, TaskState>(
        listenWhen: (p, c) => p.message != c.message && c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final task = state.todayTask;
          if (task == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.task_alt_outlined,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.sm),
                    Text('لا توجد مهمة مسجّلة لليوم',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TaskCard(task: task),
                  const SizedBox(height: AppSpacing.md),
                  _StatusBanner(task: task),
                  const SizedBox(height: AppSpacing.md),
                  if (task.status != TaskStatus.done)
                    ElevatedButton.icon(
                      onPressed: () => _askConfirmation(context, state, task),
                      icon: const Icon(Icons.how_to_reg_outlined),
                      label: Text(task.awaitingConfirmation
                          ? 'إعادة إرسال طلب التأكيد'
                          : 'سجّلتُ الحفظ — اطلبي تأكيد الرفيقة'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _askConfirmation(BuildContext context, TaskState state, DailyTask task) {
    final controller = TextEditingController(text: task.partnerId ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('طلب تأكيد الرفيقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخلي معرّف الرفيقة (uid) التي ستؤكد تسميعك:'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'معرّف الرفيقة',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final partnerId = controller.text.trim();
              if (partnerId.isEmpty) return;
              context.read<TaskBloc>().add(
                    TaskConfirmationRequested(
                      circleId: circleId,
                      dateId: state.dateId,
                      task: task,
                      partnerId: partnerId,
                    ),
                  );
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTask task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.menu_book_outlined, color: Colors.white),
                SizedBox(width: AppSpacing.sm),
                Text('المقطع المطلوب',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              task.range.isNotEmpty ? task.range : '—',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (task.note != null && task.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(task.note!,
                  style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final DailyTask task;

  const _StatusBanner({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    final IconData icon;
    final String label;
    if (task.status == TaskStatus.done) {
      color = AppColors.success;
      icon = Icons.verified_outlined;
      label = 'مُنجز — أكّدته الرفيقة';
    } else if (task.awaitingConfirmation) {
      color = AppColors.warning;
      icon = Icons.hourglass_top_outlined;
      label = 'بانتظار تأكيد الرفيقة';
    } else {
      color = AppColors.textMuted;
      icon = Icons.pending_outlined;
      label = 'لم يُسجَّل الحفظ بعد';
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
