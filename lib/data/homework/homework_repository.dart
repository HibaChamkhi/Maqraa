import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/homework/models/weekly_homework.dart';

/// Firestore access for «الواجب الأسبوعي». Constructed inline with the
/// already-registered [FirebaseFirestore] / [FirebaseAuth] (no DI codegen).
class HomeworkRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  HomeworkRepository(this.firestore, this.auth);

  CollectionReference<Map<String, dynamic>> _weeks(String circleId) =>
      firestore.collection('circles').doc(circleId).collection('homework');

  CollectionReference<Map<String, dynamic>> _completions(
          String circleId, String weekId) =>
      _weeks(circleId).doc(weekId).collection('completions');

  // --- teacher: the week's plan ---

  Stream<WeeklyHomework> weekStream(String circleId, String weekId,
      DateTime weekStart) {
    return _weeks(circleId).doc(weekId).snapshots().map((doc) {
      final data = doc.data();
      final rawDays = (data?['days'] as Map?) ?? const {};
      final days = <String, DayPlan>{};
      rawDays.forEach((k, v) {
        if (v is Map) {
          days[k.toString()] = DayPlan.fromMap(Map<String, dynamic>.from(v));
        }
      });
      return WeeklyHomework(
          weekId: weekId, weekStart: weekStart, days: days);
    });
  }

  Future<void> saveDay({
    required String circleId,
    required String weekId,
    required DateTime weekStart,
    required String dayCode,
    required String wajib,
    required String notes,
  }) async {
    await _weeks(circleId).doc(weekId).set({
      'weekStart': Timestamp.fromDate(weekStart),
      'days': {
        dayCode: {'wajib': wajib.trim(), 'notes': notes.trim()},
      },
    }, SetOptions(merge: true));
  }

  // --- completions (the قصاصة ticks) ---

  Stream<List<HomeworkCompletion>> completionsStream(
      String circleId, String weekId) {
    return _completions(circleId, weekId).snapshots().map((q) =>
        q.docs.map((d) => _completionFromMap(d.id, d.data())).toList());
  }

  Future<HomeworkCompletion> myCompletion(String circleId, String weekId) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return const HomeworkCompletion(uid: '');
    final doc = await _completions(circleId, weekId).doc(uid).get();
    return _completionFromMap(uid, doc.data() ?? const {});
  }

  Future<void> setDayDone({
    required String circleId,
    required String weekId,
    required String dayCode,
    required bool done,
    String? partnerName,
    String studentName = '',
  }) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final ref = _completions(circleId, weekId).doc(uid);
    await ref.set({
      'name': studentName,
      'doneDays': done
          ? FieldValue.arrayUnion([dayCode])
          : FieldValue.arrayRemove([dayCode]),
      if (partnerName != null) 'partners': {dayCode: partnerName},
    }, SetOptions(merge: true));
  }

  HomeworkCompletion _completionFromMap(String uid, Map<String, dynamic> m) {
    final done = ((m['doneDays'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();
    final partners = <String, String>{};
    (m['partners'] as Map?)?.forEach((k, v) => partners[k.toString()] = '$v');
    return HomeworkCompletion(
      uid: uid,
      name: (m['name'] ?? '') as String,
      doneDays: done,
      partners: partners,
    );
  }
}
