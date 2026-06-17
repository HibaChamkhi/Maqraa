import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../bloc/progress_bloc.dart';

/// US-11: student progress bar (pages completed out of the mushaf).
class MyProgressPage extends StatelessWidget {
  const MyProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProgressBloc>()..add(const LoadMyProgress()),
      child: Scaffold(
        appBar: AppBar(title: const Text('تقدّمي في الحفظ')),
        body: BlocConsumer<ProgressBloc, ProgressState>(
          listenWhen: (p, c) => c.status == UIStatus.error,
          listener: (context, state) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message))),
          builder: (context, state) {
            final info = state.progress;
            if (info == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text('${info.percent}%', style: theme.textTheme.displaySmall),
                          const SizedBox(height: 8),
                          Text('${info.pagesDone} من ${info.totalPages} صفحة'),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: info.ratio,
                              minHeight: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('سجّلي ما أنجزتِه اليوم', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [1, 2, 5].map((n) {
                      return ElevatedButton(
                        onPressed: state.status == UIStatus.loading
                            ? null
                            : () => context.read<ProgressBloc>().add(AddProgress(n)),
                        child: Text('+ $n صفحة'),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
