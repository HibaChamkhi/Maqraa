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
      teacherName: teacherName,
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

    // Gender separation (US-43): the joining account must match the circle.
    final profileDoc = await _users.doc(uid).get();
    final userGender = Gender.fromName(profileDoc.data()?['gender'] as String?);
    if (userGender != null && userGender != circle.gender) {
      throw BadRequestException(
          message: circle.gender == Gender.female
              ? 'هذه الحلقة مخصّصة للبنات'
              : 'هذه الحلقة مخصّصة للأولاد');
    }

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

  /// Live members of a circle — emits whenever the roster changes.
  Stream<List<CircleMember>> membersStream(String circleId) {
    return _members(circleId).snapshots().map((q) => q.docs
        .map((d) => CircleMemberDto.fromMap(d.id, d.data()))
        .toList(growable: false));
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

  /// Demote a supervisor back to a regular student member.
  Future<void> demoteToStudent({
    required String circleId,
    required String uid,
  }) async {
    await _circles.doc(circleId).update({
      'supervisorIds': FieldValue.arrayRemove([uid]),
    });
    await _members(circleId).doc(uid).update({
      'role': UserRole.student.name,
    });
  }

  /// Hand the circle to [newTeacherId]: they become the owning teacher, the
  /// previous owner is kept on as a supervisor.
  Future<void> transferOwnership({
    required String circleId,
    required String newTeacherId,
  }) async {
    final snap = await _circles.doc(circleId).get();
    final data = snap.data();
    if (data == null) {
      throw BadRequestException(message: 'الحلقة غير موجودة');
    }
    final oldTeacherId = data['teacherId'] as String?;
    final newProfile = await _users.doc(newTeacherId).get();
    final newName = (newProfile.data()?['name'] ?? '') as String;

    final supervisors =
        List<String>.from((data['supervisorIds'] ?? const []) as List);
    supervisors.remove(newTeacherId);
    if (oldTeacherId != null &&
        oldTeacherId != newTeacherId &&
        !supervisors.contains(oldTeacherId)) {
      supervisors.add(oldTeacherId);
    }
    await _circles.doc(circleId).update({
      'teacherId': newTeacherId,
      'teacherName': newName,
      'supervisorIds': supervisors,
    });
    // New owner becomes a teacher member; old owner becomes a supervisor.
    await _members(circleId)
        .doc(newTeacherId)
        .set({'role': UserRole.teacher.name}, SetOptions(merge: true));
    if (oldTeacherId != null && oldTeacherId != newTeacherId) {
      await _members(circleId)
          .doc(oldTeacherId)
          .set({'role': UserRole.supervisor.name}, SetOptions(merge: true));
    }
  }

  // --- US-38 ---

  Future<void> updatePrivacy({
    required String circleId,
    required Privacy privacy,
  }) async {
    await _circles.doc(circleId).update({'privacy': privacy.name});
  }

  /// Set the circle's memorization level (surah + ayah range).
  Future<void> updateLevel({
    required String circleId,
    required String unit,
    String surah = '',
    int? fromAyah,
    int? toAyah,
  }) async {
    await _circles.doc(circleId).update({
      'levelUnit': unit,
      'levelSurah': surah,
      'levelFromAyah': fromAyah,
      'levelToAyah': toAyah,
    });
  }

  /// Set the circle's short description (نبذة).
  Future<void> updateDescription({
    required String circleId,
    required String description,
  }) async {
    await _circles.doc(circleId).update({'description': description.trim()});
  }

  /// Set the circle's recitation (رواية).
  Future<void> updateRiwayah({
    required String circleId,
    required String riwayah,
  }) async {
    await _circles.doc(circleId).update({'riwayah': riwayah});
  }

  /// Set the circle's recurring weekly meeting schedule (days + per-day start
  /// time + default duration). Drives the global weekly calendar.
  Future<void> updateSchedule({
    required String circleId,
    required Map<String, String> dayTimes,
    required int durationMinutes,
  }) async {
    await _circles.doc(circleId).update({
      'days': dayTimes.keys.toList(),
      'dayTimes': dayTimes,
      'durationMinutes': durationMinutes,
    });
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

  // --- manual roster management (teacher) ---

  /// Manually add a student to a حلقة (no self-join). Creates an enrollment
  /// with a generated id; if the student later gets an account they can be linked.
  Future<CircleMember> addStudentManually({
    required String circleId,
    required String name,
    int? juz,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw BadRequestException(message: 'اسم الطالبة مطلوب');
    }
    final ref = _members(circleId).doc();
    final member = CircleMember(
      uid: ref.id,
      name: trimmed,
      role: UserRole.student,
      status: MemberStatus.active,
      juz: juz,
    );
    await ref.set(CircleMemberDto.toMap(member));
    return member;
  }

  /// Add an EXISTING account holder to the حلقة by their email or phone.
  /// Looks the user up in `users`, enrolls them with their real uid, and adds
  /// the circle to their membership so it appears in their own app.
  Future<CircleMember> addStudentByContact({
    required String circleId,
    required String contact,
  }) async {
    final value = contact.trim();
    if (value.isEmpty) {
      throw BadRequestException(message: 'أدخلي البريد الإلكتروني أو رقم الهاتف');
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? found;
    if (value.contains('@')) {
      final q = await _users.where('email', isEqualTo: value).limit(1).get();
      if (q.docs.isNotEmpty) found = q.docs.first;
    } else {
      // Phone: try the raw value plus normalized variants (digits only, with
      // a leading +, and without a leading 0) so different formats still match.
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final candidates = <String>{value, digits, '+$digits'};
      if (digits.startsWith('0')) candidates.add(digits.substring(1));
      for (final cand in candidates) {
        if (cand.isEmpty) continue;
        final q = await _users.where('phone', isEqualTo: cand).limit(1).get();
        if (q.docs.isNotEmpty) {
          found = q.docs.first;
          break;
        }
      }
    }
    // Last resort: treat the value as an email even without '@'.
    if (found == null) {
      final q = await _users.where('email', isEqualTo: value).limit(1).get();
      if (q.docs.isNotEmpty) found = q.docs.first;
    }
    if (found == null) {
      throw BadRequestException(
          message: 'لا يوجد مستخدم بهذا البريد أو رقم الهاتف');
    }

    final uid = found.id;
    final data = found.data();
    final name = (data['name'] ?? '') as String;

    // Gender separation (US-43): an account's gender must match the circle's.
    final circleDoc = await _circles.doc(circleId).get();
    final circleGender = Gender.fromName(circleDoc.data()?['gender'] as String?);
    final userGender = Gender.fromName(data['gender'] as String?);
    if (circleGender != null &&
        userGender != null &&
        userGender != circleGender) {
      throw BadRequestException(message: 'نوع الحساب لا يطابق نوع الحلقة');
    }

    final existing = await _members(circleId).doc(uid).get();
    if (existing.exists) {
      throw BadRequestException(message: 'هذه الطالبة مضافة بالفعل');
    }
    final member = CircleMember(
      uid: uid,
      name: name.isEmpty ? value : name,
      role: UserRole.student,
      status: MemberStatus.active,
    );
    await _members(circleId).doc(uid).set(CircleMemberDto.toMap(member));
    await _users.doc(uid).set(
      {'circleIds': FieldValue.arrayUnion([circleId])},
      SetOptions(merge: true),
    );
    return member;
  }

  /// Update a student's per-enrollment data (progress / attendance / rating).
  /// All changes are scoped to THIS حلقة only.
  Future<void> updateMember({
    required String circleId,
    required String uid,
    AttendanceState? attendance,
    PerformanceTag? performance,
    int? memorizedPages,
    int? juz,
    String? contact,
    String? notes,
    bool touchRecitation = false,
  }) async {
    final data = <String, dynamic>{};
    if (attendance != null) data['attendance'] = attendance.name;
    if (performance != null) data['performance'] = performance.name;
    if (memorizedPages != null) data['memorizedPages'] = memorizedPages;
    if (juz != null) data['juz'] = juz;
    if (contact != null) data['contact'] = contact;
    if (notes != null) data['notes'] = notes;
    if (touchRecitation) data['lastRecitationAt'] = FieldValue.serverTimestamp();
    if (data.isNotEmpty) await _members(circleId).doc(uid).update(data);
  }

  /// Remove a student from a حلقة.
  Future<void> removeMember({
    required String circleId,
    required String uid,
  }) async {
    await _members(circleId).doc(uid).delete();
  }

  // --- attendance history ---

  CollectionReference<Map<String, dynamic>> _attendance(String circleId) =>
      _circles.doc(circleId).collection('attendance');

  /// Mark (or clear, when [state] is null) a student's attendance for a day.
  /// Stored at circles/{id}/attendance/{dateId} as { records: { uid: state } }.
  Future<void> markAttendance({
    required String circleId,
    required String dateId,
    required String uid,
    AttendanceState? state,
  }) async {
    await _attendance(circleId).doc(dateId).set(<String, dynamic>{
      'records': <String, dynamic>{
        uid: state?.name ?? FieldValue.delete(),
      },
    }, SetOptions(merge: true));
  }

  /// Read attendance for the given day ids → { dateId: { uid: state } }.
  Future<Map<String, Map<String, AttendanceState>>> getWeekAttendance({
    required String circleId,
    required List<String> dateIds,
  }) async {
    final result = <String, Map<String, AttendanceState>>{};
    for (final dateId in dateIds) {
      final doc = await _attendance(circleId).doc(dateId).get();
      final records =
          (doc.data()?['records'] as Map<String, dynamic>?) ?? const {};
      final map = <String, AttendanceState>{};
      records.forEach((uid, v) {
        final s = AttendanceState.fromName(v as String?);
        if (s != null) map[uid] = s;
      });
      result[dateId] = map;
    }
    return result;
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
