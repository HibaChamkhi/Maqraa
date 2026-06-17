import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/call/models/weekly_call.dart';
import '../bloc/call_bloc.dart';
import 'call_attendance_page.dart';

/// US-18: teacher schedules the weekly call.
/// US-19: student confirms attendance for the (latest) weekly call.
class WeeklyCallPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const WeeklyCallPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CallBloc>()..add(CallsRequested(circleId)),
      child: _WeeklyCallView(circleId: circleId, user: user),
    );
  }
}

class _WeeklyCallView extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const _WeeklyCallView({required this.circleId, required this.user});

  bool get _canManage =>
      user.role == UserRole.teacher || user.role == UserRole.supervisor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('المكالمة الأسبوعية')),
      floatingActionButton: _canManage
          ? Builder(
              builder: (ctx) => FloatingActionButton.extended(
                onPressed: () => _scheduleDialog(ctx),
                icon: const Icon(Icons.add),
                label: const Text('جدولة'),
              ),
            )
          : null,
      body: BlocConsumer<CallBloc, CallState>(
        listenWhen: (p, c) => c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.calls.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.calls.isEmpty) {
            return Center(
              child: Text('لا توجد مكالمات مجدولة بعد',
                  style: theme.textTheme.bodyMedium),
            );
          }
          final latestId = state.calls.first.id;
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.calls.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final call = state.calls[index];
              final isLatest = call.id == latestId;
              return _CallCard(
                call: call,
                isLatest: isLatest,
                canManage: _canManage,
                myAttendance: state.myAttendance,
                onConfirm: (present) => context.read<CallBloc>().add(
                      CallAttendanceConfirmed(
                        circleId: circleId,
                        callId: call.id,
                        present: present,
                      ),
                    ),
                onViewAttendance: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CallAttendancePage(
                      circleId: circleId,
                      callId: call.id,
                      callTitle: call.title,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _scheduleDialog(BuildContext context) async {
    final bloc = context.read<CallBloc>();
    final titleCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    DateTime? when;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return AlertDialog(
              title: const Text('جدولة المكالمة الأسبوعية'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'العنوان'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(labelText: 'الرابط'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(when == null
                          ? 'اختيار الوقت'
                          : DateFormat('d MMM • h:mm a', 'ar').format(when!)),
                      onPressed: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: dialogCtx,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 90)),
                        );
                        if (date == null || !dialogCtx.mounted) return;
                        final time = await showTimePicker(
                          context: dialogCtx,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time == null) return;
                        setState(() => when = DateTime(date.year, date.month,
                            date.day, time.hour, time.minute));
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (when == null) return;
                    bloc.add(CallScheduled(
                      circleId: circleId,
                      title: titleCtrl.text,
                      time: when!,
                      link: linkCtrl.text,
                    ));
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CallCard extends StatelessWidget {
  final WeeklyCall call;
  final bool isLatest;
  final bool canManage;
  final bool myAttendance;
  final ValueChanged<bool> onConfirm;
  final VoidCallback onViewAttendance;

  const _CallCard({
    required this.call,
    required this.isLatest,
    required this.canManage,
    required this.myAttendance,
    required this.onConfirm,
    required this.onViewAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEEE d MMM • h:mm a', 'ar');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(call.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(fmt.format(call.time), style: theme.textTheme.bodySmall),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              const Icon(Icons.link, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(call.link,
                    style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            if (canManage)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.people_outline),
                  label: const Text('قائمة الحضور'),
                  onPressed: onViewAttendance,
                ),
              )
            else if (isLatest)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(myAttendance
                          ? Icons.check_circle
                          : Icons.check_circle_outline),
                      label: Text(myAttendance ? 'حضوري مؤكّد' : 'تأكيد الحضور'),
                      onPressed: () => onConfirm(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => onConfirm(false),
                    child: const Text('اعتذار'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
