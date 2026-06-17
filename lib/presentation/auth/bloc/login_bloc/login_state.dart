part of 'login_bloc.dart';

class LoginState extends UIState<void> {
  const LoginState({
    super.status,
    super.message,
  });

  @override
  LoginState copyWith({
    UIStatus? status,
    String? message,
    void data,
  }) {
    return LoginState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
