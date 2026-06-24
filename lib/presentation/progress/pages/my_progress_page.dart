import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/ui/widgets/werd_widgets.dart';
import '../../profile/pages/web_shell.dart';
import '../bloc/progress_bloc.dart';

/// US-11: student progress — memorization ring, streak, badges and quick log.
class MyProgressPage extends StatelessWidget {
  const MyProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProgressBloc>()..add(const LoadMyProgress()),
      child: Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: !ShellScope.of(context),
            title: const Text('تقدّمي')),
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
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // --- Memorization ring ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        ProgressRing(
                          value: info.ratio,
                          size: 170,
                          stroke: 16,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${info.percent}%',
                                  style: theme.textTheme.displaySmall),
                              Text('إجمالي الحفظ',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('${info.pagesDone} من ${info.totalPages} صفحة',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Streak ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('سلسلة الالتزام',
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Text('حافظي على وردك اليومي',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        StreakBadge(days: state.submissions.length),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Badges (illustrative until achievements feed the model) ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(title: 'الشارات'),
                        const SizedBox(height: AppSpacing.sm),
                        const Wrap(
                          alignment: WrapAlignment.spaceAround,
                          runSpacing: 12,
                          children: [
                            AchievementBadge(
                                icon: Icons.star_rounded, label: 'أسبوع متواصل'),
                            AchievementBadge(
                                icon: Icons.local_fire_department,
                                label: '30 يوم',
                                color: AppColors.primary),
                            AchievementBadge(
                                icon: Icons.workspace_premium,
                                label: 'أجزاء محفوظة',
                                color: AppColors.primaryLight),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Quick log ---
                Text('سجّلي ما أنجزتِه اليوم',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 12,
                  children: [1, 2, 5].map((n) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(96, 48)),
                      onPressed: state.status == UIStatus.loading
                          ? null
                          : () => context.read<ProgressBloc>().add(AddProgress(n)),
                      child: Text('+ $n صفحة'),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
