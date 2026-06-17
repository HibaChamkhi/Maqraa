import 'package:injectable/injectable.dart';

import '../../../domain/progress/models/progress_info.dart';
import '../../../domain/progress/repositories/progress_repository.dart';
import '../data_sources/remote/progress_data_source.dart';

@Injectable(as: ProgressRepository)
class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDataSource remoteDataSource;

  ProgressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProgressInfo> getMyProgress() => remoteDataSource.getMyProgress();

  @override
  Future<ProgressInfo> addProgress(int pages) => remoteDataSource.addProgress(pages);

  @override
  Future<List<StudentSubmission>> getTodaySubmissions(String circleId) =>
      remoteDataSource.getTodaySubmissions(circleId);
}
