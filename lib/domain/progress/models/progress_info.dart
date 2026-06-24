/// Student memorization progress (US-11).
class ProgressInfo {
  final String uid;
  final int pagesDone;
  final int totalPages;

  const ProgressInfo({
    required this.uid,
    this.pagesDone = 0,
    this.totalPages = 604, // pages in the standard Madinah mushaf
  });

  double get ratio => totalPages == 0 ? 0 : (pagesDone / totalPages).clamp(0, 1);
  int get percent => (ratio * 100).round();
}

/// One student's submission status for a given day (US-12).
class StudentSubmission {
  final String uid;
  final String name;
  final bool done;

  const StudentSubmission({
    required this.uid,
    required this.name,
    required this.done,
  });
}
