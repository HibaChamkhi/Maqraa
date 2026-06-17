part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final Gender gender;
  final UserRole? role;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    required this.gender,
    this.role,
  });

  @override
  List<Object?> get props => [name, email, password, phone, gender, role];
}

class AuthPhoneOtpRequested extends AuthEvent {
  final String phoneNumber;

  const AuthPhoneOtpRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthOtpVerified extends AuthEvent {
  final String smsCode;

  const AuthOtpVerified(this.smsCode);

  @override
  List<Object?> get props => [smsCode];
}

class AuthRoleSelected extends AuthEvent {
  final UserRole role;

  const AuthRoleSelected(this.role);

  @override
  List<Object?> get props => [role];
}

class AuthPasswordChangeRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const AuthPasswordChangeRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
