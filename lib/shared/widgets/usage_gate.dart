import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscription/presentation/providers/subscription_provider.dart';
import '../../features/subscription/presentation/screens/paywall_screen.dart';

/// Widget que controla acceso a features con límite diario.
///
/// Uso:
/// ```dart
/// UsageGate(
///   trigger: PaywallTrigger.evaluation,
///   canUse: ref.watch(canEvaluateProvider),
///   child: ElevatedButton(
///     onPressed: _evaluate,
///     child: Text('Evaluar oferta'),
///   ),
/// )
/// ```
///
/// Si [canUse] es false, el widget no deshabilita el botón (eso sería confuso
/// para usuarios mayores) sino que al presionar muestra el PaywallScreen.
class UsageGate extends ConsumerWidget {
  final PaywallTrigger trigger;
  final bool canUse;
  final Widget child;

  const UsageGate({
    super.key,
    required this.trigger,
    required this.canUse,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (canUse) return child;

    // Interceptar el tap para mostrar el paywall en lugar de la acción
    return GestureDetector(
      onTap: () => _showPaywall(context),
      behavior: HitTestBehavior.opaque,
      child: IgnorePointer(child: child),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => PaywallScreen(
          trigger: trigger,
          isLimitReached: true,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

/// Chip pequeño que muestra el uso restante del día.
/// Se muestra cerca de los botones de acción limitada.
class UsageChip extends ConsumerWidget {
  final PaywallTrigger trigger;

  const UsageChip({super.key, required this.trigger});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider).asData?.value;

    if (sub?.isPremium == true) {
      return const _StatusChip(
        label: 'Sin límite · Premium',
        color: Color(0xFF0E9F6E),
        icon: Icons.workspace_premium_rounded,
      );
    }

    final usage = ref.watch(dailyUsageProvider).asData?.value;
    if (usage == null) return const SizedBox.shrink();

    return switch (trigger) {
      PaywallTrigger.evaluation => _buildCounter(
          context,
          used: usage.evaluations,
          limit: 3,
          label: 'evaluaciones',
        ),
      PaywallTrigger.cvGeneration => _buildCounter(
          context,
          used: usage.cvGenerated,
          limit: 1,
          label: 'CV',
        ),
      PaywallTrigger.coach => _buildCounter(
          context,
          used: usage.coachSessions,
          limit: 3,
          label: 'coach',
        ),
    };
  }

  Widget _buildCounter(
    BuildContext context, {
    required int used,
    required int limit,
    required String label,
  }) {
    final remaining = limit - used;
    final isExhausted = remaining <= 0;

    return _StatusChip(
      label: isExhausted
          ? 'Límite alcanzado · $label'
          : '$remaining $label restante${remaining == 1 ? '' : 's'} hoy',
      color: isExhausted ? const Color(0xFFE02424) : const Color(0xFF6B7280),
      icon: isExhausted ? Icons.lock_outline : Icons.info_outline,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
