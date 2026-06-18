import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/session/models/session.dart';

/// Maps `circles/{circleId}/sessions/{sessionId}` <-> [Session].
class SessionDto {
  static Session fromMap(String id, Map<String, dynamic> map) {
    return Session(
      id: id,
      title: (map['title'] ?? '') as String,
      scheduledAt:
          (map['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      type: SessionType.fromName(map['type'] as String?),
      status: SessionStatus.fromName(map['status'] as String?),
      link: (map['link'] ?? '') as String,
      createdBy: (map['createdBy'] ?? '') as String,
      recurrenceId: map['recurrenceId'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Session session) {
    return {
      'title': session.title,
      'scheduledAt': Timestamp.fromDate(session.scheduledAt),
      'durationMinutes': session.durationMinutes,
      'type': session.type.name,
      'status': session.status.name,
      'link': session.link,
      'createdBy': session.createdBy,
      'recurrenceId': session.recurrenceId,
    };
  }
}

/// Maps `circles/{circleId}/sessions/{sessionId}/attendance/{uid}`
/// <-> [Attendance].
class AttendanceDto {
  static Attendance fromMap(String uid, Map<String, dynamic> map) {
    return Attendance(
      uid: uid,
      name: (map['name'] ?? '') as String,
      present: (map['present'] ?? false) as bool,
      at: (map['at'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(Attendance attendance) {
    return {
      'uid': attendance.uid,
      'name': attendance.name,
      'present': attendance.present,
      'at': attendance.at != null
          ? Timestamp.fromDate(attendance.at!)
          : FieldValue.serverTimestamp(),
    };
  }
}
