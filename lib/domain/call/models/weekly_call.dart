/// A weekly group call «مكالمة جماعية» under
/// circles/{circleId}/calls/{callId}: { title, time (Timestamp), link }.
class WeeklyCall {
  final String id;
  final String title;
  final DateTime time;
  final String link;

  const WeeklyCall({
    required this.id,
    required this.title,
    required this.time,
    required this.link,
  });

  WeeklyCall copyWith({
    String? title,
    DateTime? time,
    String? link,
  }) {
    return WeeklyCall(
      id: id,
      title: title ?? this.title,
      time: time ?? this.time,
      link: link ?? this.link,
    );
  }
}

/// Attendance under circles/{circleId}/calls/{callId}/attendance/{uid}:
/// { uid, name, present (bool) }.
class CallAttendance {
  final String uid;
  final String name;
  final bool present;

  const CallAttendance({
    required this.uid,
    required this.name,
    required this.present,
  });

  CallAttendance copyWith({
    String? name,
    bool? present,
  }) {
    return CallAttendance(
      uid: uid,
      name: name ?? this.name,
      present: present ?? this.present,
    );
  }
}
