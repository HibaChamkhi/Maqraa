// Live-session domain models (US-30/31/32/33/42).
// Backed by `circles/{circleId}/sessions/{sessionId}` in Firestore.

/// Lifecycle of a session.
/// - scheduled: created with a future date/time, not started yet.
/// - live: currently running — students can join and attendance is recorded.
/// - ended: finished.
enum SessionStatus {
  scheduled, // مجدولة
  live, // مباشرة
  ended; // منتهية

  String get arabicLabel {
    switch (this) {
      case SessionStatus.scheduled:
        return 'مجدولة';
      case SessionStatus.live:
        return 'مباشرة';
      case SessionStatus.ended:
        return 'منتهية';
    }
  }

  static SessionStatus fromName(String? value) {
    return SessionStatus.values.where((s) => s.name == value).firstOrNull ??
        SessionStatus.scheduled;
  }
}

/// Kind of session activity.
enum SessionType {
  tasmi3, // تسميع
  imla2; // إملاء

  String get arabicLabel => this == SessionType.imla2 ? 'إملاء' : 'تسميع';

  static SessionType fromName(String? value) =>
      value == 'imla2' ? SessionType.imla2 : SessionType.tasmi3;
}

/// A session document under circles/{circleId}/sessions/{sessionId}.
class Session {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final int durationMinutes;
  final SessionType type;
  final SessionStatus status;
  final String link;
  final String createdBy;

  /// Non-null when this session was generated as part of a weekly series —
  /// lets us delete the whole series together.
  final String? recurrenceId;

  const Session({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.type = SessionType.tasmi3,
    this.status = SessionStatus.scheduled,
    this.link = '',
    this.createdBy = '',
    this.recurrenceId,
  });

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));
  bool get isRecurring => recurrenceId != null && recurrenceId!.isNotEmpty;

  Session copyWith({
    String? title,
    DateTime? scheduledAt,
    int? durationMinutes,
    SessionType? type,
    SessionStatus? status,
    String? link,
    String? createdBy,
    String? recurrenceId,
  }) {
    return Session(
      id: id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      status: status ?? this.status,
      link: link ?? this.link,
      createdBy: createdBy ?? this.createdBy,
      recurrenceId: recurrenceId ?? this.recurrenceId,
    );
  }
}

/// An attendance record under
/// circles/{circleId}/sessions/{sessionId}/attendance/{uid}.
class Attendance {
  final String uid;
  final String name;
  final bool present;
  final DateTime? at;

  const Attendance({
    required this.uid,
    required this.name,
    this.present = true,
    this.at,
  });

  Attendance copyWith({
    String? name,
    bool? present,
    DateTime? at,
  }) {
    return Attendance(
      uid: uid,
      name: name ?? this.name,
      present: present ?? this.present,
      at: at ?? this.at,
    );
  }
}
