import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../bloc/reminder_bloc.dart';

/// US-13: enable/disable the daily task reminder and set its time.
class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ReminderBloc>()..add(const ReminderSettingsRequested()),
      child: const _ReminderSettingsView(),
    );
  }
}

class _ReminderSettingsView extends StatelessWidget {
  const _ReminderSettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('التذكير اليومي')),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listenWhen: (p, c) => c.message.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (context, state) {
          if (state.status == UIStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = state.settings;
          final time = TimeOfDay(hour: s.hour, minute: s.minute);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('تفعيل التذكير اليومي'),
                  subtitle:
                      const Text('إشعار يومي بموعد إنجاز وردك في الحلقة'),
                  value: s.enabled,
                  onChanged: (v) => context.read<ReminderBloc>().add(
                        ReminderDailySaved(s.copyWith(enabled: v)),
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: ListTile(
                  enabled: s.enabled,
                  leading: const Icon(Icons.access_time),
                  title: const Text('وقت التذكير'),
                  subtitle: Text(time.format(context)),
                  trailing: const Icon(Icons.edit),
                  onTap: s.enabled
                      ? () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (picked == null || !context.mounted) return;
                          context.read<ReminderBloc>().add(
                                ReminderDailySaved(
                                  s.copyWith(
                                    enabled: true,
                                    hour: picked.hour,
                                    minute: picked.minute,
                                  ),
                                ),
                              );
                        }
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'ملاحظة: قد يتطلب التذكير ضبط أذونات الإشعارات على الجهاز.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
