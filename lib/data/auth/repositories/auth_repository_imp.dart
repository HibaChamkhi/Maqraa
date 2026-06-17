import 'package:injectable/injectable.dart';

import '../../../domain/auth/models/app_user.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../data_sources/remote/auth_data_source.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AppUser?> currentUser() => remoteDataSource.currentUser();

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required Gender gender,
    UserRole? role,
  }) {
    return remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      gender: gender,
      role: role,
    );
  }

  @override
  Future<AppUser> login(String email, String password) =>
      remoteDataSource.login(email, password);

  @override
  Future<String> sendPhoneOtp(String phoneNumber) =>
      remoteDataSource.sendPhoneOtp(phoneNumber);

  @override
  Future<AppUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) {
    return remoteDataSource.verifyPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  Future<void> setRole(UserRole role) => remoteDataSource.setRole(role);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> logout() => remoteDataSource.logout();
}
