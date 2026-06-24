import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/strings_es.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../evaluation/domain/entities/job_evaluation.dart';
import '../../domain/entities/application.dart';
import '../providers/tracker_provider.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() =>
      _TrackerScreenState();
}

class _TrackerScreenState
    extends ConsumerState<TrackerScreen> {
  ApplicationStatus? _filter;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void deactivate() {
    _scaffoldMessenger?.hideCurrentSnackBar();
    _scaffoldMessenger = null;
    super.deactivate();
  }

  void _onDelete(Application app) {
    ref.read(trackerProvider.notifier).stageDeletion(app.id, app.evaluationId);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${app.jobTitle} eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () =>
              ref.read(trackerProvider.notifier).cancelDeletion(app.id),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(applicationsProvider);
    final pendingIds = ref.watch(trackerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsEs.trackerTitulo),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: Column(
        children: [
          // Filtros de estado
          _StatusFilterBar(
            selected: _filter,
            onSelected: (s) => setState(() => _filter = s),
          ),

          Expanded(
            child: appsAsync.when(
              data: (apps) {
                final visible = apps
                    .where((a) => !pendingIds.contains(a.id))
                    .toList();
                final filtered = _filter == null
                    ? visible
                    : visible
                        .where((a) => a.status == _filter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        visible.isEmpty
                            ? StringsEs.trackerVacio
                            : 'No hay postulaciones con este estado.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 0),
                  itemBuilder: (_, i) => Dismissible(
                    key: Key(filtered[i].id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        _onDelete(filtered[i]),
                    background: Container(
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      padding:
                          const EdgeInsets.only(right: 20),
                      child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28),
                    ),
                    child:
                        _ApplicationCard(app: filtered[i]),
                  ),
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorRetryWidget(
                message: friendlyError(e),
                onRetry: () =>
                    ref.invalidate(applicationsProvider),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _StatusFilterBar extends ConsumerWidget {
  final ApplicationStatus? selected;
  final Function(ApplicationStatus?) onSelected;

  const _StatusFilterBar(
      {required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps =
        ref.watch(applicationsProvider).asData?.value ??
            const [];

    int countFor(ApplicationStatus? status) =>
        status == null
            ? apps.length
            : apps.where((a) => a.status == status).length;

    final options = [
      (null, StringsEs.trackerFiltroTodas),
      (
        ApplicationStatus.interested,
        StringsEs.trackerFiltroInteresado
      ),
      (
        ApplicationStatus.applied,
        StringsEs.trackerFiltroAplicado
      ),
      (
        ApplicationStatus.interview,
        StringsEs.trackerFiltroEntrevista
      ),
      (
        ApplicationStatus.offer,
        StringsEs.trackerFiltroOferta
      ),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        children: options.map((o) {
          final isSelected = selected == o.$1;
          final count = countFor(o.$1);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(o.$2),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withAlpha(60)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(30),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimary
                            : Theme.of(context)
                                .colorScheme
                                .primary,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(o.$1),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  final Application app;
  const _ApplicationCard({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreColor =
        context.appColors.scoreColor(app.score);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
            '/evaluate/result?id=${app.evaluationId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    app.score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(app.jobTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(app.company,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd/MM/yyyy')
                          .format(app.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // Status chip + menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusMenu(app: app),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMenu extends ConsumerWidget {
  final Application app;
  const _StatusMenu({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ApplicationStatus>(
      initialValue: app.status,
      onSelected: (status) {
        ref
            .read(trackerProvider.notifier)
            .updateStatus(app.id, status);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text(StringsEs.trackerEstadoActualizado),
          ),
        );
      },
      child: Chip(
        label: Text(app.status.label,
            style: const TextStyle(fontSize: 12)),
        padding: EdgeInsets.zero,
        materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap,
      ),
      itemBuilder: (_) => ApplicationStatus.values
          .map((s) =>
              PopupMenuItem(value: s, child: Text(s.label)))
          .toList(),
    );
  }
}
