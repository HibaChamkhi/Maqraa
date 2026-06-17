import '../../../domain/task/models/daily_task.dart';

/// Maps `circles/{circleId}/tasks/{dateId}/students/{uid}` <-> [DailyTask].
class DailyTaskDto {
  static DailyTask fromMap(String dateId, Map<String, dynamic> map) {
    return DailyTask(
      uid: (map['uid'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      range: (map['range'] ?? '') as String,
      status: TaskStatus.fromName(map['status'] as String?),
      partnerConfirmed: (map['partnerConfirmed'] ?? false) as bool,
      partnerId: map['partnerId'] as String?,
      note: map['note'] as String?,
      dateId: dateId,
    );
  }

  static Map<String, dynamic> toMap(DailyTask task) {
    return {
      'uid': task.uid,
      'name': task.name,
      'range': task.range,
      'status': task.status.name,
      'partnerConfirmed': task.partnerConfirmed,
      'partnerId': task.partnerId,
      'note': task.note,
    };
  }
}
