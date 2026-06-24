import 'package:intl/intl.dart';

import '../../domain/circle/models/circle.dart';
import '../../domain/session/models/session.dart';

const _codeToWeekday = {
  'sat': DateTime.saturday,
  'sun': DateTime.sunday,
  'mon': DateTime.monday,
  'tue': DateTime.tuesday,
  'wed': DateTime.wednesday,
  'thu': DateTime.thursday,
  'fri': DateTime.friday,
};

/// One concrete session occurrence on a given date/time.
class SessionOccurrence {
  final DateTime at;
  final SessionStatus? status; // null = generated from the rule, not started
  final String? title;
  const SessionOccurrence(this.at, {this.status, this.title});

  bool get isLive => status == SessionStatus.live;
}

/// Builds the concrete session occurrences for [circle] within [from]..[to]
/// (inclusive) by expanding the fixed weekly rule (`days` + `dayTimes`),
/// applying schedule exceptions (cancelled / moved), and merging in any real
/// session documents (one-off or already materialized). Deduped by calendar
/// day; a real session doc's time/status wins over the generated one.
List<SessionOccurrence> buildSessionOccurrences({
  required Circle circle,
  required DateTime from,
  required DateTime to,
  Map<String, ({String type, String? time})> exceptions = const {},
  List<Session> docs = const [],
}) {
  final byDate = <String, SessionOccurrence>{};

  // Rule occurrences.
  for (var d = DateTime(from.year, from.month, from.day);
      !d.isAfter(to);
      d = d.add(const Duration(days: 1))) {
    for (final entry in circle.dayTimes.entries) {
      if (_codeToWeekday[entry.key] != d.weekday) continue;
      final dateId = DateFormat('yyyy-MM-dd').format(d);
      final e = exceptions[dateId];
      if (e != null && e.type == 'cancelled') continue;
      final timeStr =
          (e != null && e.type == 'moved' && e.time != null) ? e.time! : entry.value;
      final p = timeStr.split(':');
      byDate[dateId] = SessionOccurrence(DateTime(d.year, d.month, d.day,
          int.tryParse(p.first) ?? 6, int.tryParse(p.length > 1 ? p[1] : '0') ?? 0));
    }
  }

  // Real session docs.
  final windowEnd = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
  for (final s in docs) {
    final d = s.scheduledAt;
    if (d.isBefore(DateTime(from.year, from.month, from.day)) ||
        !d.isBefore(windowEnd)) {
      continue;
    }
    final dateId = DateFormat('yyyy-MM-dd').format(d);
    if (exceptions[dateId]?.type == 'cancelled') continue;
    byDate[dateId] = SessionOccurrence(d, status: s.status, title: s.title);
  }

  final list = byDate.values.toList()..sort((a, b) => a.at.compareTo(b.at));
  return list;
}
