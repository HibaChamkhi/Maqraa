import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/auth/models/app_user.dart';
import '../../../domain/circle/models/circle.dart';

/// Maps the `circles/{circleId}` document <-> [Circle].
class CircleDto {
  static Circle fromMap(String id, Map<String, dynamic> map) {
    return Circle(
      id: id,
      name: (map['name'] ?? '') as String,
      teacherId: (map['teacherId'] ?? '') as String,
      gender: Gender.fromName(map['gender'] as String?) ?? Gender.female,
      privacy: Privacy.fromName(map['privacy'] as String?),
      inviteCode: (map['inviteCode'] ?? '') as String,
      supervisorIds:
          ((map['supervisorIds'] as List?)?.cast<String>()) ?? const [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(Circle circle) {
    return {
      'name': circle.name,
      'teacherId': circle.teacherId,
      'gender': circle.gender.name,
      'privacy': circle.privacy.name,
      'inviteCode': circle.inviteCode,
      'supervisorIds': circle.supervisorIds,
      'createdAt': circle.createdAt != null
          ? Timestamp.fromDate(circle.createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Maps `circles/{circleId}/members/{uid}` <-> [CircleMember].
class CircleMemberDto {
  static CircleMember fromMap(String uid, Map<String, dynamic> map) {
    return CircleMember(
      uid: uid,
      name: (map['name'] ?? '') as String,
      role: UserRole.fromName(map['role'] as String?) ?? UserRole.student,
      status: MemberStatus.fromName(map['status'] as String?),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(CircleMember member) {
    return {
      'uid': member.uid,
      'name': member.name,
      'role': member.role.name,
      'status': member.status.name,
      'joinedAt': member.joinedAt != null
          ? Timestamp.fromDate(member.joinedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
