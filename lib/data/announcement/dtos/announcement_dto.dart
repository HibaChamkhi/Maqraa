import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/announcement/models/announcement.dart';

/// Maps circles/{circleId}/announcements/{id} <-> [Announcement].
class AnnouncementDto {
  static Announcement fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      text: (map['text'] ?? '') as String,
      authorId: (map['authorId'] ?? '') as String,
      authorName: (map['authorName'] ?? '') as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(Announcement a) {
    return {
      'text': a.text,
      'authorId': a.authorId,
      'authorName': a.authorName,
      'createdAt': a.createdAt != null
          ? Timestamp.fromDate(a.createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
