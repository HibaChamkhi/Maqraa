import '../../circle/models/circle.dart';
import '../models/partner.dart';

/// Partner («الرفيقة») contract: pairing, daily-call organizer, appointments.
abstract class PartnerRepository {
  /// US-16: manually pair two members as recitation partners.
  Future<Pair> pairMembers({
    required String circleId,
    required CircleMember a,
    required CircleMember b,
  });

  /// US-16: auto-pair all active students two-by-two. Returns created pairs.
  Future<List<Pair>> autoPairActiveStudents(String circleId);

  /// All pairs of a circle.
  Future<List<Pair>> getPairs(String circleId);

  /// US-17: the pair the current user belongs to (or null).
  Future<Pair?> getMyPair(String circleId);

  /// US-17: whether the current user marked today's daily call as done.
  Future<bool> isDailyCallDone(String circleId);

  /// US-17: toggle today's daily-call status for the current user.
  Future<bool> setDailyCallDone({
    required String circleId,
    required bool done,
  });

  /// US-34: book a recitation appointment with the partner.
  Future<Appointment> bookAppointment({
    required String circleId,
    required String toId,
    required String toName,
    required DateTime time,
  });

  /// US-34: the other party confirms an appointment.
  Future<void> confirmAppointment({
    required String circleId,
    required String appointmentId,
  });

  /// US-34: appointments involving the current user (pending + confirmed).
  Future<List<Appointment>> getMyAppointments(String circleId);
}
