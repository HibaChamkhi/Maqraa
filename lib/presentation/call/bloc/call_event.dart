part of 'call_bloc.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class CallsRequested extends CallEvent {
  final String circleId;

  const CallsRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

class CallScheduled extends CallEvent {
  final String circleId;
  final String title;
  final DateTime time;
  final String link;

  const CallScheduled({
    required this.circleId,
    required this.title,
    required this.time,
    required this.link,
  });

  @override
  List<Object?> get props => [circleId, title, time, link];
}

class CallAttendanceConfirmed extends CallEvent {
  final String circleId;
  final String callId;
  final bool present;

  const CallAttendanceConfirmed({
    required this.circleId,
    required this.callId,
    required this.present,
  });

  @override
  List<Object?> get props => [circleId, callId, present];
}

class CallAttendanceRequested extends CallEvent {
  final String circleId;
  final String callId;

  const CallAttendanceRequested({
    required this.circleId,
    required this.callId,
  });

  @override
  List<Object?> get props => [circleId, callId];
}
