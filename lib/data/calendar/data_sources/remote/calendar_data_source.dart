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
    String link = '',
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
      status: SessionStatus.scheduled,
      link: link.trim(),
      createdBy: uid,
    );
    await docRef.set(SessionDto.toMap(session));
    return session;
  }

  Future<Session> updateSession({
    required String circleId,
    required String sessionId,
    required String title,
    required DateTime scheduledAt,
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
      'link': link.trim(),
    });
    final existing = SessionDto.fromMap(doc.id, doc.data()!);
    return existing.copyWith(
      title: trimmed,
      scheduledAt: scheduledAt,
      link: link.trim(),
    );
  }

  Future<void> deleteSession({
    required String circleId,
    required String sessionId,
  }) async {
    await _sessions(circleId).doc(sessionId).delete();
  }
}
