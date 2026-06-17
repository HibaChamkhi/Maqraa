import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/announcement/models/announcement.dart';
import '../../../domain/announcement/repositories/announcement_repository.dart';

part 'announcement_event.dart';
part 'announcement_state.dart';

@injectable
class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  final AnnouncementRepository announcementRepository;

  AnnouncementBloc(this.announcementRepository)
      : super(const AnnouncementState()) {
    on<AnnouncementsRequested>(_onLoad);
    on<AnnouncementPosted>(_onPost);
  }

  Future<void> _onLoad(
      AnnouncementsRequested event, Emitter<AnnouncementState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final items =
          await announcementRepository.getAnnouncements(event.circleId);
      emit(state.copyWith(status: UIStatus.success, announcements: items));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onPost(
      AnnouncementPosted event, Emitter<AnnouncementState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await announcementRepository.postAnnouncement(
        circleId: event.circleId,
        text: event.text,
      );
      final items =
          await announcementRepository.getAnnouncements(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        announcements: items,
        actionDone: true,
        message: 'تم نشر الإعلان',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
