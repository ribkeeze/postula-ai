// ── Domain ────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/application.dart';
import '../../../evaluation/domain/entities/job_evaluation.dart';

part 'tracker_provider.g.dart';

// ── Datasource ────────────────────────────────────────────────────────────────

class TrackerRemoteDatasource {
  final FirebaseFirestore _db;
  TrackerRemoteDatasource({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Application>> watchApplications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('applications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Application.fromJson(d.data())).toList(),
        );
  }

  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    await _db.collection('applications').doc(applicationId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNotes(String applicationId, String notes) async {
    await _db.collection('applications').doc(applicationId).update({
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteApplication(String id, String evaluationId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('applications').doc(id));
    batch.delete(_db.collection('evaluations').doc(evaluationId));

    // Solo borrar cv y coach si existen
    final cvDoc = await _db.collection('cvs').doc(evaluationId).get();
    if (cvDoc.exists) {
      batch.delete(_db.collection('cvs').doc(evaluationId));
    }

    final coachDoc = await _db
        .collection('coachSessions')
        .doc(evaluationId)
        .get();
    if (coachDoc.exists) {
      batch.delete(_db.collection('coachSessions').doc(evaluationId));
    }

    await batch.commit();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

@riverpod
TrackerRemoteDatasource trackerDatasource(Ref ref) => TrackerRemoteDatasource();

/// Stream reactivo de todas las postulaciones del usuario.
@riverpod
Stream<List<Application>> applications(Ref ref) {
  return ref.watch(trackerDatasourceProvider).watchApplications();
}

/// Filtrar por estado
@riverpod
List<Application> filteredApplications(Ref ref, ApplicationStatus? status) {
  final all = ref.watch(applicationsProvider).asData?.value ?? [];
  if (status == null) return all;
  return all.where((a) => a.status == status).toList();
}

@Riverpod(keepAlive: true)
class TrackerNotifier extends _$TrackerNotifier {
  final Map<String, Timer> _timers = {};
  final Map<String, String> _pendingDeletions = {};

  @override
  Set<String> build() => {};

  Future<Either<Failure, void>> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    try {
      await ref
          .read(trackerDatasourceProvider)
          .updateStatus(applicationId, status);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  Future<void> deleteApplication(String id, String evaluationId) =>
      ref.read(trackerDatasourceProvider).deleteApplication(id, evaluationId);

  void stageDeletion(String appId, String evaluationId) {
    _pendingDeletions[appId] = evaluationId;
    state = <String>{...state, appId};

    _timers[appId]?.cancel();
    _timers[appId] = Timer(const Duration(seconds: 4), () async {
      _timers.remove(appId);
      final evalId = _pendingDeletions.remove(appId);
      if (evalId != null) {
        await deleteApplication(appId, evalId);
        state = state.where((id) => id != appId).toSet();
      }
    });
  }

  void cancelDeletion(String appId) {
    _timers[appId]?.cancel();
    _timers.remove(appId);
    _pendingDeletions.remove(appId);
    state = state.where((id) => id != appId).toSet();
  }
}
