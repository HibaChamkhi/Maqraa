import '../models/app_user.dart';

/// Auth contract. Implemented with Firebase Auth + Firestore in the data layer.
abstract class AuthRepository {
  /// Currently signed-in user (with role/gender from Firestore), or null.
  Future<AppUser?> currentUser();

  /// Register with email + password, then create the user profile document.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required Gender gender,
    UserRole? role,
  });

  /// Email + password sign-in.
  Future<AppUser> login(String email, String password);

  /// --- Phone (OTP) sign-in, two steps ---
  /// 1) Send the SMS code. Returns a verificationId to pass back with the code.
  Future<String> sendPhoneOtp(String phoneNumber);

  /// 2) Verify the code and sign in.
  Future<AppUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Persist the chosen role (US-02).
  Future<void> setRole(UserRole role);

  /// Securely change password — requires the current password to re-authenticate (US-37).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
}
