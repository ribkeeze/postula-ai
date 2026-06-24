import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/strings_es.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../domain/entities/user_profile.dart';
import '../../presentation/providers/profile_provider.dart';
import '../widgets/work_reference_dialog.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/presentation/screens/paywall_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends ConsumerState<ProfileScreen> {
  final _linkedInCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _commuteCtrl = TextEditingController();
  final _excludedIndustryCtrl = TextEditingController();
  final _excludedCompanyCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  Set<WorkModality> _preferredModalities = {};
  String _salaryCurrency = 'ARS';
  bool _salaryNegotiable = true;
  bool _hasOwnVehicle = false;
  List<String> _excludedIndustries = [];
  List<String> _excludedCompanies = [];
  List<Certification> _certifications = [];
  List<WorkExperience> _experiences = [];
  List<Education> _educations = [];
  List<Language> _languages = [];
  List<String> _skills = [];

  bool _initialized = false;
  bool _saving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initFromProfile());
  }

  @override
  void dispose() {
    _linkedInCtrl.dispose();
    _githubCtrl.dispose();
    _portfolioCtrl.dispose();
    _salaryCtrl.dispose();
    _commuteCtrl.dispose();
    _excludedIndustryCtrl.dispose();
    _excludedCompanyCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    final profile =
        ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      if (mounted) setState(() => _initialized = true);
      return;
    }
    if (mounted) {
      setState(() {
        _initialized = true;
        _applyProfile(profile);
      });
    }
  }

  void _applyProfile(UserProfile profile) {
    final info = profile.personalInfo;
    _linkedInCtrl.text = info.linkedInUrl ?? '';
    _githubCtrl.text = info.githubUrl ?? '';
    _portfolioCtrl.text = info.portfolioUrl ?? '';
    _salaryCtrl.text =
        info.expectedSalaryAmount?.toStringAsFixed(0) ?? '';
    _salaryCurrency = info.expectedSalaryCurrency;
    _salaryNegotiable = info.salaryNegotiable;
    _hasOwnVehicle = info.hasOwnVehicle;
    _commuteCtrl.text = info.maxCommuteKm?.toString() ?? '';
    _excludedIndustries =
        List.from(info.excludedIndustries);
    _excludedCompanies = List.from(info.excludedCompanies);
    _preferredModalities =
        Set.from(info.preferredModalities);
    _certifications = List.from(profile.certifications);
    _experiences = List.from(profile.workExperience);
    _educations = List.from(profile.education);
    _languages = List.from(profile.languages);
    _skills = List.from(profile.skills);
  }

  void _cancelEdit() {
    final profile =
        ref.read(userProfileProvider).asData?.value;
    setState(() {
      _isEditing = false;
      if (profile != null) _applyProfile(profile);
    });
  }

  Future<void> _save() async {
    final existing =
        ref.read(userProfileProvider).asData?.value;
    if (existing == null) return;

    final updated = existing.copyWith(
      personalInfo: existing.personalInfo.copyWith(
        linkedInUrl: _linkedInCtrl.text.trim().isEmpty
            ? null
            : _linkedInCtrl.text.trim(),
        githubUrl: _githubCtrl.text.trim().isEmpty
            ? null
            : _githubCtrl.text.trim(),
        portfolioUrl: _portfolioCtrl.text.trim().isEmpty
            ? null
            : _portfolioCtrl.text.trim(),
        expectedSalaryAmount:
            _salaryCtrl.text.trim().isEmpty
                ? null
                : double.tryParse(_salaryCtrl.text.trim()),
        expectedSalaryCurrency: _salaryCurrency,
        salaryNegotiable: _salaryNegotiable,
        hasOwnVehicle: _hasOwnVehicle,
        maxCommuteKm: _commuteCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_commuteCtrl.text.trim()),
        excludedIndustries: _excludedIndustries,
        excludedCompanies: _excludedCompanies,
        preferredModalities: _preferredModalities.toList(),
      ),
      certifications: _certifications,
      workExperience: _experiences,
      education: _educations,
      languages: _languages,
      skills: _skills,
      updatedAt: existing.updatedAt,
    );

    if (jsonEncode(existing.toJson()) == jsonEncode(updated.toJson())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar')),
      );
      return;
    }

    setState(() => _saving = true);

    final result = await ref
        .read(profileProvider.notifier)
        .save(updated.copyWith(updatedAt: DateTime.now()));
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor:
              Theme.of(context).colorScheme.error,
        ),
      ),
      (_) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsEs.perfilTitulo),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _cancelEdit,
              child: const Text('Cancelar'),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Cerrar sesión',
              onPressed: () =>
                  ref.read(authProvider.notifier).signOut(),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
                child: Text('No hay perfil guardado'));
          }
          if (!_initialized) {
            return const Center(
                child: CircularProgressIndicator());
          }

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              subAsync.when(
                data: (sub) =>
                    _PlanBadge(isPremium: sub.isPremium),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                ..._buildEditSections(context, profile)
              else
                ..._buildReadSections(context, profile),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorRetryWidget(
          message: friendlyError(e),
          onRetry: () =>
              ref.invalidate(userProfileProvider),
        ),
      ),
    );
  }

  // ── Read mode ────────────────────────────────────────────────────────────────

  List<Widget> _buildReadSections(
      BuildContext context, UserProfile profile) {
    final info = profile.personalInfo;
    final sections = <Widget>[];

    void add(Widget card) {
      sections.add(card);
      sections.add(const SizedBox(height: 12));
    }

    // ─ 1. Datos de contacto ────────────────────────────────────────────────
    {
      final locParts = <String>[info.city];
      if (info.provincia?.isNotEmpty == true)
        locParts.add(info.provincia!);
      if (info.postalCode?.isNotEmpty == true)
        locParts.add('CP ${info.postalCode}');
      locParts.add(info.country);

      add(_SectionCard(
        title: 'Datos de contacto',
        icon: Icons.person_outline,
        children: [
          _InfoRow('Nombre', info.fullName),
          _InfoRow('Email', info.email),
          if (info.phone?.isNotEmpty == true)
            _InfoRow('Teléfono', info.phone!),
          _InfoRow('Ubicación', locParts.join(', ')),
          if (info.linkedInUrl?.isNotEmpty == true)
            _LinkInfoRow('LinkedIn', info.linkedInUrl!),
          if (info.githubUrl?.isNotEmpty == true)
            _LinkInfoRow('GitHub', info.githubUrl!),
          if (info.portfolioUrl?.isNotEmpty == true)
            _LinkInfoRow('Portfolio', info.portfolioUrl!),
        ],
      ));
    }

    // ─ 2. Experiencia laboral ──────────────────────────────────────────────
    if (profile.workExperience.isNotEmpty) {
      add(_SectionCard(
        title: StringsEs.perfilExperiencia,
        icon: Icons.work_outline,
        children: [
          for (final e in profile.workExperience)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.position,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600)),
                  Text(
                    '${e.company}  ·  ${e.startDate} → '
                    '${e.isCurrent ? "Actual" : (e.endDate ?? "")}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  if (e.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(e.description!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall),
                  ],
                  if (e.references.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${e.references.length} referencia'
                        '${e.references.length > 1 ? "s" : ""}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ));
    }

    // ─ 3. Proyectos destacados ─────────────────────────────────────────────
    if (profile.projects.isNotEmpty) {
      add(_SectionCard(
        title: 'Proyectos destacados',
        icon: Icons.rocket_launch_outlined,
        children: [
          for (final p in profile.projects)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600)),
                  if (p.context?.isNotEmpty == true)
                    Text(p.context!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                  if (p.technologies.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: p.technologies
                          .map((t) => Chip(
                                label: Text(t,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall),
                                materialTapTargetSize:
                                    MaterialTapTargetSize
                                        .shrinkWrap,
                                visualDensity:
                                    VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  if (p.url?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    _LinkInfoRow('URL', p.url!),
                  ],
                ],
              ),
            ),
        ],
      ));
    }

    // ─ 4. Educación ───────────────────────────────────────────────────────
    if (profile.education.isNotEmpty) {
      add(_SectionCard(
        title: StringsEs.perfilEducacion,
        icon: Icons.school_outlined,
        children: [
          for (final e in profile.education)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.degree,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600)),
                  if (e.field.isNotEmpty &&
                      e.field != 'General')
                    Text(e.field,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                  Text(
                    '${e.institution}  ·  ${e.startYear} → '
                    '${e.isOngoing ? "En curso" : (e.endYear ?? "")}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ));
    }

    // ─ 5. Certificaciones ─────────────────────────────────────────────────
    if (profile.certifications.isNotEmpty) {
      add(_SectionCard(
        title: 'Certificaciones',
        icon: Icons.verified_outlined,
        children: [
          for (final c in profile.certifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600)),
                  Text(
                    '${c.issuer}  ·  ${c.year}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  if (c.url?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    _LinkInfoRow('URL', c.url!),
                  ],
                ],
              ),
            ),
        ],
      ));
    }

    // ─ 6. Habilidades ─────────────────────────────────────────────────────
    if (profile.skills.isNotEmpty) {
      add(_SectionCard(
        title: StringsEs.perfilHabilidades,
        icon: Icons.star_outline,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.skills
                .map((s) => Chip(label: Text(s)))
                .toList(),
          ),
        ],
      ));
    }

    // ─ 7. Idiomas ─────────────────────────────────────────────────────────
    if (profile.languages.isNotEmpty) {
      add(_SectionCard(
        title: 'Idiomas',
        icon: Icons.language_outlined,
        children: profile.languages
            .map((l) => _InfoRow(l.name, l.level.label))
            .toList(),
      ));
    }

    // ─ 8. Preferencias laborales ──────────────────────────────────────────
    final hasPrefs = info.preferredModalities.isNotEmpty ||
        info.expectedSalaryAmount != null ||
        info.hasOwnVehicle ||
        info.maxCommuteKm != null ||
        info.excludedIndustries.isNotEmpty ||
        info.excludedCompanies.isNotEmpty;

    if (hasPrefs) {
      add(_SectionCard(
        title: 'Preferencias laborales',
        icon: Icons.tune_outlined,
        children: [
          if (info.preferredModalities.isNotEmpty) ...[
            Text('Modalidad',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    )),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: info.preferredModalities
                  .map((m) => Chip(
                        label: Text(m.label),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (info.expectedSalaryAmount != null)
            _InfoRow(
              'Pretensión',
              '${info.expectedSalaryAmount!.toStringAsFixed(0)} '
              '${info.expectedSalaryCurrency}'
              '${info.salaryNegotiable ? " (negociable)" : ""}',
            ),
          _InfoRow(
              'Vehículo', info.hasOwnVehicle ? 'Sí' : 'No'),
          if (info.maxCommuteKm != null)
            _InfoRow(
                'Distancia máx.', '${info.maxCommuteKm} km'),
          if (info.excludedIndustries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Industrias a evitar',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    )),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: info.excludedIndustries
                  .map((s) => Chip(
                        label: Text(s),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          if (info.excludedCompanies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Empresas a evitar',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    )),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: info.excludedCompanies
                  .map((s) => Chip(
                        label: Text(s),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ],
      ));
    }

    sections.addAll([
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () => context.push('/profile/edit'),
        child: const Text('Editar perfil'),
      ),
    ]);

    return sections;
  }

  // ── Edit mode ────────────────────────────────────────────────────────────────

  List<Widget> _buildEditSections(
      BuildContext context, UserProfile profile) {
    final showCommute = _preferredModalities
            .contains(WorkModality.hybrid) ||
        _preferredModalities.contains(WorkModality.onsite);

    return [
      _SectionCard(
        title: 'Datos de contacto',
        icon: Icons.person_outline,
        children: [
          TextField(
            controller: _linkedInCtrl,
            decoration: const InputDecoration(
              labelText: 'LinkedIn URL',
              hintText: 'https://linkedin.com/in/tu-perfil',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _githubCtrl,
            decoration: const InputDecoration(
              labelText: 'GitHub URL',
              hintText: 'https://github.com/tu-usuario',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _portfolioCtrl,
            decoration: const InputDecoration(
              labelText: 'Portfolio / Web personal',
              hintText: 'https://tu-portfolio.com',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar datos básicos'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: StringsEs.perfilExperiencia,
        icon: Icons.work_outline,
        children: [
          ..._experiences.map((e) => _ExperienceTile(
                exp: e,
                onEdit: (updated) => setState(() {
                  final idx = _experiences
                      .indexWhere((x) => x.id == e.id);
                  if (idx != -1)
                    _experiences[idx] = updated;
                }),
                onDelete: () => setState(() => _experiences
                    .removeWhere((x) => x.id == e.id)),
              )),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _ExperienceDialog(
                onSave: (exp) =>
                    setState(() => _experiences.add(exp)),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar experiencia'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'Preferencias laborales',
        icon: Icons.tune_outlined,
        children: [
          Text('Modalidad de trabajo',
              style:
                  Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: WorkModality.values.map((m) {
              final isSelected =
                  _preferredModalities.contains(m);
              return FilterChip(
                label: Text(m.label),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  if (isSelected) {
                    _preferredModalities.remove(m);
                  } else {
                    _preferredModalities.add(m);
                  }
                }),
              );
            }).toList(),
          ),
          if (showCommute) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _commuteCtrl,
              decoration: const InputDecoration(
                  labelText:
                      'Distancia máxima de viaje (km)'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Tengo vehículo propio'),
            value: _hasOwnVehicle,
            onChanged: (v) =>
                setState(() => _hasOwnVehicle = v),
          ),
          const SizedBox(height: 8),
          Text('Pretensión salarial',
              style:
                  Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Moneda',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _salaryCurrency,
                      isDense: true,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'ARS',
                            child: Text('ARS')),
                        DropdownMenuItem(
                            value: 'USD',
                            child: Text('USD')),
                      ],
                      onChanged: (v) {
                        if (v != null)
                          setState(
                              () => _salaryCurrency = v);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _salaryCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Monto'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Negociable'),
            value: _salaryNegotiable,
            onChanged: (v) =>
                setState(() => _salaryNegotiable = v),
          ),
          const SizedBox(height: 8),
          Text('Industrias a evitar',
              style:
                  Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          _ChipListEditor(
            items: _excludedIndustries,
            controller: _excludedIndustryCtrl,
            hint: 'ej: Tabaco, Juego...',
            onAdd: (v) =>
                setState(() => _excludedIndustries.add(v)),
            onDelete: (v) => setState(
                () => _excludedIndustries.remove(v)),
          ),
          const SizedBox(height: 10),
          Text('Empresas a evitar',
              style:
                  Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          _ChipListEditor(
            items: _excludedCompanies,
            controller: _excludedCompanyCtrl,
            hint: 'ej: Empresa XYZ...',
            onAdd: (v) =>
                setState(() => _excludedCompanies.add(v)),
            onDelete: (v) => setState(
                () => _excludedCompanies.remove(v)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: StringsEs.perfilEducacion,
        icon: Icons.school_outlined,
        children: [
          ..._educations.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(e.degree),
                subtitle: Text(
                    '${e.institution} · ${e.startYear}–${e.isOngoing ? "En curso" : (e.endYear ?? "")}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18),
                      tooltip: 'Editar',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _EducationDialog(
                          initial: e,
                          onSave: (updated) => setState(() {
                            final idx = _educations
                                .indexWhere((x) => x.id == e.id);
                            if (idx != -1)
                              _educations[idx] = updated;
                          }),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18),
                      tooltip: 'Eliminar',
                      onPressed: () => setState(() =>
                          _educations
                              .removeWhere((x) => x.id == e.id)),
                    ),
                  ],
                ),
              )),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _EducationDialog(
                onSave: (edu) =>
                    setState(() => _educations.add(edu)),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar educación'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'Certificaciones',
        icon: Icons.verified_outlined,
        children: [
          ..._certifications.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(c.name),
                subtitle: Text('${c.issuer} · ${c.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18),
                      tooltip: 'Editar',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _CertDialog(
                          initial: c,
                          onSave: (updated) => setState(() {
                            final idx = _certifications
                                .indexWhere((x) => x.id == c.id);
                            if (idx != -1)
                              _certifications[idx] = updated;
                          }),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18),
                      tooltip: 'Eliminar',
                      onPressed: () => setState(() =>
                          _certifications
                              .removeWhere((x) => x.id == c.id)),
                    ),
                  ],
                ),
              )),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _CertDialog(
                onSave: (cert) =>
                    setState(() => _certifications.add(cert)),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar certificación'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'Idiomas',
        icon: Icons.language_outlined,
        children: [
          ..._languages.map((l) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l.name),
                subtitle: Text(l.level.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18),
                      tooltip: 'Editar',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _LanguageDialog(
                          initial: l,
                          onSave: (updated) => setState(() {
                            final idx = _languages.indexWhere(
                                (x) => x.name == l.name);
                            if (idx != -1)
                              _languages[idx] = updated;
                          }),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18),
                      tooltip: 'Eliminar',
                      onPressed: () => setState(() =>
                          _languages
                              .removeWhere((x) => x.name == l.name)),
                    ),
                  ],
                ),
              )),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _LanguageDialog(
                onSave: (lang) =>
                    setState(() => _languages.add(lang)),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar idioma'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: StringsEs.perfilHabilidades,
        icon: Icons.star_outline,
        children: [
          if (_skills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _skills
                  .map((s) => Chip(
                        label: Text(s),
                        onDeleted: () => setState(
                            () => _skills.remove(s)),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Agregar habilidad...',
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    final t = v.trim();
                    if (t.isNotEmpty &&
                        !_skills.contains(t)) {
                      setState(() => _skills.add(t));
                      _skillCtrl.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _skillCtrl,
                builder: (_, val, __) =>
                    IconButton.outlined(
                  onPressed: val.text.trim().isEmpty
                      ? null
                      : () {
                          final t = val.text.trim();
                          if (t.isNotEmpty &&
                              !_skills.contains(t)) {
                            setState(() => _skills.add(t));
                            _skillCtrl.clear();
                          }
                        },
                  icon: const Icon(Icons.add, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2),
              )
            : const Text('Guardar cambios'),
      ),
    ];
  }
}

// ── Section card (always expanded, no ExpansionTile) ─────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                          fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── Shared display helpers ────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final bool isPremium;
  const _PlanBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color(0xFFFFFBEB)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPremium
              ? const Color(0xFFFCD34D)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium
                ? Icons.workspace_premium_rounded
                : Icons.person_outline,
            color:
                isPremium ? const Color(0xFFD97706) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium
                      ? StringsEs.planPremium
                      : StringsEs.planGratuito,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPremium
                            ? const Color(0xFF92400E)
                            : null,
                      ),
                ),
                if (!isPremium)
                  Text(
                    '3 evaluaciones · 1 CV por día',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          if (!isPremium) ...[
            const Spacer(),
            TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.92,
                  minChildSize: 0.6,
                  maxChildSize: 0.92,
                  expand: false,
                  builder: (_, controller) => PaywallScreen(
                    trigger: PaywallTrigger.evaluation,
                    isLimitReached: false,
                    onDismiss: () =>
                        Navigator.of(context).pop(),
                  ),
                ),
              ),
              child: const Text('Mejorar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value,
                style:
                    Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _LinkInfoRow extends StatelessWidget {
  final String label;
  final String url;
  const _LinkInfoRow(this.label, this.url);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL copiada al portapapeles'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                url,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit mode widgets ─────────────────────────────────────────────────────────

class _ExperienceTile extends StatelessWidget {
  final WorkExperience exp;
  final ValueChanged<WorkExperience> onEdit;
  final VoidCallback onDelete;
  const _ExperienceTile(
      {required this.exp,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(exp.position),
      subtitle: Text(
          '${exp.company}  ·  ${exp.startDate} → ${exp.isCurrent ? "Actual" : (exp.endDate ?? "")}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Editar',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _ExperienceDialog(
                initial: exp,
                onSave: onEdit,
              ),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ExperienceDialog extends StatefulWidget {
  final WorkExperience? initial;
  final ValueChanged<WorkExperience> onSave;
  const _ExperienceDialog(
      {this.initial, required this.onSave});

  @override
  State<_ExperienceDialog> createState() =>
      _ExperienceDialogState();
}

class _ExperienceDialogState
    extends State<_ExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _positionCtrl = TextEditingController(
      text: widget.initial?.position ?? '');
  late final _companyCtrl = TextEditingController(
      text: widget.initial?.company ?? '');
  late final _descriptionCtrl = TextEditingController(
      text: widget.initial?.description ?? '');
  bool _autovalidate = false;

  final _now = DateTime.now();
  late int _startMonth;
  late int _startYear;
  int? _endMonth;
  int? _endYear;
  late bool _isCurrent;

  static int _parseMonth(String? date) {
    if (date == null || date.length < 2)
      return DateTime.now().month;
    return int.tryParse(date.split('/').first) ??
        DateTime.now().month;
  }

  static int _parseYear(String? date) {
    if (date == null || !date.contains('/'))
      return DateTime.now().year;
    return int.tryParse(date.split('/').last) ??
        DateTime.now().year;
  }

  late List<WorkReference> _references;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _startMonth = _parseMonth(init?.startDate);
    _startYear = _parseYear(init?.startDate);
    _isCurrent = init?.isCurrent ?? true;
    _endMonth = init?.endDate != null
        ? _parseMonth(init!.endDate)
        : null;
    _endYear = init?.endDate != null
        ? _parseYear(init!.endDate)
        : null;
    _references = List.from(init?.references ?? []);
  }

  @override
  void dispose() {
    _positionCtrl.dispose();
    _companyCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddReference(BuildContext context) async {
    final ref = await showDialog<WorkReference>(
      context: context,
      builder: (_) => const WorkReferenceDialog(),
    );
    if (ref != null && mounted) setState(() => _references.add(ref));
  }

  String _fmt(int m, int y) =>
      '${m.toString().padLeft(2, '0')}/$y';

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
        currentYear - 1960 + 1, (i) => currentYear - i);
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return AlertDialog(
      title: Text(widget.initial == null
          ? 'Agregar experiencia'
          : 'Editar experiencia'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _positionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Puesto / Cargo *'),
                textCapitalization:
                    TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Requerido'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                    labelText: 'Empresa *'),
                textCapitalization:
                    TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Requerido'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText:
                      'Responsabilidades y logros (opcional)',
                  alignLabelWithHint: true,
                ),
                textCapitalization:
                    TextCapitalization.sentences,
                maxLines: 5,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Fecha de inicio',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: _DropdownField<int>(
                    value: _startMonth,
                    items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(months[i]))),
                    onChanged: (v) {
                      if (v != null)
                        setState(() => _startMonth = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _DropdownField<int>(
                    value: _startYear,
                    items: years
                        .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString())))
                        .toList(),
                    onChanged: (v) {
                      if (v != null)
                        setState(() => _startYear = v);
                    },
                  ),
                ),
              ]),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Trabajo actual'),
                value: _isCurrent,
                onChanged: (v) =>
                    setState(() => _isCurrent = v ?? true),
              ),
              if (!_isCurrent) ...[
                Text(
                  'Fecha de fin',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: _DropdownField<int>(
                      value: _endMonth ?? _now.month,
                      items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(months[i]))),
                      onChanged: (v) {
                        if (v != null)
                          setState(() => _endMonth = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _DropdownField<int>(
                      value: _endYear ?? _now.year,
                      items: years
                          .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(y.toString())))
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          setState(() => _endYear = v);
                      },
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Referencias',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        _showAddReference(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              ..._references.map((r) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.name),
                    subtitle:
                        Text('${r.position} · ${r.company}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() =>
                          _references
                              .removeWhere((x) => x.id == r.id)),
                    ),
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onSave(WorkExperience(
                id: widget.initial?.id ?? const Uuid().v4(),
                company: _companyCtrl.text.trim(),
                position: _positionCtrl.text.trim(),
                startDate: _fmt(_startMonth, _startYear),
                endDate: _isCurrent
                    ? null
                    : _fmt(_endMonth ?? _now.month,
                        _endYear ?? _now.year),
                isCurrent: _isCurrent,
                description:
                    _descriptionCtrl.text.trim().isEmpty
                        ? null
                        : _descriptionCtrl.text.trim(),
                references: _references,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CertDialog extends StatefulWidget {
  final Certification? initial;
  final ValueChanged<Certification> onSave;
  const _CertDialog({this.initial, required this.onSave});

  @override
  State<_CertDialog> createState() => _CertDialogState();
}

class _CertDialogState extends State<_CertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  late final _issuerCtrl =
      TextEditingController(text: widget.initial?.issuer ?? '');
  late final _urlCtrl =
      TextEditingController(text: widget.initial?.url ?? '');
  bool _autovalidate = false;
  late int _year = widget.initial?.year ?? DateTime.now().year;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _issuerCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
        currentYear - 1980 + 1, (i) => currentYear - i);

    return AlertDialog(
      title: Text(widget.initial == null
          ? 'Agregar certificación'
          : 'Editar certificación'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre *'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issuerCtrl,
                decoration: const InputDecoration(
                    labelText: 'Institución emisora *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                    labelText: 'URL (opcional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Año',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _year,
                    isExpanded: true,
                    isDense: true,
                    items: years
                        .map((y) => DropdownMenuItem(
                            value: y, child: Text(y.toString())))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _year = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onSave(Certification(
                id: widget.initial?.id ?? const Uuid().v4(),
                name: _nameCtrl.text.trim(),
                issuer: _issuerCtrl.text.trim(),
                year: _year,
                url: _urlCtrl.text.trim().isEmpty
                    ? null
                    : _urlCtrl.text.trim(),
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ── Education dialog ──────────────────────────────────────────────────────────

class _EducationDialog extends StatefulWidget {
  final Education? initial;
  final ValueChanged<Education> onSave;
  const _EducationDialog({this.initial, required this.onSave});

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _degreeCtrl =
      TextEditingController(text: widget.initial?.degree ?? '');
  late final _fieldCtrl =
      TextEditingController(text: widget.initial?.field ?? '');
  late final _institutionCtrl =
      TextEditingController(text: widget.initial?.institution ?? '');
  bool _autovalidate = false;

  late int _startYear =
      int.tryParse(widget.initial?.startYear ?? '') ??
          DateTime.now().year;
  late int? _endYear =
      widget.initial?.endYear != null
          ? int.tryParse(widget.initial!.endYear!)
          : null;
  late bool _isOngoing = widget.initial?.isOngoing ?? true;

  @override
  void dispose() {
    _degreeCtrl.dispose();
    _fieldCtrl.dispose();
    _institutionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years =
        List.generate(currentYear - 1955 + 1, (i) => currentYear - i);

    return AlertDialog(
      title: Text(widget.initial == null
          ? 'Agregar educación'
          : 'Editar educación'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _degreeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Título / Carrera *'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fieldCtrl,
                decoration: const InputDecoration(
                    labelText: 'Área / Especialidad (opcional)'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _institutionCtrl,
                decoration:
                    const InputDecoration(labelText: 'Institución *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _DropdownField<int>(
                value: _startYear,
                items: years
                    .map((y) => DropdownMenuItem(
                        value: y, child: Text('Inicio: $y')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _startYear = v);
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('En curso'),
                value: _isOngoing,
                onChanged: (v) =>
                    setState(() => _isOngoing = v ?? true),
              ),
              if (!_isOngoing) ...[
                const SizedBox(height: 4),
                _DropdownField<int>(
                  value: _endYear ?? currentYear,
                  items: years
                      .map((y) => DropdownMenuItem(
                          value: y, child: Text('Egreso: $y')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _endYear = v);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onSave(Education(
                id: widget.initial?.id ?? const Uuid().v4(),
                institution: _institutionCtrl.text.trim(),
                degree: _degreeCtrl.text.trim(),
                field: _fieldCtrl.text.trim().isEmpty
                    ? 'General'
                    : _fieldCtrl.text.trim(),
                startYear: _startYear.toString(),
                endYear: _isOngoing
                    ? null
                    : (_endYear ?? DateTime.now().year).toString(),
                isOngoing: _isOngoing,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ── Language dialog ───────────────────────────────────────────────────────────

class _LanguageDialog extends StatefulWidget {
  final Language? initial;
  final ValueChanged<Language> onSave;
  const _LanguageDialog({this.initial, required this.onSave});

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  late final _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  late LanguageLevel _level =
      widget.initial?.level ?? LanguageLevel.intermedio;
  bool _showNameError = false;

  static const _suggestions = [
    'Inglés', 'Portugués', 'Francés', 'Alemán',
    'Italiano', 'Chino', 'Árabe', 'Japonés',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Agregar idioma' : 'Editar idioma'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Idioma *',
                errorText: _showNameError ? 'Requerido' : null,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_showNameError) {
                  setState(() => _showNameError = false);
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s),
                        onPressed: () => setState(() {
                          _nameCtrl.text = s;
                          _showNameError = false;
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LanguageLevel>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Nivel'),
              items: LanguageLevel.values
                  .map((l) => DropdownMenuItem(
                      value: l, child: Text(l.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _level = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) {
              setState(() => _showNameError = true);
              return;
            }
            widget.onSave(Language(name: name, level: _level));
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ChipListEditor extends StatelessWidget {
  final List<String> items;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onDelete;

  const _ChipListEditor({
    required this.items,
    required this.controller,
    required this.hint,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((item) => Chip(
                      label: Text(item),
                      onDeleted: () => onDelete(item),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                ),
                onSubmitted: (v) {
                  final trimmed = v.trim();
                  if (trimmed.isNotEmpty &&
                      !items.contains(trimmed)) {
                    onAdd(trimmed);
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, val, __) => IconButton.outlined(
                onPressed: val.text.trim().isEmpty
                    ? null
                    : () {
                        final trimmed = val.text.trim();
                        if (trimmed.isNotEmpty &&
                            !items.contains(trimmed)) {
                          onAdd(trimmed);
                          controller.clear();
                        }
                      },
                icon: const Icon(Icons.add, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 8, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
