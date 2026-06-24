part of 'achievement_bloc.dart';

abstract class AchievementEvent extends Equatable {
  const AchievementEvent();

  @override
  List<Object?> get props => [];
}

class AchievementRequested extends AchievementEvent {
  const AchievementRequested();
}

class AchievementCompletionRegistered extends AchievementEvent {
  const AchievementCompletionRegistered();
}
