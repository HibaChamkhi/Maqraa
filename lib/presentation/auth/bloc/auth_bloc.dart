import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/auth/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthPhoneOtpRequested>(_onSendOtp);
    on<AuthOtpVerified>(_onVerifyOtp);
    on<AuthRoleSelected>(_onSelectRole);
    on<AuthPasswordChangeRequested>(_onChangePassword);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: UIStatus.loading));
    try {
      final user = await authRepository.currentUser();
      emit(state.copyWith(status: UIStatus.success, user: user, clearUser: user == null));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(state.copyWith(status: UIStatus.success, user: user));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final user = await authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
        gender: event.gender,
        role: event.role,
      );
      emit(state.copyWith(status: UIStatus.success, user: user));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onSendOtp(AuthPhoneOtpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final verificationId = await authRepository.sendPhoneOtp(event.phoneNumber);
      emit(state.copyWith(status: UIStatus.success, verificationId: verificationId, otpSent: true));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onVerifyOtp(AuthOtpVerified event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final user = await authRepository.verifyPhoneOtp(
        verificationId: state.verificationId ?? '',
        smsCode: event.smsCode,
      );
      emit(state.copyWith(status: UIStatus.success, user: user, otpSent: false));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onSelectRole(AuthRoleSelected event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await authRepository.setRole(event.role);
      final user = state.user?.copyWith(role: event.role);
      emit(state.copyWith(status: UIStatus.success, user: user));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onChangePassword(
      AuthPasswordChangeRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(status: UIStatus.success, message: 'تم تغيير كلمة المرور بنجاح'));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(const AuthState(status: UIStatus.success));
  }
}
