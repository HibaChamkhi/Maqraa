import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/call/models/weekly_call.dart';

/// Maps circles/{circleId}/calls/{callId} <-> [WeeklyCall].
class WeeklyCallDto {
  static WeeklyCall fromMap(String id, Map<String, dynamic> map) {
    return WeeklyCall(
      id: id,
      title: (map['title'] ?? '') as String,
      time: (map['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      link: (map['link'] ?? '') as String,
    );
  }

  static Map<String, dynamic> toMap(WeeklyCall call) {
    return {
      'title': call.title,
      'time': Timestamp.fromDate(call.time),
      'link': call.link,
    };
  }
}

/// Maps circles/{circleId}/calls/{callId}/attendance/{uid} <-> [CallAttendance].
class CallAttendanceDto {
  static CallAttendance fromMap(String id, Map<String, dynamic> map) {
    return CallAttendance(
      uid: (map['uid'] ?? id) as String,
      name: (map['name'] ?? '') as String,
      present: (map['present'] ?? false) as bool,
    );
  }

  static Map<String, dynamic> toMap(CallAttendance a) {
    return {
      'uid': a.uid,
      'name': a.name,
      'present': a.present,
    };
  }
}
