import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coach_session.dart';

abstract class CoachRemoteDatasource {
  Future<CoachSession?> getCachedCoach(String evaluationId);
}

class CoachRemoteDatasourceImpl implements CoachRemoteDatasource {
  final _db = FirebaseFirestore.instance;

  @override
  Future<CoachSession?> getCachedCoach(String evaluationId) async {
    final doc = await _db.collection('coachSessions').doc(evaluationId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CoachSession.fromJson({
      ...doc.data()!,
      'evaluationId': evaluationId,
    });
  }
}
