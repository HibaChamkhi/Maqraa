import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/session/models/session.dart';
import '../bloc/calendar_bloc.dart';

/// US-31: student views upcoming sessions in a read-only calendar that marks
/// the days that have sessions.
class StudentCalendarPage extends StatelessWidget {
  final String circleId;
  final AppUser user;

  const StudentCalendarPage({
    super.key,
    required this.circleId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CalendarBloc>()..add(CalendarSessionsRequested(circleId)),
      child: const _StudentCalendarView(),
    );
  }
}

class _StudentCalendarView extends StatefulWidget {
  const _StudentCalendarView();

  @override
  State<_StudentCalendarView> createState() => _StudentCalendarViewState();
}

class _StudentCalendarViewState extends State<_StudentCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Session> _sessionsOn(List<Session> all, DateTime day) =>
      all.where((s) => _isSameDay(s.scheduledAt, day)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('تقويم الجلسات')),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state.status == UIStatus.loading && state.sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == UIStatus.error) {
            return Center(
              child: Text(state.message, style: theme.textTheme.bodyMedium),
            );
          }
          final daySessions = _sessionsOn(state.sessions, _selectedDay);
          return Column(
            children: [
              Card(
                child: TableCalendar<Session>(
                  locale: 'ar',
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => _isSameDay(d, _selectedDay),
                  eventLoader: (d) => _sessionsOn(state.sessions, d),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: daySessions.isEmpty
                    ? Center(
                        child: Text('لا توجد جلسات في هذا اليوم',
                            style: theme.textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: daySessions.length,
                        itemBuilder: (context, i) {
                          final s = daySessions[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.event_outlined),
                              title: Text(s.title),
                              subtitle: Text(
                                  '${timeFormat.format(s.scheduledAt)} • ${s.status.arabicLabel}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
