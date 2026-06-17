import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/call/models/weekly_call.dart';
import '../../dtos/call_dto.dart';

/// Firestore-backed weekly group-call data source (US-18, US-19).
@injectable
class CallRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CallRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> get _circles =>
      firestore.collection('circles');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _calls(String circleId) =>
      _circles.doc(circleId).collection('calls');

  CollectionReference<Map<String, dynamic>> _attendance(
          String circleId, String callId) =>
      _calls(circleId).doc(callId).collection('attendance');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  // --- US-18 ---

  Future<WeeklyCall> scheduleCall({
    required String circleId,
    required String title,
    required DateTime time,
    required String link,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedLink = link.trim();
    if (trimmedTitle.isEmpty) {
      throw BadRequestException(message: 'عنوان المكالمة مطلوب');
    }
    if (trimmedLink.isEmpty) {
      throw BadRequestException(message: 'رابط المكالمة مطلوب');
    }
    final ref = _calls(circleId).doc();
    final call = WeeklyCall(
      id: ref.id,
      title: trimmedTitle,
      time: time,
      link: trimmedLink,
    );
    await ref.set(WeeklyCallDto.toMap(call));
    return call;
  }

  Future<List<WeeklyCall>> getCalls(String circleId) async {
    final snap =
        await _calls(circleId).orderBy('time', descending: true).get();
    return snap.docs
        .map((d) => WeeklyCallDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  // --- US-19 ---

  Future<void> confirmAttendance({
    required String circleId,
    required String callId,
    required bool present,
  }) async {
    final uid = _uid;
    final name = await _currentUserName();
    await _attendance(circleId, callId).doc(uid).set(CallAttendanceDto.toMap(
          CallAttendance(uid: uid, name: name, present: present),
        ));
  }

  Future<bool> myAttendance({
    required String circleId,
    required String callId,
  }) async {
    final uid = _uid;
    final doc = await _attendance(circleId, callId).doc(uid).get();
    final data = doc.data();
    if (data == null) return false;
    return (data['present'] ?? false) as bool;
  }

  Future<List<CallAttendance>> getAttendance({
    required String circleId,
    required String callId,
  }) async {
    final snap = await _attendance(circleId, callId).get();
    return snap.docs
        .map((d) => CallAttendanceDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  // --- helpers ---

  Future<String> _currentUserName() async {
    final doc = await _users.doc(_uid).get();
    return (doc.data()?['name'] ?? '') as String;
  }
}
