import '../../../domain/auth/models/app_user.dart';

/// Maps the `users/{uid}` Firestore document <-> [AppUser].
class AppUserDto {
  static AppUser fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.fromName(map['role'] as String?),
      gender: Gender.fromName(map['gender'] as String?),
    );
  }

  static Map<String, dynamic> toMap(AppUser user) {
    return {
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'photoUrl': user.photoUrl,
      'role': user.role?.name,
      'gender': user.gender?.name,
    };
  }
}
