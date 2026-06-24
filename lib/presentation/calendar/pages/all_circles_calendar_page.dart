import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/di/injection.dart';
import '../../../core/ui/styles/theme.dart';
import '../../../core/util/session_occurrences.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../../profile/pages/web_shell.dart';

/// A read-only calendar that merges the sessions of ALL the student's حلقات —
/// expanded from each حلقة's fixed rule (+ exceptions) and any real session
/// docs — each occurrence tagged with its حلقة name.
class AllCirclesCalendarPage extends StatefulWidget {
  final AppUser user;
  const AllCirclesCalendarPage({super.key, required this.user});

  @override
  State<AllCirclesCalendarPage> createState() => _AllCirclesCalendarPageState();
}

class _CalItem {
  final SessionOccurrence occ;
  final String circleName;
  const _CalItem(this.occ, this.circleName);
}

class _AllCirclesCalendarPageState extends State<AllCirclesCalendarPage> {
  late Future<List<_CalItem>> _future = _load();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Future<List<_CalItem>> _load() async {
    final out = <_CalItem>[];
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 60));
    final to = now.add(const Duration(days: 120));
    try {
      final circles = await getIt<CircleRepository>().getMyCircles();
      for (final c in circles) {
        Map<String, ({String type, String? time})> exc = const {};
        try {
          exc = await getIt<CircleRepository>().getScheduleExceptions(c.id);
        } catch (_) {}
        List<Session> docs = const [];
        try {
          docs = await getIt<SessionRepository>().getSessions(c.id);
        } catch (_) {}
        final occ = buildSessionOccurrences(
          circle: c,
          from: from,
          to: to,
          exceptions: exc,
          docs: docs,
        );
        for (final o in occ) {
          out.add(_CalItem(o, c.name));
        }
      }
    } catch (_) {/* circles optional */}
    return out;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<_CalItem> _on(List<_CalItem> all, DateTime day) =>
      all.where((e) => _sameDay(e.occ.at, day)).toList()
        ..sort((a, b) => a.occ.at.compareTo(b.occ.at));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeF = DateFormat('h:mm a', 'ar');
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
          automaticallyImplyLeading: !ShellScope.of(context),
          title: const Text('تقويم جلساتي')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<_CalItem>>(
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
                  child: TableCalendar<_CalItem>(
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
                            e.occ.isLive
                                ? Icons.podcasts_rounded
                                : Icons.event_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                            e.occ.title != null &&
                                    e.occ.title!.trim().isNotEmpty
                                ? '${e.occ.title!.trim()} — حلقة ${e.circleName}'
                                : 'حلقة ${e.circleName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(
                            '${timeF.format(e.occ.at)}${e.occ.isLive ? ' • مباشرة الآن' : ''}'),
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
