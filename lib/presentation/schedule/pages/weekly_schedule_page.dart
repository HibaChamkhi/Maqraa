import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/schedule/models/weekly_schedule.dart';
import '../bloc/schedule_bloc.dart';

/// US-07: student views the current week's schedule, ordered by day.
class WeeklySchedulePage extends StatelessWidget {
  final String circleId;

  const WeeklySchedulePage({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScheduleBloc>()
        ..add(ScheduleLoadRequested(circleId: circleId)),
      child: const _WeeklyView(),
    );
  }
}

class _WeeklyView extends StatelessWidget {
  const _WeeklyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayCode = _todayCode();
    return Scaffold(
      appBar: AppBar(title: const Text('جدول الأسبوع')),
      body: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          if (state.status == UIStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == UIStatus.error) {
            return Center(child: Text(state.message));
          }
          final schedule = state.schedule;
          if (schedule == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy_outlined,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.sm),
                    Text('لم يُنشر جدول لهذا الأسبوع بعد',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                color: AppColors.sky,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'أسبوع يبدأ ${DateFormat('yyyy/MM/dd').format(schedule.weekStart)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final code in WeeklySchedule.dayOrder)
                _DayTile(
                  day: WeeklySchedule.arabicDay(code),
                  range: schedule.days[code] ?? '',
                  isToday: code == todayCode,
                ),
            ],
          );
        },
      ),
    );
  }

  String _todayCode() {
    const map = {
      DateTime.saturday: 'sat',
      DateTime.sunday: 'sun',
      DateTime.monday: 'mon',
      DateTime.tuesday: 'tue',
      DateTime.wednesday: 'wed',
      DateTime.thursday: 'thu',
      DateTime.friday: 'fri',
    };
    return map[DateTime.now().weekday] ?? '';
  }
}

class _DayTile extends StatelessWidget {
  final String day;
  final String range;
  final bool isToday;

  const _DayTile({
    required this.day,
    required this.range,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRange = range.isNotEmpty;
    return Card(
      color: isToday
          ? AppColors.primaryLight.withValues(alpha: 0.25)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: isToday
            ? const BorderSide(color: AppColors.primary, width: 1.4)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: const Icon(Icons.menu_book_outlined,
              color: AppColors.primary, size: 20),
        ),
        title: Row(
          children: [
            Text(day, style: theme.textTheme.titleMedium),
            if (isToday) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('اليوم',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          hasRange ? range : 'لا يوجد تكليف',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasRange ? null : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
