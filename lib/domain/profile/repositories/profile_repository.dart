import '../../auth/models/app_user.dart';

/// Profile editing (US-36). Auth/password concerns live in AuthRepository.
abstract class ProfileRepository {
  Future<AppUser> updateProfile({
    required String uid,
    String? name,
    String? photoUrl,
  });
}
