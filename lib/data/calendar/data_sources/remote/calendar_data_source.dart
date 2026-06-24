import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/session/models/session.dart';
import '../../../session/dtos/session_dto.dart';

/// Firestore-backed sessions-calendar data source (US-30/31).
/// Reuses the `circles/{circleId}/sessions` collection.
@injectable
class CalendarRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CalendarRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> _sessions(String circleId) =>
      firestore.collection('circles').doc(circleId).collection('sessions');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  // --- US-31 (read) ---

  Future<List<Session>> getSessions(String circleId) async {
    final query = await _sessions(circleId).orderBy('scheduledAt').get();
    return query.docs
        .map((d) => SessionDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  // --- US-30 ---

  Future<Session> addSession({
    required String circleId,
    required String title,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    SessionType type = SessionType.tasmi3,
    String link = '',
    String? recurrenceId,
  }) async {
    final uid = _uid;
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw BadRequestException(message: 'عنوان الجلسة مطلوب');
    }
    final docRef = _sessions(circleId).doc();
    final session = Session(
      id: docRef.id,
      title: trimmed,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      type: type,
      status: SessionStatus.scheduled,
      link: link.trim(),
      createdBy: uid,
      recurrenceId: recurrenceId,
    );
    await docRef.set(SessionDto.toMap(session));
    return session;
  }

  /// Generate one session document per [occurrences] entry, all sharing a
  /// recurrenceId so the whole series can be removed together.
  Future<void> addRecurringSessions({
    required String circleId,
    required String title,
    required SessionType type,
    required int durationMinutes,
    required List<DateTime> occurrences,
    String link = '',
  }) async {
    final uid = _uid;
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw BadRequestException(message: 'عنوان الجلسة مطلوب');
    }
    if (occurrences.isEmpty) {
      throw BadRequestException(message: 'اختاري يومًا واحدًا على الأقل');
    }
    final recurrenceId = _sessions(circleId).doc().id;
    final batch = firestore.batch();
    for (final at in occurrences) {
      final ref = _sessions(circleId).doc();
      batch.set(
        ref,
        SessionDto.toMap(Session(
          id: ref.id,
          title: trimmed,
          scheduledAt: at,
          durationMinutes: durationMinutes,
          type: type,
          status: SessionStatus.scheduled,
          link: link.trim(),
          createdBy: uid,
          recurrenceId: recurrenceId,
        )),
      );
    }
    await batch.commit();
  }

  Future<Session> updateSession({
    required String circleId,
    required String sessionId,
    required String title,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    SessionType type = SessionType.tasmi3,
    String link = '',
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw BadRequestException(message: 'عنوان الجلسة مطلوب');
    }
    final doc = await _sessions(circleId).doc(sessionId).get();
    if (!doc.exists) {
      throw BadRequestException(message: 'الجلسة غير موجودة');
    }
    await _sessions(circleId).doc(sessionId).update({
      'title': trimmed,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': durationMinutes,
      'type': type.name,
      'link': link.trim(),
    });
    final existing = SessionDto.fromMap(doc.id, doc.data()!);
    return existing.copyWith(
      title: trimmed,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      type: type,
      link: link.trim(),
    );
  }

  Future<void> deleteSession({
    required String circleId,
    required String sessionId,
  }) async {
    await _sessions(circleId).doc(sessionId).delete();
  }

  /// Delete every session that belongs to a recurring series.
  Future<void> deleteSeries({
    required String circleId,
    required String recurrenceId,
  }) async {
    final q = await _sessions(circleId)
        .where('recurrenceId', isEqualTo: recurrenceId)
        .get();
    final batch = firestore.batch();
    for (final d in q.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
