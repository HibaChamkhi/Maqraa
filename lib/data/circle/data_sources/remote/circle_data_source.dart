import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/auth/models/app_user.dart';
import '../../../../domain/circle/models/circle.dart';
import '../../dtos/circle_dto.dart';

/// Firestore-backed circle management data source.
@injectable
class CircleRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CircleRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> get _circles =>
      firestore.collection('circles');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _members(String circleId) =>
      _circles.doc(circleId).collection('members');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  // --- US-03 ---

  Future<Circle> createCircle({
    required String name,
    required Privacy privacy,
  }) async {
    final uid = _uid;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw BadRequestException(message: 'اسم الحلقة مطلوب');
    }

    // Pull the teacher's profile for gender + display name.
    final profileDoc = await _users.doc(uid).get();
    final profile = profileDoc.data();
    final gender = Gender.fromName(profile?['gender'] as String?);
    if (gender == null) {
      throw BadRequestException(message: 'يلزم تحديد الجنس في الملف الشخصي أولاً');
    }
    final teacherName = (profile?['name'] ?? '') as String;

    final inviteCode = _generateInviteCode();
    final docRef = _circles.doc();
    final circle = Circle(
      id: docRef.id,
      name: trimmed,
      teacherId: uid,
      gender: gender,
      privacy: privacy,
      inviteCode: inviteCode,
      supervisorIds: const [],
    );

    await docRef.set(CircleDto.toMap(circle));
    // Add the teacher as an active member.
    await _members(docRef.id).doc(uid).set(CircleMemberDto.toMap(
          CircleMember(
            uid: uid,
            name: teacherName,
            role: UserRole.teacher,
            status: MemberStatus.active,
          ),
        ));
    // Track membership on the user doc so getMyCircles needs no index.
    await _users.doc(uid).set(
      {'circleIds': FieldValue.arrayUnion([docRef.id])},
      SetOptions(merge: true),
    );

    return circle;
  }

  // --- US-04 / US-29 ---

  Future<Circle> joinByInviteCode(String inviteCode) async {
    final uid = _uid;
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw BadRequestException(message: 'رمز الدعوة مطلوب');
    }

    final query =
        await _circles.where('inviteCode', isEqualTo: code).limit(1).get();
    if (query.docs.isEmpty) {
      throw BadRequestException(message: 'رمز الدعوة غير صحيح');
    }
    final doc = query.docs.first;
    final circle = CircleDto.fromMap(doc.id, doc.data());

    final existing = await _members(circle.id).doc(uid).get();
    if (existing.exists) {
      throw BadRequestException(message: 'أنتِ عضوة في هذه الحلقة بالفعل');
    }

    await _members(circle.id).doc(uid).set(CircleMemberDto.toMap(
          CircleMember(
            uid: uid,
            name: await _currentUserName(),
            role: UserRole.student,
            status: MemberStatus.active,
          ),
        ));
    await _users.doc(uid).set(
      {'circleIds': FieldValue.arrayUnion([circle.id])},
      SetOptions(merge: true),
    );
    return circle;
  }

  // --- US-39 ---

  Future<void> requestToJoin(String circleId) async {
    final uid = _uid;
    final existing = await _members(circleId).doc(uid).get();
    if (existing.exists) {
      throw BadRequestException(message: 'لديكِ طلب أو عضوية في هذه الحلقة بالفعل');
    }
    await _members(circleId).doc(uid).set(CircleMemberDto.toMap(
          CircleMember(
            uid: uid,
            name: await _currentUserName(),
            role: UserRole.student,
            status: MemberStatus.pending,
          ),
        ));
  }

  Future<List<Circle>> discoverPublicCircles() async {
    final uid = _uid;
    final profileDoc = await _users.doc(uid).get();
    final gender = Gender.fromName(profileDoc.data()?['gender'] as String?);
    if (gender == null) {
      throw BadRequestException(message: 'يلزم تحديد الجنس في الملف الشخصي أولاً');
    }
    final query = await _circles
        .where('privacy', isEqualTo: Privacy.public.name)
        .where('gender', isEqualTo: gender.name)
        .get();
    return query.docs
        .map((d) => CircleDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  // --- US-05 ---

  Future<List<CircleMember>> getMembers(String circleId) async {
    final query = await _members(circleId).get();
    return query.docs
        .map((d) => CircleMemberDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  // --- US-41 ---

  Future<List<CircleMember>> getPendingRequests(String circleId) async {
    final query = await _members(circleId)
        .where('status', isEqualTo: MemberStatus.pending.name)
        .get();
    return query.docs
        .map((d) => CircleMemberDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  Future<void> acceptRequest({
    required String circleId,
    required String uid,
  }) async {
    await _members(circleId).doc(uid).update({
      'status': MemberStatus.active.name,
    });
  }

  Future<void> rejectRequest({
    required String circleId,
    required String uid,
  }) async {
    await _members(circleId).doc(uid).delete();
  }

  // --- US-40 ---

  Future<void> promoteToSupervisor({
    required String circleId,
    required String uid,
  }) async {
    await _circles.doc(circleId).update({
      'supervisorIds': FieldValue.arrayUnion([uid]),
    });
    await _members(circleId).doc(uid).update({
      'role': UserRole.supervisor.name,
    });
  }

  // --- US-38 ---

  Future<void> updatePrivacy({
    required String circleId,
    required Privacy privacy,
  }) async {
    await _circles.doc(circleId).update({'privacy': privacy.name});
  }

  // --- shared ---

  Future<Circle> getCircle(String circleId) async {
    final doc = await _circles.doc(circleId).get();
    if (!doc.exists) {
      throw BadRequestException(message: 'الحلقة غير موجودة');
    }
    return CircleDto.fromMap(doc.id, doc.data()!);
  }

  Future<List<Circle>> getMyCircles() async {
    final uid = _uid;
    // Read the circle ids cached on the user doc, then fetch each circle by id.
    // Plain document reads — no collection-group query, so no index needed.
    final userDoc = await _users.doc(uid).get();
    final ids = ((userDoc.data()?['circleIds'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final circles = <Circle>[];
    for (final id in ids) {
      final circleDoc = await _circles.doc(id).get();
      if (circleDoc.exists) {
        circles.add(CircleDto.fromMap(circleDoc.id, circleDoc.data()!));
      }
    }
    return circles;
  }

  // --- helpers ---

  Future<String> _currentUserName() async {
    final doc = await _users.doc(_uid).get();
    return (doc.data()?['name'] ?? '') as String;
  }

  /// Generates a random 6-char invite code. A no-query approach (6 chars from a
  /// 31-char alphabet ≈ 887M combinations) keeps circle creation to plain doc
  /// writes — avoiding a collection query that hangs on Flutter web.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
