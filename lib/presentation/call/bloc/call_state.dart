part of 'call_bloc.dart';

class CallState extends Equatable {
  final UIStatus status;
  final String message;

  /// Scheduled calls, newest first (US-18).
  final List<WeeklyCall> calls;

  /// Whether the current user is marked present for the latest call (US-19).
  final bool myAttendance;

  /// Attendance list of the inspected call (teacher view, US-19).
  final List<CallAttendance> attendance;

  /// Set true after scheduling a call (navigation/feedback hook).
  final bool actionDone;

  const CallState({
    this.status = UIStatus.loading,
    this.message = '',
    this.calls = const [],
    this.myAttendance = false,
    this.attendance = const [],
    this.actionDone = false,
  });

  CallState copyWith({
    UIStatus? status,
    String? message,
    List<WeeklyCall>? calls,
    bool? myAttendance,
    List<CallAttendance>? attendance,
    bool? actionDone,
  }) {
    return CallState(
      status: status ?? this.status,
      message: message ?? this.message,
      calls: calls ?? this.calls,
      myAttendance: myAttendance ?? this.myAttendance,
      attendance: attendance ?? this.attendance,
      actionDone: actionDone ?? this.actionDone,
    );
  }

  @override
  List<Object?> get props => [
        status,
        message,
        calls,
        myAttendance,
        attendance,
        actionDone,
      ];
}
