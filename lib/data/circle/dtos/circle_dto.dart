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
      teacherName: (map['teacherName'] ?? '') as String,
      gender: Gender.fromName(map['gender'] as String?) ?? Gender.female,
      privacy: Privacy.fromName(map['privacy'] as String?),
      inviteCode: (map['inviteCode'] ?? '') as String,
      supervisorIds:
          ((map['supervisorIds'] as List?)?.cast<String>()) ?? const [],
      level: (map['level'] ?? '') as String,
      levelUnit: (map['levelUnit'] ?? '') as String,
      levelSurah: (map['levelSurah'] ?? '') as String,
      levelFromAyah: (map['levelFromAyah'] as num?)?.toInt(),
      levelToAyah: (map['levelToAyah'] as num?)?.toInt(),
      riwayah: (map['riwayah'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      days: ((map['days'] as List?)?.cast<String>()) ?? const [],
      dayTimes: ((map['dayTimes'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()))) ??
          const {},
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(Circle circle) {
    return {
      'name': circle.name,
      'teacherId': circle.teacherId,
      'teacherName': circle.teacherName,
      'gender': circle.gender.name,
      'privacy': circle.privacy.name,
      'inviteCode': circle.inviteCode,
      'supervisorIds': circle.supervisorIds,
      'level': circle.level,
      'levelUnit': circle.levelUnit,
      'levelSurah': circle.levelSurah,
      'levelFromAyah': circle.levelFromAyah,
      'levelToAyah': circle.levelToAyah,
      'riwayah': circle.riwayah,
      'description': circle.description,
      'days': circle.days,
      'dayTimes': circle.dayTimes,
      'durationMinutes': circle.durationMinutes,
      'createdAt': circle.createdAt != null
          ? Timestamp.fromDate(circle.createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Maps `circles/{circleId}/members/{uid}` <-> [CircleMember] (the enrollment).
class CircleMemberDto {
  static CircleMember fromMap(String uid, Map<String, dynamic> map) {
    return CircleMember(
      uid: uid,
      name: (map['name'] ?? '') as String,
      role: UserRole.fromName(map['role'] as String?) ?? UserRole.student,
      status: MemberStatus.fromName(map['status'] as String?),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
      memorizedPages: (map['memorizedPages'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 604,
      attendance: AttendanceState.fromName(map['attendance'] as String?),
      lastRecitationAt: (map['lastRecitationAt'] as Timestamp?)?.toDate(),
      performance: PerformanceTag.fromName(map['performance'] as String?),
      partnerId: map['partnerId'] as String?,
      juz: (map['juz'] as num?)?.toInt(),
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
      'memorizedPages': member.memorizedPages,
      'totalPages': member.totalPages,
      'attendance': member.attendance?.name,
      'lastRecitationAt': member.lastRecitationAt != null
          ? Timestamp.fromDate(member.lastRecitationAt!)
          : null,
      'performance': member.performance?.name,
      'partnerId': member.partnerId,
      'juz': member.juz,
    };
  }
}
