import '../models/progress_info.dart';

/// Progress tracking (US-11 student progress, US-12 teacher daily tracking).
abstract class ProgressRepository {
  /// Current user's memorization progress.
  Future<ProgressInfo> getMyProgress();

  /// Add [pages] to the current user's completed pages.
  Future<ProgressInfo> addProgress(int pages);

  /// Today's submission status for every active student in a circle.
  Future<List<StudentSubmission>> getTodaySubmissions(String circleId);
}
