import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/coach_remote_datasource.dart';
import '../../domain/entities/coach_session.dart';

part 'coach_provider.g.dart';

@riverpod
CoachRemoteDatasourceImpl coachDatasource(Ref ref) =>
    CoachRemoteDatasourceImpl();

@Riverpod(keepAlive: true)
class CoachNotifier extends _$CoachNotifier {
  bool _isPreparing = false;

  @override
  AsyncValue<CoachSession?> build(String evaluationId) {
    _loadCached(evaluationId);
    return const AsyncValue.data(null);
  }

  Future<void> _loadCached(String evaluationId) async {
    try {
      final cached = await ref
          .read(coachDatasourceProvider)
          .getCachedCoach(evaluationId);
      final current = state;
      if (!_isPreparing &&
          current is AsyncData &&
          current.value == null &&
          cached != null) {
        state = AsyncValue.data(cached);
      }
    } catch (_) {}
  }

  Future<Either<Failure, CoachSession>> prepare(String evaluationId) async {
    _isPreparing = true;
    state = const AsyncValue.loading();

    try {
      final fn = FirebaseFunctions.instanceFor(region: 'southamerica-east1');
      final result = await fn.httpsCallable('prepareCoach').call({
        'evaluationId': evaluationId,
      });

      final rawData = Map<String, dynamic>.from(result.data as Map);

      // Limpiar tipos anidados via JSON round-trip
      final cleanData = jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;

      CoachSession session;
      try {
        session = CoachSession.fromJson({
          ...cleanData,
          'evaluationId': evaluationId,
        });
      } catch (parseError) {
        debugPrint('Coach fromJson error: $parseError');
        state = AsyncValue.error(
          const ServerFailure('Error procesando la sesión. Intentá de nuevo.'),
          StackTrace.current,
        );
        return const Left(ServerFailure('Error procesando la sesión.'));
      }

      state = AsyncValue.data(session);
      return Right(session);
    } on Exception catch (e) {
      debugPrint('Coach exception: $e');
      final msg = e.toString();
      final Failure f;
      if (msg.contains('resource-exhausted')) {
        f = const LimitExceededFailure();
      } else if (msg.contains('unauthenticated')) {
        f = const AuthFailure();
      } else if (msg.contains('not-found')) {
        f = const NotFoundFailure();
      } else {
        f = const ServerFailure();
      }
      state = AsyncValue.error(f, StackTrace.current);
      return Left(f);
    } finally {
      _isPreparing = false;
    }
  }
}
