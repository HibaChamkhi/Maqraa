part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final UIStatus status;
  final String message;
  final AppUser? user;
  final String? verificationId;
  final bool otpSent;

  const AuthState({
    this.status = UIStatus.loading,
    this.message = '',
    this.user,
    this.verificationId,
    this.otpSent = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UIStatus? status,
    String? message,
    AppUser? user,
    bool clearUser = false,
    String? verificationId,
    bool? otpSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message ?? this.message,
      user: clearUser ? null : (user ?? this.user),
      verificationId: verificationId ?? this.verificationId,
      otpSent: otpSent ?? this.otpSent,
    );
  }

  @override
  List<Object?> get props => [status, message, user, verificationId, otpSent];
}
