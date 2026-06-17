part of 'partner_bloc.dart';

class PartnerState extends Equatable {
  final UIStatus status;
  final String message;

  /// All pairs of the circle (US-16, teacher view).
  final List<Pair> pairs;

  /// The current user's pair (US-17), or null.
  final Pair? myPair;

  /// Whether today's daily call is marked done (US-17).
  final bool dailyCallDone;

  /// Appointments involving the current user (US-34).
  final List<Appointment> appointments;

  /// Set true after a pairing / booking action (navigation/feedback hook).
  final bool actionDone;

  const PartnerState({
    this.status = UIStatus.loading,
    this.message = '',
    this.pairs = const [],
    this.myPair,
    this.dailyCallDone = false,
    this.appointments = const [],
    this.actionDone = false,
  });

  PartnerState copyWith({
    UIStatus? status,
    String? message,
    List<Pair>? pairs,
    Pair? myPair,
    bool clearMyPair = false,
    bool? dailyCallDone,
    List<Appointment>? appointments,
    bool? actionDone,
  }) {
    return PartnerState(
      status: status ?? this.status,
      message: message ?? this.message,
      pairs: pairs ?? this.pairs,
      myPair: clearMyPair ? null : (myPair ?? this.myPair),
      dailyCallDone: dailyCallDone ?? this.dailyCallDone,
      appointments: appointments ?? this.appointments,
      actionDone: actionDone ?? this.actionDone,
    );
  }

  @override
  List<Object?> get props => [
        status,
        message,
        pairs,
        myPair,
        dailyCallDone,
        appointments,
        actionDone,
      ];
}
