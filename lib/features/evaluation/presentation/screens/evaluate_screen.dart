import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/strings_es.dart';
import '../../../../core/router/app_router.dart';
import '../providers/evaluation_provider.dart';

class EvaluateScreen extends ConsumerStatefulWidget {
  const EvaluateScreen({super.key});

  @override
  ConsumerState<EvaluateScreen> createState() =>
      _EvaluateScreenState();
}

class _EvaluateScreenState
    extends ConsumerState<EvaluateScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    if (!_formKey.currentState!.validate()) return;

    final text = _controller.text.trim();
    final result = await ref
        .read(evaluationProvider.notifier)
        .evaluate(text);

    if (!mounted) return;

    result.fold(
      (failure) => _showError(failure.message),
      (evaluation) {
        debugPrint('Navigating to id: ${evaluation.id}');
        context.push(
            '${AppRoutes.evaluate}/result?id=${evaluation.id}');
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 16)),
        backgroundColor:
            Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evaluationProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsEs.evaluadorTitulo),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              StringsEs.evaluadorSubtitulo,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              enabled: !isLoading,
              maxLines: 12,
              minLines: 8,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: StringsEs.evaluadorPlaceholder,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return StringsEs.errorOfertaVacia;
                }
                if (value.trim().length < 100) {
                  return StringsEs.errorOfertaMuyCorta;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            if (isLoading)
              _LoadingCard()
            else
              ElevatedButton(
                onPressed: _evaluate,
                child: const Text(StringsEs.evaluadorBoton),
              ),
            const SizedBox(height: 16),
            _HowToTip(),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            StringsEs.evaluadorCargando,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            StringsEs.evaluadorCargandoDetalle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HowToTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Color(0xFF15803D), size: 20),
              const SizedBox(width: 8),
              Text(
                '¿Cómo conseguir el texto?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                      color: const Color(0xFF15803D),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'En el aviso de trabajo, seleccioná todo el texto '
            '(manteniendo presionado en el celular) y copialo. '
            'También podés copiar desde LinkedIn, Bumeran, ZonaJobs, etc.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: const Color(0xFF166534),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
