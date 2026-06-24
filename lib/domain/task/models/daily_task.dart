/// Status of a daily memorization task.
enum TaskStatus {
  pending, // لم يُسلَّم بعد / بانتظار التأكيد
  done; // تم بعد تأكيد الرفيقة

  String get arabicLabel => this == TaskStatus.done ? 'مُنجز' : 'قيد الإنجاز';

  static TaskStatus fromName(String? value) {
    return value == 'done' ? TaskStatus.done : TaskStatus.pending;
  }

  String get name => this == TaskStatus.done ? 'done' : 'pending';
}

/// A student's daily homework (US-08/09/10).
///
/// Stored at `circles/{circleId}/tasks/{yyyy-MM-dd}/students/{uid}`.
/// Becomes [TaskStatus.done] only after the partner confirms ([partnerConfirmed]).
class DailyTask {
  final String uid;
  final String name;
  final String range;
  final TaskStatus status;

  /// True once the recitation partner confirmed it.
  final bool partnerConfirmed;

  /// uid of the partner asked to confirm (null = no confirmation requested yet).
  final String? partnerId;
  final String? note;

  /// The day this task belongs to (yyyy-MM-dd document id).
  final String dateId;

  const DailyTask({
    required this.uid,
    required this.name,
    required this.range,
    this.status = TaskStatus.pending,
    this.partnerConfirmed = false,
    this.partnerId,
    this.note,
    this.dateId = '',
  });

  /// A confirmation has been requested but not yet granted.
  bool get awaitingConfirmation =>
      partnerId != null && partnerId!.isNotEmpty && !partnerConfirmed;

  DailyTask copyWith({
    String? uid,
    String? name,
    String? range,
    TaskStatus? status,
    bool? partnerConfirmed,
    String? partnerId,
    String? note,
    String? dateId,
  }) {
    return DailyTask(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      range: range ?? this.range,
      status: status ?? this.status,
      partnerConfirmed: partnerConfirmed ?? this.partnerConfirmed,
      partnerId: partnerId ?? this.partnerId,
      note: note ?? this.note,
      dateId: dateId ?? this.dateId,
    );
  }
}
