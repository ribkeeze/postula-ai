import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/job_evaluation.dart';

abstract class EvaluationRemoteDatasource {
  Future<JobEvaluation> evaluate(String jobText);
  Future<List<JobEvaluation>> getEvaluations();
  Future<JobEvaluation> getEvaluation(String id);
}

class EvaluationRemoteDatasourceImpl
    implements EvaluationRemoteDatasource {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  EvaluationRemoteDatasourceImpl({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(
                region: 'southamerica-east1'),
        _firestore =
            firestore ?? FirebaseFirestore.instance;

  @override
  Future<JobEvaluation> evaluate(String jobText) async {
    final result = await _functions
        .httpsCallable('evaluateJob')
        .call({'jobText': jobText});

    final data =
        Map<String, dynamic>.from(result.data as Map);

    // La función devuelve evaluationId, no id
    return JobEvaluation.fromJson({
      ...data,
      'id': data['evaluationId'] ?? '',
      'userId':
          FirebaseAuth.instance.currentUser?.uid ?? '',
      'rawJobText': jobText,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<JobEvaluation>> getEvaluations() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _firestore
        .collection('evaluations')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snap.docs
        .map((d) => JobEvaluation.fromJson(d.data()))
        .toList();
  }

  @override
  Future<JobEvaluation> getEvaluation(String id) async {
    final doc = await _firestore
        .collection('evaluations')
        .doc(id)
        .get();
    if (!doc.exists) {
      throw Exception('Evaluación no encontrada');
    }

    final data = doc.data()!;

    // Convertir Timestamp a String para que fromJson lo acepte
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }

    return JobEvaluation.fromJson(data);
  }
}
