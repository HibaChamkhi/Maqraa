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

  /// Structured memorization level.
  /// [levelUnit] is 'juz' | 'hizb' | 'surah'. For juz/hizb the range is in
  /// [levelFromAyah]/[levelToAyah] (the juz/hizb numbers); for surah the
  /// surah name is in [levelSurah] and the ayah range in from/to.
  final String levelUnit;
  final String levelSurah;
  final int? levelFromAyah;
  final int? levelToAyah;

  /// The حلقة's recitation (رواية), e.g. «حفص عن عاصم».
  final String riwayah;

  /// A short free-text note the teacher writes, shown under the name.
  final String description;

  /// Arabic display for the level, e.g. «جزء ٥ – ٣٠» or «البقرة · الآيات ١–٥٠».
  String get levelLabel {
    final f = levelFromAyah, t = levelToAyah;
    String pair(String u) =>
        (t == null || t == f) ? '$u $f' : '$u $f – $t';
    switch (levelUnit) {
      case 'juz':
        return f == null ? (level) : pair('جزء');
      case 'hizb':
        return f == null ? (level) : pair('حزب');
      case 'surah':
        if (levelSurah.isEmpty) return level;
        if (f == null) return levelSurah;
        return (t == null || t == f)
            ? '$levelSurah · الآية $f'
            : '$levelSurah · الآيات $f–$t';
      default:
        return level;
    }
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
    this.levelUnit = '',
    this.levelSurah = '',
    this.levelFromAyah,
    this.levelToAyah,
    this.riwayah = '',
    this.description = '',
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
    String? levelUnit,
    String? levelSurah,
    int? levelFromAyah,
    int? levelToAyah,
    String? riwayah,
    String? description,
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
      levelUnit: levelUnit ?? this.levelUnit,
      levelSurah: levelSurah ?? this.levelSurah,
      levelFromAyah: levelFromAyah ?? this.levelFromAyah,
      levelToAyah: levelToAyah ?? this.levelToAyah,
      riwayah: riwayah ?? this.riwayah,
      description: description ?? this.description,
      days: days ?? this.days,
      dayTimes: dayTimes ?? this.dayTimes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// The single source of truth for "what can this user do in THIS circle?".
/// Always use these instead of the global [AppUser.role], which only says what
/// kind of account someone has — not their authority in a specific حلقة.
extension CircleAuthority on Circle {
  /// This user's role *within this circle* (owner teacher, supervisor, or
  /// plain student/member).
  UserRole roleOf(AppUser? user) {
    if (user == null) return UserRole.student;
    if (teacherId == user.uid) return UserRole.teacher;
    if (supervisorIds.contains(user.uid)) return UserRole.supervisor;
    return UserRole.student;
  }

  /// True only for the owning teacher of this circle.
  bool isOwner(AppUser? user) => user != null && teacherId == user.uid;

  /// Teacher (owner) or supervisor of this circle — may manage students,
  /// grading, tracking, schedule, etc.
  bool canManage(AppUser? user) {
    final r = roleOf(user);
    return r == UserRole.teacher || r == UserRole.supervisor;
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
