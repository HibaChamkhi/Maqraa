import '../../auth/models/app_user.dart';

/// Visibility of a circle (US-38).
/// - public: discoverable; students can send join requests.
/// - private: invite-only; joinable only via invite code / QR.
enum Privacy {
  public, // عامة
  private; // خاصة

  String get arabicLabel => this == Privacy.public ? 'عامة' : 'خاصة';

  static Privacy fromName(String? value) {
    return Privacy.values.where((p) => p.name == value).firstOrNull ??
        Privacy.private;
  }
}

/// Membership state of a circle member.
/// - active: full member.
/// - pending: awaiting approval of a join request (US-39 / US-41).
enum MemberStatus {
  active, // نشط
  pending; // قيد الانتظار

  String get arabicLabel => this == MemberStatus.active ? 'نشط' : 'قيد الانتظار';

  static MemberStatus fromName(String? value) {
    return MemberStatus.values.where((s) => s.name == value).firstOrNull ??
        MemberStatus.active;
  }
}

/// A memorization circle «حلقة».
class Circle {
  final String id;
  final String name;
  final String teacherId;
  final Gender gender;
  final Privacy privacy;
  final String inviteCode;
  final List<String> supervisorIds;
  final DateTime? createdAt;

  const Circle({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.gender,
    this.privacy = Privacy.private,
    required this.inviteCode,
    this.supervisorIds = const [],
    this.createdAt,
  });

  Circle copyWith({
    String? name,
    String? teacherId,
    Gender? gender,
    Privacy? privacy,
    String? inviteCode,
    List<String>? supervisorIds,
    DateTime? createdAt,
  }) {
    return Circle(
      id: id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      gender: gender ?? this.gender,
      privacy: privacy ?? this.privacy,
      inviteCode: inviteCode ?? this.inviteCode,
      supervisorIds: supervisorIds ?? this.supervisorIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A member document under circles/{circleId}/members/{uid}.
class CircleMember {
  final String uid;
  final String name;
  final UserRole role;
  final MemberStatus status;
  final DateTime? joinedAt;

  const CircleMember({
    required this.uid,
    required this.name,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  CircleMember copyWith({
    String? name,
    UserRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
  }) {
    return CircleMember(
      uid: uid,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
