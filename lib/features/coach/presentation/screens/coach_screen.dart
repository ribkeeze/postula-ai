import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/strings_es.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/usage_gate.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/presentation/screens/paywall_screen.dart';
import '../providers/coach_provider.dart';

class CoachScreen extends ConsumerWidget {
  final String applicationId;
  const CoachScreen(
      {super.key, required this.applicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState =
        ref.watch(coachProvider(applicationId));
    final canCoach = ref.watch(canCoachProvider);

    return Scaffold(
      appBar:
          AppBar(title: const Text(StringsEs.coachTitulo)),
      body: sessionState.when(
        data: (session) {
          if (session == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined,
                      size: 64, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 16),
                  Text(StringsEs.coachSubtitulo,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge),
                  const SizedBox(height: 32),
                  UsageGate(
                    trigger: PaywallTrigger.coach,
                    canUse: canCoach,
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(coachProvider(applicationId)
                              .notifier)
                          .prepare(applicationId),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text(
                          'Preparar entrevista con IA'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const UsageChip(trigger: PaywallTrigger.coach),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Tips
              if (session.interviewTips.isNotEmpty) ...[
                Text(StringsEs.coachConsejos,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 10),
                ...session.interviewTips.map(
                  (tip) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 18,
                            color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(tip,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Preguntas
              Text(StringsEs.coachPreguntasSugeridas,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
              const SizedBox(height: 10),
              ...session.probableQuestions.map(
                (q) => _QuestionCard(question: q),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(
            message:
                'Preparando tu coach de entrevista...'),
        error: (e, _) => ErrorRetryWidget(
          message: friendlyError(e),
          onRetry: () => ref
              .read(coachProvider(applicationId).notifier)
              .prepare(applicationId),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final dynamic question;
  const _QuestionCard({required this.question});

  @override
  State<_QuestionCard> createState() =>
      _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeBadge(
                      type: widget.question.type as String),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.question.question as String,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Icon(_expanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Qué busca el entrevistador:',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                      const SizedBox(height: 4),
                      Text(widget.question.hint as String,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall),
                      const SizedBox(height: 10),
                      Text('Cómo encararlo:',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                      const SizedBox(height: 4),
                      Text(
                          widget.question.suggestedApproach
                              as String,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'tecnica' => ('Técnica', const Color(0xFF1A56DB)),
      'conductual' => (
          'Conductual',
          const Color(0xFF0E9F6E)
        ),
      'motivacional' => (
          'Motivación',
          const Color(0xFF7E3AF2)
        ),
      'trampa' => ('¡Ojo!', const Color(0xFFE02424)),
      _ => ('General', const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}
