import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/task/models/assignment.dart';

/// Maps `circles/{circleId}/assignments/{assignmentId}` <-> [Assignment].
class AssignmentDto {
  static Assignment fromMap(String id, Map<String, dynamic> map) {
    return Assignment(
      id: id,
      studentId: (map['studentId'] ?? '') as String,
      studentName: (map['studentName'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      done: (map['done'] ?? false) as bool,
    );
  }

  static Map<String, dynamic> toMap(Assignment assignment) {
    return {
      'studentId': assignment.studentId,
      'studentName': assignment.studentName,
      'title': assignment.title,
      'date': Timestamp.fromDate(assignment.date),
      'done': assignment.done,
    };
  }
}
