import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/progress/models/progress_info.dart';

@injectable
class ProgressRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  ProgressRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  String get _uid {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid == null) throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    return uid;
  }

  Future<ProgressInfo> getMyProgress() async {
    final doc = await firestore.collection('users').doc(_uid).get();
    final data = doc.data() ?? {};
    return ProgressInfo(
      uid: _uid,
      pagesDone: (data['progressPages'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 604,
    );
  }

  Future<ProgressInfo> addProgress(int pages) async {
    final ref = firestore.collection('users').doc(_uid);
    await ref.set({
      'progressPages': FieldValue.increment(pages),
    }, SetOptions(merge: true));
    return getMyProgress();
  }

  Future<List<StudentSubmission>> getTodaySubmissions(String circleId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Active students in the circle.
    final membersSnap = await firestore
        .collection('circles')
        .doc(circleId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .where('role', isEqualTo: 'student')
        .get();

    // Today's task docs (keyed by student uid).
    final tasksSnap = await firestore
        .collection('circles')
        .doc(circleId)
        .collection('tasks')
        .doc(today)
        .collection('students')
        .get();
    final doneByUid = <String, bool>{
      for (final d in tasksSnap.docs) d.id: (d.data()['status'] == 'done'),
    };

    return membersSnap.docs.map((m) {
      final data = m.data();
      return StudentSubmission(
        uid: m.id,
        name: (data['name'] ?? '') as String,
        done: doneByUid[m.id] ?? false,
      );
    }).toList();
  }
}
