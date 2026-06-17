import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../bloc/progress_bloc.dart';

/// US-12: teacher dashboard — who submitted today vs who is late.
class TeacherTrackingPage extends StatelessWidget {
  final String circleId;

  const TeacherTrackingPage({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProgressBloc>()..add(LoadTodaySubmissions(circleId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('متابعة التسليم اليومي')),
        body: BlocBuilder<ProgressBloc, ProgressState>(
          builder: (context, state) {
            if (state.status == UIStatus.loading && state.submissions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.submissions.isEmpty) {
              return const Center(child: Text('لا توجد طالبات في الحلقة بعد'));
            }
            final done = state.submissions.where((s) => s.done).length;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'سلّمت اليوم: $done من ${state.submissions.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.submissions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = state.submissions[i];
                      return ListTile(
                        leading: Icon(
                          s.done ? Icons.check_circle : Icons.schedule,
                          color: s.done ? Colors.green : Colors.orange,
                        ),
                        title: Text(s.name),
                        trailing: Text(s.done ? 'سلّمت' : 'متأخرة'),
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
