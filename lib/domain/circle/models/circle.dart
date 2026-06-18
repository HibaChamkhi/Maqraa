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

/// Attendance state for a student in their حلقة (per-enrollment).
enum AttendanceState {
  present, // حاضر
  excused, // مستأذن
  absent, // غياب
  late_; // متأخر

  String get arabicLabel {
    switch (this) {
      case AttendanceState.present:
        return 'حاضر';
      case AttendanceState.excused:
        return 'مستأذن';
      case AttendanceState.absent:
        return 'غياب';
      case AttendanceState.late_:
        return 'متأخر';
    }
  }

  static AttendanceState? fromName(String? value) =>
      AttendanceState.values.where((s) => s.name == value).firstOrNull;
}

/// Teacher's qualitative rating of a student's memorization (per-enrollment).
enum PerformanceTag {
  excellent, // ممتاز
  good, // جيد
  average, // متوسط
  needsFollowUp; // يحتاج متابعة

  String get arabicLabel {
    switch (this) {
      case PerformanceTag.excellent:
        return 'ممتاز';
      case PerformanceTag.good:
        return 'جيد';
      case PerformanceTag.average:
        return 'متوسط';
      case PerformanceTag.needsFollowUp:
        return 'يحتاج متابعة';
    }
  }

  static PerformanceTag? fromName(String? value) =>
      PerformanceTag.values.where((s) => s.name == value).firstOrNull;
}

/// A memorization circle «حلقة».
class Circle {
  final String id;
  final String name;
  final String teacherId;
  final String teacherName;
  final Gender gender;
  final Privacy privacy;
  final String inviteCode;
  final List<String> supervisorIds;

  /// Legacy free-text level (kept for backward compatibility).
  final String level;

  /// Structured memorization level: surah name + ayah range.
  final String levelSurah;
  final int? levelFromAyah;
  final int? levelToAyah;

  /// The حلقة's recitation (رواية), e.g. «حفص عن عاصم».
  final String riwayah;

  /// Arabic display for the level, e.g. «البقرة · الآيات ١–٥٠».
  String get levelLabel {
    if (levelSurah.isEmpty) return level.isEmpty ? '' : level;
    final f = levelFromAyah, t = levelToAyah;
    if (f == null) return levelSurah;
    if (t == null || t == f) return '$levelSurah · الآية $f';
    return '$levelSurah · الآيات $f–$t';
  }

  /// Session days, e.g. ['sun','tue','thu'].
  final List<String> days;

  /// Recurring meeting start time per day code, e.g. {'sun':'08:00','tue':'10:00'}.
  final Map<String, String> dayTimes;

  /// Default meeting length in minutes (applies to every recurring day).
  final int durationMinutes;

  final DateTime? createdAt;

  const Circle({
    required this.id,
    required this.name,
    required this.teacherId,
    this.teacherName = '',
    required this.gender,
    this.privacy = Privacy.private,
    required this.inviteCode,
    this.supervisorIds = const [],
    this.level = '',
    this.levelSurah = '',
    this.levelFromAyah,
    this.levelToAyah,
    this.riwayah = '',
    this.days = const [],
    this.dayTimes = const {},
    this.durationMinutes = 60,
    this.createdAt,
  });

  Circle copyWith({
    String? name,
    String? teacherId,
    String? teacherName,
    Gender? gender,
    Privacy? privacy,
    String? inviteCode,
    List<String>? supervisorIds,
    String? level,
    String? levelSurah,
    int? levelFromAyah,
    int? levelToAyah,
    String? riwayah,
    List<String>? days,
    Map<String, String>? dayTimes,
    int? durationMinutes,
    DateTime? createdAt,
  }) {
    return Circle(
      id: id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      gender: gender ?? this.gender,
      privacy: privacy ?? this.privacy,
      inviteCode: inviteCode ?? this.inviteCode,
      supervisorIds: supervisorIds ?? this.supervisorIds,
      level: level ?? this.level,
      levelSurah: levelSurah ?? this.levelSurah,
      levelFromAyah: levelFromAyah ?? this.levelFromAyah,
      levelToAyah: levelToAyah ?? this.levelToAyah,
      riwayah: riwayah ?? this.riwayah,
      days: days ?? this.days,
      dayTimes: dayTimes ?? this.dayTimes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// An enrollment: `circles/{circleId}/members/{uid}`.
///
/// This is the join between a user and ONE specific حلقة. All per-circle student
/// data lives here, so the same person enrolled in two حلقات is tracked
/// independently (different progress, attendance, partner per حلقة).
class CircleMember {
  final String uid;
  final String name;
  final UserRole role;
  final MemberStatus status;
  final DateTime? joinedAt;

  // --- per-enrollment progress & follow-up ---
  final int memorizedPages; // الأجزاء/الصفحات المحفوظة في هذه الحلقة
  final int totalPages; // المرجع (افتراضيًا 604)
  final AttendanceState? attendance; // حالة الحضور
  final DateTime? lastRecitationAt; // آخر تسميع
  final PerformanceTag? performance; // تقييم المعلّمة
  final String? partnerId; // الرفيقة في هذه الحلقة
  final int? juz; // الجزء الحالي للطالبة

  const CircleMember({
    required this.uid,
    required this.name,
    required this.role,
    required this.status,
    this.joinedAt,
    this.memorizedPages = 0,
    this.totalPages = 604,
    this.attendance,
    this.lastRecitationAt,
    this.performance,
    this.partnerId,
    this.juz,
  });

  double get memorizedRatio =>
      totalPages == 0 ? 0 : (memorizedPages / totalPages).clamp(0, 1);
  int get memorizedPercent => (memorizedRatio * 100).round();

  CircleMember copyWith({
    String? name,
    UserRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
    int? memorizedPages,
    int? totalPages,
    AttendanceState? attendance,
    DateTime? lastRecitationAt,
    PerformanceTag? performance,
    String? partnerId,
    int? juz,
  }) {
    return CircleMember(
      uid: uid,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      memorizedPages: memorizedPages ?? this.memorizedPages,
      totalPages: totalPages ?? this.totalPages,
      attendance: attendance ?? this.attendance,
      lastRecitationAt: lastRecitationAt ?? this.lastRecitationAt,
      performance: performance ?? this.performance,
      partnerId: partnerId ?? this.partnerId,
      juz: juz ?? this.juz,
    );
  }
}
