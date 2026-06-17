import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/error_utils.dart';
import '../../../../domain/auth/repositories/auth_repository.dart';

part 'register_event.dart';

part 'register_state.dart';

@injectable
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository authRepository;

  RegisterBloc(this.authRepository) : super(const RegisterState()) {
    on<RegisterUserEvent>(_onRegisterUserEvent);
  }

  void _onRegisterUserEvent(
      RegisterUserEvent event, Emitter<RegisterState> emit) async {
    emit(state.copyWith(registerStatus: RegisterStatus.loading, message: ''));

    try {
      await authRepository.register(event.userInfo);
      emit(state.copyWith(registerStatus: RegisterStatus.success,));
    } on Exception catch (e) {
      emit(state.copyWith(
        message: mapExceptionToMessage(e),
        registerStatus: RegisterStatus.error,
      ));
    }
  }

}
