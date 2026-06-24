import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/generated_cv.dart';

abstract class CvRemoteDatasource {
  Future<GeneratedCv?> getCachedCv(String evaluationId);
}

class CvRemoteDatasourceImpl implements CvRemoteDatasource {
  final _db = FirebaseFirestore.instance;

  @override
  Future<GeneratedCv?> getCachedCv(String evaluationId) async {
    final doc = await _db.collection('cvs').doc(evaluationId).get();
    if (!doc.exists || doc.data() == null) return null;
    return GeneratedCv.fromJson({...doc.data()!, 'evaluationId': evaluationId});
  }
}
