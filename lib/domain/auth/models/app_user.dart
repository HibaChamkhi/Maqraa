/// User roles in Wesal. «الرفيقة» is not a separate role — every student can be
/// a recitation partner for another student.
enum UserRole {
  teacher, // المعلّمة
  supervisor, // المشرفة (مساعدة المعلّمة)
  student; // الطالبة

  String get arabicLabel {
    switch (this) {
      case UserRole.teacher:
        return 'معلّمة';
      case UserRole.supervisor:
        return 'مشرفة';
      case UserRole.student:
        return 'طالبة';
    }
  }

  static UserRole? fromName(String? value) {
    return UserRole.values.where((r) => r.name == value).firstOrNull;
  }
}

/// Gender — drives the FULL separation between men's and women's spaces (US-43).
/// Every circle and space is single-gender; this value gates what a user sees.
enum Gender {
  female, // أنثى
  male; // ذكر

  String get arabicLabel => this == Gender.female ? 'أنثى' : 'ذكر';

  static Gender? fromName(String? value) {
    return Gender.values.where((g) => g.name == value).firstOrNull;
  }
}

/// Core user entity used across the app.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? city;
  final String? photoUrl;
  final UserRole? role;
  final Gender? gender;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.city,
    this.photoUrl,
    this.role,
    this.gender,
  });

  bool get hasCompletedProfile => role != null && gender != null;

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    String? photoUrl,
    UserRole? role,
    Gender? gender,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      gender: gender ?? this.gender,
    );
  }
}
