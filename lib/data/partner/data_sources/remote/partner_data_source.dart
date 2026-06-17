import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/auth/models/app_user.dart';
import '../../../../domain/circle/models/circle.dart';
import '../../../../domain/partner/models/partner.dart';
import '../../dtos/partner_dto.dart';

/// Firestore-backed recitation-partner data source (US-16, US-17, US-34).
@injectable
class PartnerRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  PartnerRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> get _circles =>
      firestore.collection('circles');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _pairs(String circleId) =>
      _circles.doc(circleId).collection('pairs');

  CollectionReference<Map<String, dynamic>> _members(String circleId) =>
      _circles.doc(circleId).collection('members');

  CollectionReference<Map<String, dynamic>> _appointments(String circleId) =>
      _circles.doc(circleId).collection('appointments');

  /// Daily-call tracking lives under pairs/{pairId}/dailyCalls/{yyyy-MM-dd}.
  CollectionReference<Map<String, dynamic>> _dailyCalls(
          String circleId, String pairId) =>
      _pairs(circleId).doc(pairId).collection('dailyCalls');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  // --- US-16 ---

  Future<Pair> pairMembers({
    required String circleId,
    required CircleMember a,
    required CircleMember b,
  }) async {
    if (a.uid == b.uid) {
      throw BadRequestException(message: 'لا يمكن إقران العضوة بنفسها');
    }
    // Prevent duplicate pairing of either member.
    final existing = await _pairs(circleId).get();
    for (final doc in existing.docs) {
      final p = PairDto.fromMap(doc.id, doc.data());
      final ids = {p.aId, p.bId};
      if (ids.contains(a.uid) || ids.contains(b.uid)) {
        throw BadRequestException(message: 'إحدى العضوتين لديها رفيقة بالفعل');
      }
    }
    final ref = _pairs(circleId).doc();
    final pair = Pair(
      id: ref.id,
      aId: a.uid,
      aName: a.name,
      bId: b.uid,
      bName: b.name,
    );
    await ref.set(PairDto.toMap(pair));
    return pair;
  }

  Future<List<Pair>> autoPairActiveStudents(String circleId) async {
    // Clear existing pairs first to avoid duplicates.
    final existing = await _pairs(circleId).get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    final membersSnap = await _members(circleId)
        .where('status', isEqualTo: MemberStatus.active.name)
        .where('role', isEqualTo: UserRole.student.name)
        .get();
    final students = membersSnap.docs
        .map((d) => CircleMemberFromMap.parse(d.id, d.data()))
        .toList();
    students.shuffle();

    final created = <Pair>[];
    for (var i = 0; i + 1 < students.length; i += 2) {
      final a = students[i];
      final b = students[i + 1];
      final ref = _pairs(circleId).doc();
      final pair = Pair(
        id: ref.id,
        aId: a.uid,
        aName: a.name,
        bId: b.uid,
        bName: b.name,
      );
      await ref.set(PairDto.toMap(pair));
      created.add(pair);
    }
    return created;
  }

  Future<List<Pair>> getPairs(String circleId) async {
    final snap = await _pairs(circleId).get();
    return snap.docs
        .map((d) => PairDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  // --- US-17 ---

  Future<Pair?> getMyPair(String circleId) async {
    final uid = _uid;
    final asA =
        await _pairs(circleId).where('aId', isEqualTo: uid).limit(1).get();
    if (asA.docs.isNotEmpty) {
      return PairDto.fromMap(asA.docs.first.id, asA.docs.first.data());
    }
    final asB =
        await _pairs(circleId).where('bId', isEqualTo: uid).limit(1).get();
    if (asB.docs.isNotEmpty) {
      return PairDto.fromMap(asB.docs.first.id, asB.docs.first.data());
    }
    return null;
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<bool> isDailyCallDone(String circleId) async {
    final pair = await getMyPair(circleId);
    if (pair == null) return false;
    final doc = await _dailyCalls(circleId, pair.id).doc(_todayKey).get();
    final data = doc.data();
    if (data == null) return false;
    return (data['done'] ?? false) as bool;
  }

  Future<bool> setDailyCallDone({
    required String circleId,
    required bool done,
  }) async {
    final pair = await getMyPair(circleId);
    if (pair == null) {
      throw BadRequestException(message: 'لا توجد رفيقة مُسندة إليكِ بعد');
    }
    await _dailyCalls(circleId, pair.id).doc(_todayKey).set({
      'done': done,
      'date': _todayKey,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return done;
  }

  // --- US-34 ---

  Future<Appointment> bookAppointment({
    required String circleId,
    required String toId,
    required String toName,
    required DateTime time,
  }) async {
    final uid = _uid;
    if (time.isBefore(DateTime.now())) {
      throw BadRequestException(message: 'يجب اختيار وقت في المستقبل');
    }
    final ref = _appointments(circleId).doc();
    final appointment = Appointment(
      id: ref.id,
      fromId: uid,
      fromName: await _currentUserName(),
      toId: toId,
      toName: toName,
      time: time,
      confirmed: false,
    );
    await ref.set(AppointmentDto.toMap(appointment));
    return appointment;
  }

  Future<void> confirmAppointment({
    required String circleId,
    required String appointmentId,
  }) async {
    final uid = _uid;
    final doc = await _appointments(circleId).doc(appointmentId).get();
    if (!doc.exists) {
      throw BadRequestException(message: 'الموعد غير موجود');
    }
    final appointment = AppointmentDto.fromMap(doc.id, doc.data()!);
    // Only the invited party (toId) may confirm.
    if (appointment.toId != uid) {
      throw BadRequestException(message: 'لا يمكنكِ تأكيد هذا الموعد');
    }
    await _appointments(circleId).doc(appointmentId).update({'confirmed': true});
  }

  Future<List<Appointment>> getMyAppointments(String circleId) async {
    final uid = _uid;
    final fromSnap =
        await _appointments(circleId).where('fromId', isEqualTo: uid).get();
    final toSnap =
        await _appointments(circleId).where('toId', isEqualTo: uid).get();
    final byId = <String, Appointment>{};
    for (final d in [...fromSnap.docs, ...toSnap.docs]) {
      byId[d.id] = AppointmentDto.fromMap(d.id, d.data());
    }
    final list = byId.values.toList()..sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  // --- helpers ---

  Future<String> _currentUserName() async {
    final doc = await _users.doc(_uid).get();
    return (doc.data()?['name'] ?? '') as String;
  }
}

/// Lightweight parser for member docs (avoids depending on the circle feature's
/// private DTO). circles/{circleId}/members/{uid}: { uid, name, role, status }.
extension CircleMemberFromMap on CircleMember {
  static CircleMember parse(String id, Map<String, dynamic> map) {
    return CircleMember(
      uid: (map['uid'] ?? id) as String,
      name: (map['name'] ?? '') as String,
      role: UserRole.fromName(map['role'] as String?) ?? UserRole.student,
      status: MemberStatus.fromName(map['status'] as String?),
    );
  }
}
