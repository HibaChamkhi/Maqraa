import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';

/// A read-only calendar that merges the sessions of ALL the student's حلقات,
/// each session tagged with its حلقة name.
class AllCirclesCalendarPage extends StatefulWidget {
  final AppUser user;
  const AllCirclesCalendarPage({super.key, required this.user});

  @override
  State<AllCirclesCalendarPage> createState() => _AllCirclesCalendarPageState();
}

class _CalSession {
  final Session session;
  final String circleName;
  const _CalSession(this.session, this.circleName);
}

class _AllCirclesCalendarPageState extends State<AllCirclesCalendarPage> {
  late Future<List<_CalSession>> _future = _load();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Future<List<_CalSession>> _load() async {
    final circles = await getIt<CircleRepository>().getMyCircles();
    final out = <_CalSession>[];
    for (final c in circles) {
      try {
        final ss = await getIt<SessionRepository>().getSessions(c.id);
        for (final s in ss) {
          out.add(_CalSession(s, c.name));
        }
      } catch (_) {/* skip this circle */}
    }
    return out;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<_CalSession> _on(List<_CalSession> all, DateTime day) =>
      all.where((e) => _sameDay(e.session.scheduledAt, day)).toList()
        ..sort((a, b) =>
            a.session.scheduledAt.compareTo(b.session.scheduledAt));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeF = DateFormat('h:mm a', 'ar');
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(title: const Text('تقويم جلساتي')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<_CalSession>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snap.data!;
            final day = _on(all, _selectedDay);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: [
                Card(
                  child: TableCalendar<_CalSession>(
                    locale: 'ar',
                    firstDay: DateTime.utc(2020),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => _sameDay(d, _selectedDay),
                    eventLoader: (d) => _on(all, d),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
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
                const SizedBox(height: AppSpacing.sm),
                if (day.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text('لا توجد جلسات في هذا اليوم',
                          style: theme.textTheme.bodyMedium),
                    ),
                  )
                else
                  for (final e in day)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.sky,
                          child: Icon(
                            e.session.status == SessionStatus.live
                                ? Icons.podcasts_rounded
                                : Icons.event_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                            e.session.title.trim().isNotEmpty
                                ? '${e.session.title.trim()} — حلقة ${e.circleName}'
                                : 'حلقة ${e.circleName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(
                            '${timeF.format(e.session.scheduledAt)} • ${e.session.status.arabicLabel}'),
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
