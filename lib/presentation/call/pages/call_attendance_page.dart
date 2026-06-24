import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../bloc/call_bloc.dart';

/// US-19: teacher views the attendance list of a weekly call.
class CallAttendancePage extends StatelessWidget {
  final String circleId;
  final String callId;
  final String callTitle;

  const CallAttendancePage({
    super.key,
    required this.circleId,
    required this.callId,
    required this.callTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CallBloc>()
        ..add(CallAttendanceRequested(circleId: circleId, callId: callId)),
      child: Scaffold(
        appBar: AppBar(title: Text('حضور: $callTitle')),
        body: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            final theme = Theme.of(context);
            if (state.status == UIStatus.loading && state.attendance.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.attendance.isEmpty) {
              return Center(
                child: Text('لا يوجد تأكيدات حضور بعد',
                    style: theme.textTheme.bodyMedium),
              );
            }
            final present =
                state.attendance.where((a) => a.present).length;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'الحاضرات: $present من ${state.attendance.length}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemCount: state.attendance.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final a = state.attendance[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            a.present ? Icons.check_circle : Icons.cancel,
                            color: a.present
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          title: Text(a.name.isNotEmpty ? a.name : 'عضوة'),
                          subtitle:
                              Text(a.present ? 'حاضرة' : 'معتذرة'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
