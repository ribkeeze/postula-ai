import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/cv_remote_datasource.dart';
import '../../domain/entities/generated_cv.dart';

part 'cv_provider.g.dart';

@riverpod
CvRemoteDatasourceImpl cvDatasource(Ref ref) => CvRemoteDatasourceImpl();

@Riverpod(keepAlive: true)
class CvNotifier extends _$CvNotifier {
  bool _isGenerating = false;

  @override
  AsyncValue<GeneratedCv?> build(String evaluationId) {
    _loadCached(evaluationId);
    return const AsyncValue.data(null);
  }

  Future<void> _loadCached(String evaluationId) async {
    try {
      final cached = await ref
          .read(cvDatasourceProvider)
          .getCachedCv(evaluationId);
      final current = state;
      if (!_isGenerating &&
          current is AsyncData &&
          current.value == null &&
          cached != null) {
        state = AsyncValue.data(cached);
      }
    } catch (_) {}
  }

  Future<Either<Failure, GeneratedCv>> generate(String evaluationId) async {
    _isGenerating = true;
    state = const AsyncValue.loading();

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      );
      final result = await functions.httpsCallable('generateCv').call({
        'evaluationId': evaluationId,
      });

      final rawData = Map<String, dynamic>.from(result.data as Map);

      // Limpiar tipos anidados via JSON round-trip
      final cleanData = jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;

      GeneratedCv cv;
      try {
        cv = GeneratedCv.fromJson({...cleanData, 'evaluationId': evaluationId});
      } catch (parseError) {
        debugPrint('CV fromJson error: $parseError');
        state = AsyncValue.error(
          const ServerFailure('Error procesando el CV. Intentá de nuevo.'),
          StackTrace.current,
        );
        return const Left(ServerFailure('Error procesando el CV.'));
      }

      state = AsyncValue.data(cv);
      return Right(cv);
    } on Exception catch (e) {
      debugPrint('CV generate exception: $e');
      final msg = e.toString();
      final Failure f;
      if (msg.contains('resource-exhausted') || msg.contains('DAILY_LIMIT')) {
        f = const LimitExceededFailure();
      } else if (msg.contains('unavailable') || msg.contains('AI_BUSY')) {
        f = const ServerFailure('El servicio de IA está ocupado. Intentá en unos segundos.');
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
      _isGenerating = false;
    }
  }
}
