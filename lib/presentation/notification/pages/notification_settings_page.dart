import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../domain/notification/models/app_notification.dart';
import '../../profile/pages/profile_theme.dart';
import '../bloc/notification_bloc.dart';

/// إعدادات الإشعارات — master switch, per-type switches, and quiet-hours range.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<NotificationBloc>()..add(const NotificationSettingsRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  static const _types = <String, NotificationType>{
    'تذكير الصلاة': NotificationType.prayer,
    'الواجبات': NotificationType.homework,
    'الاختبارات': NotificationType.exam,
    'الإنجازات': NotificationType.achievement,
    'الرسائل من المعلمين': NotificationType.teacherMessage,
    'تنبيهات الحضور': NotificationType.attendance,
  };

  void _save(BuildContext context, NotificationSettings s) =>
      context.read<NotificationBloc>().add(NotificationSettingsSaved(s));

  Future<void> _pickTime(
      BuildContext context, NotificationSettings s, bool isFrom) async {
    final parts = (isFrom ? s.fromTime : s.toTime).split(':');
    final initial = TimeOfDay(
        hour: int.tryParse(parts.first) ?? 8,
        minute: int.tryParse(parts.last) ?? 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final str = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    if (!context.mounted) return;
    _save(context, isFrom ? s.copyWith(fromTime: str) : s.copyWith(toTime: str));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text('إعدادات الإشعارات',
                        textAlign: TextAlign.center,
                        style: ProfileTheme.appBarTitle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: ProfileTheme.ink),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  final s = state.settings;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      _Card(
                        child: _ToggleRow(
                          label: 'تفعيل الإشعارات',
                          value: s.enabled,
                          onChanged: (v) =>
                              _save(context, s.copyWith(enabled: v)),
                          bold: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('نوع الإشعارات', style: ProfileTheme.sectionTitle),
                      const SizedBox(height: 12),
                      _Card(
                        child: Column(
                          children: [
                            for (final entry in _types.entries) ...[
                              _ToggleRow(
                                label: entry.key,
                                value: s.enabled &&
                                    s.typeEnabled(entry.value.name),
                                onChanged: s.enabled
                                    ? (v) {
                                        final types =
                                            Map<String, bool>.from(s.types);
                                        types[entry.value.name] = v;
                                        _save(context,
                                            s.copyWith(types: types));
                                      }
                                    : null,
                              ),
                              if (entry.key != _types.keys.last)
                                const Divider(
                                    height: 18, color: ProfileTheme.border),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('وقت الإشعارات', style: ProfileTheme.sectionTitle),
                      const SizedBox(height: 12),
                      _Card(
                        child: Row(
                          children: [
                            Expanded(
                              child: _TimeBox(
                                label: 'من',
                                time: s.fromTime,
                                onTap: () => _pickTime(context, s, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeBox(
                                label: 'إلى',
                                time: s.toTime,
                                onTap: () => _pickTime(context, s, false),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'يمكنك التحكم في الأوقات التي ترغب باستقبال الإشعارات خلالها.',
                        style: ProfileTheme.hint,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: ProfileTheme.cardShadow,
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.bold = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Switch(
            value: value,
            activeThumbColor: ProfileTheme.green,
            onChanged: onChanged,
          ),
          const Spacer(),
          Text(label,
              style: TextStyle(
                  color: ProfileTheme.ink,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 15 : 14)),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox(
      {required this.label, required this.time, required this.onTap});
  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: ProfileTheme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ProfileTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ProfileTheme.hint),
            Text(time,
                style: const TextStyle(
                    color: ProfileTheme.ink, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
