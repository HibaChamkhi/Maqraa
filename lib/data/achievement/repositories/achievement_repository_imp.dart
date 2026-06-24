import 'package:injectable/injectable.dart';

import '../../../domain/achievement/models/achievement.dart';
import '../../../domain/achievement/repositories/achievement_repository.dart';
import '../data_sources/remote/achievement_data_source.dart';

@Injectable(as: AchievementRepository)
class AchievementRepositoryImpl implements AchievementRepository {
  final AchievementRemoteDataSource remoteDataSource;

  AchievementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Achievement> getAchievement() => remoteDataSource.getAchievement();

  @override
  Future<Achievement> registerCompletion() =>
      remoteDataSource.registerCompletion();
}
