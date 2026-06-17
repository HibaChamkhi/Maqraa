import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/session/models/session.dart';
import '../../dtos/session_dto.dart';

/// Firestore-backed live-session & attendance data source (US-32/33/42).
@injectable
class SessionRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  SessionRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> _sessions(String circleId) =>
      firestore.collection('circles').doc(circleId).collection('sessions');

  CollectionReference<Map<String, dynamic>> _attendance(
    String circleId,
    String sessionId,
  ) =>
      _sessions(circleId).doc(sessionId).collection('attendance');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  Future<String> _currentUserName() async {
    final doc = await _users.doc(_uid).get();
    return (doc.data()?['name'] ?? '') as String;
  }

  // --- shared reads ---

  Future<Session?> getActiveSession(String circleId) async {
    final query = await _sessions(circleId)
        .where('status', isEqualTo: SessionStatus.live.name)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return SessionDto.fromMap(doc.id, doc.data());
  }

  Future<List<Session>> getSessions(String circleId) async {
    final query =
        await _sessions(circleId).orderBy('scheduledAt').get();
    return query.docs
        .map((d) => SessionDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  Future<Session> _getSession(String circleId, String sessionId) async {
    final doc = await _sessions(circleId).doc(sessionId).get();
    if (!doc.exists) {
      throw BadRequestException(message: 'الجلسة غير موجودة');
    }
    return SessionDto.fromMap(doc.id, doc.data()!);
  }

  // --- US-32 ---

  Future<Session> startSession({
    required String circleId,
    required String sessionId,
  }) async {
    final session = await _getSession(circleId, sessionId);
    if (session.status == SessionStatus.ended) {
      throw BadRequestException(message: 'انتهت هذه الجلسة بالفعل');
    }
    if (session.status == SessionStatus.live) {
      throw BadRequestException(message: 'الجلسة مباشرة بالفعل');
    }
    await _sessions(circleId)
        .doc(sessionId)
        .update({'status': SessionStatus.live.name});
    return session.copyWith(status: SessionStatus.live);
  }

  Future<Session> endSession({
    required String circleId,
    required String sessionId,
  }) async {
    final session = await _getSession(circleId, sessionId);
    if (session.status != SessionStatus.live) {
      throw BadRequestException(message: 'لا يمكن إنهاء جلسة غير مباشرة');
    }
    await _sessions(circleId)
        .doc(sessionId)
        .update({'status': SessionStatus.ended.name});
    return session.copyWith(status: SessionStatus.ended);
  }

  // --- US-33 ---

  Future<Session> joinSession({
    required String circleId,
    required String sessionId,
  }) async {
    final uid = _uid;
    final session = await _getSession(circleId, sessionId);
    if (session.status != SessionStatus.live) {
      throw BadRequestException(message: 'لا توجد جلسة مباشرة للانضمام إليها');
    }
    await _attendance(circleId, sessionId).doc(uid).set(
          AttendanceDto.toMap(
            Attendance(
              uid: uid,
              name: await _currentUserName(),
              present: true,
            ),
          ),
        );
    return session;
  }

  // --- US-42 ---

  Future<List<Attendance>> getAttendance({
    required String circleId,
    required String sessionId,
  }) async {
    final query = await _attendance(circleId, sessionId)
        .where('present', isEqualTo: true)
        .get();
    return query.docs
        .map((d) => AttendanceDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }
}
