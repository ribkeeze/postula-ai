import 'package:equatable/equatable.dart';

/// Jerarquía de errores de dominio.
/// Se usan en Either<Failure, T> — nunca exponer excepciones raw a la UI.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Error del servidor o de la Cloud Function
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Algo salió mal. Intentá de nuevo.']);
}

/// Sin conexión a internet
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión. Verificá tu internet.']);
}

/// Recurso no encontrado en Firestore
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontramos los datos. Intentá de nuevo.']);
}

/// Usuario alcanzó su límite diario del plan gratuito
class LimitExceededFailure extends Failure {
  const LimitExceededFailure([
    super.message = 'Alcanzaste tu límite diario. Volvé mañana o activá Premium.',
  ]);
}

/// Error de autenticación
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Tu sesión expiró. Volvé a iniciar sesión.']);
}

/// Error de caché / almacenamiento local
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Algo salió mal. Intentá de nuevo.']);
}

/// Datos inválidos (validación)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Converts any caught exception to a user-friendly Spanish message.
String friendlyError(Object e) {
  if (e is Failure) return e.message;
  final msg = e.toString().toLowerCase();
  if (msg.contains('resource-exhausted') || msg.contains('limitexceeded')) {
    return 'Alcanzaste tu límite diario. Volvé mañana o activá Premium.';
  }
  if (msg.contains('unauthenticated') || msg.contains('authfailure')) {
    return 'Tu sesión expiró. Volvé a iniciar sesión.';
  }
  if (msg.contains('not-found') || msg.contains('notfound')) {
    return 'No encontramos los datos. Intentá de nuevo.';
  }
  if (msg.contains('network') || msg.contains('socketexception') ||
      msg.contains('connection refused')) {
    return 'Sin conexión. Verificá tu internet.';
  }
  return 'Algo salió mal. Intentá de nuevo.';
}
