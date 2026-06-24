# Convenciones de código — PostulaAI

## Nomenclatura

| Tipo | Convención | Ejemplo |
|------|-----------|---------|
| Clases | PascalCase | `UserProfile`, `EvaluationResult` |
| Variables y métodos | camelCase | `currentUser`, `evaluateJob()` |
| Constantes | camelCase o SCREAMING | `AppLimits.freeEvaluationsPerDay` |
| Archivos | snake_case | `user_profile.dart`, `evaluate_screen.dart` |
| Providers | camelCase + sufijo Provider/Notifier | `subscriptionProvider`, `EvaluationNotifier` |

## Estructura de un feature

Todo feature tiene exactamente estas capas:
```
feature/
  data/
    datasources/   → Solo interacción con Firebase/APIs. Sin lógica de negocio.
    models/        → Solo si el DTO difiere significativamente de la entidad
    repositories/  → Implementación concreta. Convierte excepciones a Failures.
  domain/
    entities/      → Objetos puros. Freezed. Sin dependencias de Flutter ni Firebase.
    repositories/  → Interface. Solo define el contrato.
    usecases/      → Una clase por caso de uso. Método call() que retorna Either<>.
  presentation/
    providers/     → Riverpod. Lee de repositorios via usecases. Nunca accede a datasources.
    screens/       → UI. Lee providers. Delega acciones a notifiers.
    widgets/       → Widgets reutilizables dentro del feature.
```

## Manejo de errores

```dart
// ✅ Correcto — Failure en domain, Either en repositorio
Future<Either<Failure, UserProfile>> getProfile(String userId) async {
  try {
    final profile = await _datasource.getProfile(userId);
    if (profile == null) return const Left(NotFoundFailure());
    return Right(profile);
  } catch (_) {
    return const Left(ServerFailure());
  }
}

// ❌ Incorrecto — excepción raw llegando a la UI
Future<UserProfile> getProfile(String userId) async {
  return await _datasource.getProfile(userId); // puede tirar excepciones
}
```

## Providers

```dart
// ✅ Correcto — usando @riverpod annotation
@riverpod
class EvaluationNotifier extends _$EvaluationNotifier {
  @override
  AsyncValue<JobEvaluation?> build() => const AsyncValue.data(null);
  // ...
}

// ❌ Incorrecto — StateNotifierProvider manual (patrón viejo)
final evaluationProvider = StateNotifierProvider<...>((ref) => ...);
```

## Accesibilidad — checklist antes de cada PR

- [ ] Fuente mínima 16sp en texto de cuerpo
- [ ] Touch targets mínimo 48x48dp (especialmente botones)
- [ ] Labels en íconos sin texto (`Semantics` o `Tooltip`)
- [ ] No hardcodear colores — usar `Theme.of(context).colorScheme.xxx`
- [ ] Testeado con zoom del sistema al 150%

## Strings

**Nunca** escribir strings de UI en los widgets directamente:

```dart
// ✅ Correcto
Text(StringsEs.evaluadorTitulo)

// ❌ Incorrecto
Text('Evaluar oferta')
```

## Imports

```dart
// ✅ Correcto — package import
import 'package:postula_ai/features/evaluation/domain/entities/job_evaluation.dart';

// ❌ Incorrecto — relative import entre features
import '../../../evaluation/domain/entities/job_evaluation.dart';
```

Imports relativos están permitidos SOLO dentro del mismo feature.
