import '../models/weekly_call.dart';

/// Weekly group-call contract (US-18, US-19).
abstract class CallRepository {
  /// US-18: teacher schedules the weekly call.
  Future<WeeklyCall> scheduleCall({
    required String circleId,
    required String title,
    required DateTime time,
    required String link,
  });

  /// Calls of a circle, newest first.
  Future<List<WeeklyCall>> getCalls(String circleId);

  /// US-19: student confirms attendance (present true/false).
  Future<void> confirmAttendance({
    required String circleId,
    required String callId,
    required bool present,
  });

  /// US-19: whether the current user already confirmed attendance.
  Future<bool> myAttendance({
    required String circleId,
    required String callId,
  });

  /// US-19: teacher views the attendance list of a call.
  Future<List<CallAttendance>> getAttendance({
    required String circleId,
    required String callId,
  });
}
