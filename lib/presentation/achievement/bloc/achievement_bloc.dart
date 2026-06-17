import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/achievement/models/achievement.dart';
import '../../../domain/achievement/repositories/achievement_repository.dart';

part 'achievement_event.dart';
part 'achievement_state.dart';

@injectable
class AchievementBloc extends Bloc<AchievementEvent, AchievementState> {
  final AchievementRepository achievementRepository;

  AchievementBloc(this.achievementRepository)
      : super(const AchievementState()) {
    on<AchievementRequested>(_onLoad);
    on<AchievementCompletionRegistered>(_onComplete);
  }

  Future<void> _onLoad(
      AchievementRequested event, Emitter<AchievementState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final achievement = await achievementRepository.getAchievement();
      emit(state.copyWith(status: UIStatus.success, achievement: achievement));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onComplete(AchievementCompletionRegistered event,
      Emitter<AchievementState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final before = state.achievement.badges.toSet();
      final achievement = await achievementRepository.registerCompletion();
      final newBadges =
          achievement.badges.toSet().difference(before).toList();
      emit(state.copyWith(
        status: UIStatus.success,
        achievement: achievement,
        message: newBadges.isNotEmpty
            ? 'مبارك! حصلتِ على وسام جديد'
            : 'تم تسجيل إنجاز اليوم (سلسلة ${achievement.streakCount})',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
