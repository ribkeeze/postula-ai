import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/limits.dart';
import '../../../../core/constants/strings_es.dart';
import '../providers/subscription_provider.dart';

/// Pantalla de paywall — aparece cuando el usuario free llega a su límite diario.
///
/// Diseño deliberado:
/// - No es agresivo ni desesperado. Explica claramente qué pasó y qué puede hacer.
/// - El botón de "esperar a mañana" es visible — no hay dark patterns.
/// - Muestra los beneficios concretos, no promesas vagas.
class PaywallScreen extends ConsumerWidget {
  final PaywallTrigger trigger;
  final VoidCallback? onDismiss;

  /// true → usuario llegó al límite (muestra uso real + título de bloqueo)
  /// false → usuario abrió desde perfil voluntariamente
  final bool isLimitReached;

  const PaywallScreen({
    super.key,
    required this.trigger,
    required this.isLimitReached,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseProvider);
    final isLoading = purchaseState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PostulaAI Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
          tooltip: 'Cerrar',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono y título
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isLimitReached ? StringsEs.paywallTitulo : 'Mejorá tu plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              StringsEs.paywallSubtitulo,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),

            if (isLimitReached) ...[
              const SizedBox(height: 32),
              _LimitesGratis(),
            ],

            const SizedBox(height: 24),

            // Divider con "Premium incluye"
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Con Premium tenés',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // Beneficios Premium
            ...[
              StringsEs.paywallBeneficio1,
              StringsEs.paywallBeneficio2,
              StringsEs.paywallBeneficio3,
              StringsEs.paywallBeneficio4,
            ].map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF0E9F6E), size: 22),
                    const SizedBox(width: 12),
                    Text(b, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón principal
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: () => _purchase(context, ref),
                child: const Text(StringsEs.paywallBotonPremium),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.outline),
                ),
                child: const Text(StringsEs.paywallBotonEsperar),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _restore(context, ref),
                  child: const Text(StringsEs.paywallRestaurarCompra),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Nota legal mínima
            Center(
              child: Text(
                'Se renueva automáticamente. Cancelá cuando quieras\n'
                'desde la configuración de tu tienda de aplicaciones.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(purchaseProvider.notifier)
        .purchasePremium();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(StringsEs.suscripcionActivada)),
      );
      Navigator.of(context).pop(true); // pop con resultado positivo
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(purchaseProvider.notifier)
        .restorePurchases();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? StringsEs.suscripcionActivada
            : 'No encontramos compras anteriores.'),
      ),
    );

    if (success) Navigator.of(context).pop(true);
  }
}

class _LimitesGratis extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(dailyUsageProvider).asData?.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu uso de hoy',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          _UsageRow(
            label: 'Evaluaciones',
            used: usage?.evaluations ?? 0,
            limit: AppLimits.freeEvaluationsPerDay,
          ),
          const SizedBox(height: 6),
          _UsageRow(
            label: 'CVs',
            used: usage?.cvGenerated ?? 0,
            limit: AppLimits.freeCvPerDay,
          ),
          const SizedBox(height: 6),
          _UsageRow(
            label: 'Sesiones de coach',
            used: usage?.coachSessions ?? 0,
            limit: AppLimits.freeCoachPerDay,
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final int used;
  final int limit;

  const _UsageRow({
    required this.label,
    required this.used,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final isExhausted = used >= limit;
    final statusColor =
        isExhausted ? const Color(0xFFDC2626) : const Color(0xFF0E9F6E);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF78350F),
                ),
          ),
        ),
        Text(
          '$used de $limit usado${used == 1 ? '' : 's'} hoy',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight:
                    isExhausted ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ],
    );
  }
}

/// Trigger que causó el paywall — para personalizar el mensaje si se necesita en el futuro.
enum PaywallTrigger { evaluation, cvGeneration, coach }
