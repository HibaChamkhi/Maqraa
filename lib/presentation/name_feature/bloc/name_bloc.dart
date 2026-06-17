import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/name_feature/repositories/feature_name_repository.dart';

part 'name_event.dart';

part 'name_state.dart';

@injectable
class NameBloc extends Bloc<NameEvent, NameState> {
  final NameFeatureRepository nameFeatureRepository;

  NameBloc(this.nameFeatureRepository) : super(const NameState()) {
    on<CreateNameEvent>(_onCreateNameEvent);
    on<ReadNameEvent>(_onReadNameEvent);
    on<UpdateNameEvent>(_onUpdateNameEvent);
    on<DeleteNameEvent>(_onDeleteNameEvent);
  }

  void _onCreateNameEvent(
      CreateNameEvent event, Emitter<NameState> emit) async {
    emit(state.copyWith(status:  UIStatus.loading));

    try {
      await nameFeatureRepository.create(event.data);
      emit(state.copyWith(status:  UIStatus.success));
    } on Exception catch (e) {
      emit(state.copyWith(
        status:  UIStatus.error,
        message: mapExceptionToMessage(e),
      ));
    }
  }

  void _onReadNameEvent(ReadNameEvent event, Emitter<NameState> emit) async {
    emit(state.copyWith(status:  UIStatus.loading));

    try {
      final data = await nameFeatureRepository.read(event.id);
      emit(state.copyWith(
        status:  UIStatus.success,
        data: data, // Emit the data separately
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status:  UIStatus.error,
        message: mapExceptionToMessage(e),
      ));
    }
  }

  void _onUpdateNameEvent(
      UpdateNameEvent event, Emitter<NameState> emit) async {
    emit(state.copyWith(status:  UIStatus.loading));

    try {
      await nameFeatureRepository.update(event.id, event.data);
      emit(state.copyWith(status:  UIStatus.success));
    } on Exception catch (e) {
      emit(state.copyWith(
        status:  UIStatus.error,
        message: mapExceptionToMessage(e),
      ));
    }
  }

  void _onDeleteNameEvent(
      DeleteNameEvent event, Emitter<NameState> emit) async {
    emit(state.copyWith(status:  UIStatus.loading));

    try {
      await nameFeatureRepository.delete(event.id);
      emit(state.copyWith(status:  UIStatus.success));
    } on Exception catch (e) {
      emit(state.copyWith(
        status:  UIStatus.error,
        message: mapExceptionToMessage(e),
      ));
    }
  }
}
