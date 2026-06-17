/// A circle announcement «إعلان» under
/// circles/{circleId}/announcements/{id}:
/// { text, authorId, authorName, createdAt (Timestamp) }.
class Announcement {
  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final DateTime? createdAt;

  const Announcement({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    this.createdAt,
  });

  Announcement copyWith({
    String? text,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
  }) {
    return Announcement(
      id: id,
      text: text ?? this.text,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
