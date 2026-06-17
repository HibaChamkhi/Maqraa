part of 'partner_bloc.dart';

abstract class PartnerEvent extends Equatable {
  const PartnerEvent();

  @override
  List<Object?> get props => [];
}

class PartnerPairsRequested extends PartnerEvent {
  final String circleId;

  const PartnerPairsRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

class PartnerManualPairRequested extends PartnerEvent {
  final String circleId;
  final CircleMember a;
  final CircleMember b;

  const PartnerManualPairRequested({
    required this.circleId,
    required this.a,
    required this.b,
  });

  @override
  List<Object?> get props => [circleId, a.uid, b.uid];
}

class PartnerAutoPairRequested extends PartnerEvent {
  final String circleId;

  const PartnerAutoPairRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

class PartnerMyPairRequested extends PartnerEvent {
  final String circleId;

  const PartnerMyPairRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

class PartnerDailyCallToggled extends PartnerEvent {
  final String circleId;
  final bool done;

  const PartnerDailyCallToggled({required this.circleId, required this.done});

  @override
  List<Object?> get props => [circleId, done];
}

class PartnerAppointmentsRequested extends PartnerEvent {
  final String circleId;

  const PartnerAppointmentsRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

class PartnerAppointmentBooked extends PartnerEvent {
  final String circleId;
  final String toId;
  final String toName;
  final DateTime time;

  const PartnerAppointmentBooked({
    required this.circleId,
    required this.toId,
    required this.toName,
    required this.time,
  });

  @override
  List<Object?> get props => [circleId, toId, toName, time];
}

class PartnerAppointmentConfirmed extends PartnerEvent {
  final String circleId;
  final String appointmentId;

  const PartnerAppointmentConfirmed({
    required this.circleId,
    required this.appointmentId,
  });

  @override
  List<Object?> get props => [circleId, appointmentId];
}
