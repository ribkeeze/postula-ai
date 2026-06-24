/// Límites del plan gratuito.
/// Centralizado acá para que cambiar un límite no requiera tocar 5 archivos.
abstract class AppLimits {
  static const int freeEvaluationsPerDay = 3;
  static const int freeCvPerDay = 1;
  static const int freeCoachPerDay = 3;
}
