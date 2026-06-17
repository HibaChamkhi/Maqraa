import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/achievement/models/achievement.dart';
import '../bloc/achievement_bloc.dart';

/// US-24: shows the current commitment streak and earned badges.
class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AchievementBloc>()..add(const AchievementRequested()),
      child: const _AchievementView(),
    );
  }
}

class _AchievementView extends StatelessWidget {
  const _AchievementView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إنجازاتي')),
      body: BlocConsumer<AchievementBloc, AchievementState>(
        listenWhen: (p, c) => c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading &&
              state.achievement.streakCount == 0 &&
              state.achievement.badges.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final a = state.achievement;
          final earned = a.badges
              .map(Badge.fromKey)
              .whereType<Badge>()
              .toList()
            ..sort((x, y) => x.threshold.compareTo(y.threshold));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _StreakCard(streak: a.streakCount),
              const SizedBox(height: AppSpacing.lg),
              Text('الأوسمة', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.9,
                children: Badge.values
                    .map((b) => _BadgeTile(
                          badge: b,
                          earned: earned.contains(b),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('تسجيل إنجاز اليوم'),
                onPressed: () => context
                    .read<AchievementBloc>()
                    .add(const AchievementCompletionRegistered()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.local_fire_department,
                color: AppColors.warning, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text('$streak',
                style: theme.textTheme.displaySmall
                    ?.copyWith(color: theme.colorScheme.primary)),
            Text('يوم متتالٍ من الالتزام',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Badge badge;
  final bool earned;

  const _BadgeTile({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = earned ? AppColors.pink : AppColors.textMuted;
    return Container(
      decoration: BoxDecoration(
        color: (earned ? AppColors.pink : AppColors.textMuted)
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(earned ? Icons.emoji_events : Icons.lock_outline,
              color: color, size: 32),
          const SizedBox(height: AppSpacing.xs),
          Text(
            badge.arabicLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
