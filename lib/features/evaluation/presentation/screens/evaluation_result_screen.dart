import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postula_ai/core/router/app_router.dart';
import 'package:postula_ai/features/ads/providers/ads_provider.dart';

import '../../../../core/constants/strings_es.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../coach/presentation/providers/coach_provider.dart';
import '../../../cv_generator/presentation/providers/cv_provider.dart';
import '../../domain/entities/job_evaluation.dart';
import '../providers/evaluation_provider.dart';

class EvaluationResultScreen extends ConsumerWidget {
  final String evaluationId;
  const EvaluationResultScreen({super.key, required this.evaluationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure ad is preloaded
    ref.read(interstitialAdServiceProvider);

    final evalAsync = ref.watch(evaluationByIdProvider(evaluationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsEs.resultadoTitulo),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: evalAsync.when(
        data: (eval) => _ResultBody(evaluation: eval),
        loading: () => const LoadingWidget(message: 'Cargando resultado...'),
        error: (e, _) => ErrorRetryWidget(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(evaluationByIdProvider(evaluationId)),
        ),
      ),
    );
  }
}

class _ResultBody extends ConsumerStatefulWidget {
  final JobEvaluation evaluation;
  const _ResultBody({required this.evaluation});

  @override
  ConsumerState<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends ConsumerState<_ResultBody> {
  @override
  void initState() {
    super.initState();
    debugPrint('[ADS] _ResultBody initState fired');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint(
          '[ADS] postFrameCallback firing, calling showInterstitialIfEligible',
        );
        ref.read(interstitialAdServiceProvider).showInterstitialIfEligible();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ScoreCard(evaluation: widget.evaluation),
              const SizedBox(height: 20),
              Text(
                widget.evaluation.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _ListSection(
                title: StringsEs.resultadoFortalezas,
                icon: Icons.thumb_up_outlined,
                color: const Color(0xFF0E9F6E),
                items: widget.evaluation.strengths,
              ),
              const SizedBox(height: 16),
              if (widget.evaluation.gaps.isNotEmpty) ...[
                _ListSection(
                  title: StringsEs.resultadoBrechas,
                  icon: Icons.info_outline,
                  color: const Color(0xFFFF8A00),
                  items: widget.evaluation.gaps,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              _CvButton(evaluation: widget.evaluation),
              const SizedBox(height: 12),
              _CoachButton(evaluation: widget.evaluation),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.evaluate),
                child: const Text('Evaluar otra oferta'),
              ),
            ],
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}

class _CvButton extends ConsumerWidget {
  final JobEvaluation evaluation;
  const _CvButton({required this.evaluation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvState = ref.watch(cvProvider(evaluation.id));

    if (cvState is AsyncLoading) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text(StringsEs.resultadoGenerarCV),
      );
    }

    final hasCv = cvState.asData?.value != null;
    return ElevatedButton.icon(
      onPressed: () => context.push('/cv/${evaluation.id}'),
      icon: Icon(hasCv ? Icons.description : Icons.description_outlined),
      label: Text(hasCv ? 'Ver CV generado' : StringsEs.resultadoGenerarCV),
    );
  }
}

class _CoachButton extends ConsumerWidget {
  final JobEvaluation evaluation;
  const _CoachButton({required this.evaluation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSession =
        ref.watch(coachProvider(evaluation.id)).asData?.value != null;
    return OutlinedButton.icon(
      onPressed: () => context.push('/coach/${evaluation.id}'),
      icon: Icon(hasSession ? Icons.school : Icons.school_outlined),
      label: Text(
        hasSession
            ? 'Ver preparación de entrevista'
            : StringsEs.resultadoPreparar,
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final JobEvaluation evaluation;
  const _ScoreCard({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final scoreColor = context.appColors.scoreColor(evaluation.score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${evaluation.jobTitle} · ${evaluation.company}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                evaluation.score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  '/5',
                  style: TextStyle(
                    fontSize: 20,
                    color: scoreColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              evaluation.recommendation.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            evaluation.recommendation.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ListSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
