import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/schedule/models/weekly_schedule.dart';
import '../bloc/schedule_bloc.dart';

/// US-06: teacher publishes a weekly memorization schedule (a range per day).
class PublishSchedulePage extends StatelessWidget {
  final String circleId;

  const PublishSchedulePage({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScheduleBloc>()
        ..add(ScheduleLoadRequested(circleId: circleId)),
      child: _PublishView(circleId: circleId),
    );
  }
}

class _PublishView extends StatefulWidget {
  final String circleId;

  const _PublishView({required this.circleId});

  @override
  State<_PublishView> createState() => _PublishViewState();
}

class _PublishViewState extends State<_PublishView> {
  final Map<String, TextEditingController> _controllers = {
    for (final code in WeeklySchedule.dayOrder) code: TextEditingController(),
  };
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(WeeklySchedule schedule) {
    for (final code in WeeklySchedule.dayOrder) {
      _controllers[code]!.text = schedule.days[code] ?? '';
    }
  }

  void _publish() {
    final state = context.read<ScheduleBloc>().state;
    final weekStart = state.weekStart ?? DateTime.now();
    final days = <String, String>{
      for (final code in WeeklySchedule.dayOrder)
        code: _controllers[code]!.text.trim(),
    };
    context.read<ScheduleBloc>().add(
          SchedulePublishRequested(
            circleId: widget.circleId,
            weekStart: weekStart,
            days: days,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('نشر جدول الأسبوع')),
      body: BlocConsumer<ScheduleBloc, ScheduleState>(
        listenWhen: (p, c) => p.status != c.status || p.schedule != c.schedule,
        listener: (context, state) {
          if (state.status == UIStatus.error) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state.status == UIStatus.success) {
            if (!_prefilled && state.schedule != null) {
              _prefill(state.schedule!);
              _prefilled = true;
            }
            if (state.message.isNotEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          }
        },
        builder: (context, state) {
          final saving = state.status == UIStatus.loading;
          final weekStart = state.weekStart;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (weekStart != null)
                    Card(
                      color: AppColors.sky,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'أسبوع يبدأ ${DateFormat('yyyy/MM/dd').format(weekStart)}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final code in WeeklySchedule.dayOrder)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: TextField(
                        controller: _controllers[code],
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: WeeklySchedule.arabicDay(code),
                          hintText: 'المقطع المطلوب حفظه',
                          prefixIcon: const Icon(Icons.menu_book_outlined),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: saving ? null : _publish,
                    icon: const Icon(Icons.publish_outlined),
                    label: Text(saving ? 'جارٍ النشر...' : 'نشر الجدول'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
