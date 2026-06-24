import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';

import 'package:postula_ai/core/constants/localidades_argentina.dart';
import 'package:postula_ai/shared/providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/work_reference_dialog.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormFieldState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _cityKey = GlobalKey<FormFieldState>();

  // Contact
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Links
  final _linkedInCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();

  // Salary
  final _salaryCtrl = TextEditingController();
  final _commuteCtrl = TextEditingController();

  // Exclusions
  final _excludedIndustryCtrl = TextEditingController();
  final _excludedCompanyCtrl = TextEditingController();

  // Skills
  final _skillCtrl = TextEditingController();
  static const _maxSkills = 20;

  // City
  String _city = '';
  String _provincia = '';
  String _postalCode = '';
  bool _cityTouched = false;

  // Phone
  String _phoneRaw = '';
  String _fullPhone = '';
  String _initialLocalNumber = '';
  String? _phoneError;

  bool _nameTouched = false;
  bool _emailTouched = false;

  late final FocusNode _nameFocus;
  late final FocusNode _emailFocus;

  // Preferences
  Set<WorkModality> _preferredModalities = {};
  String _salaryCurrency = 'ARS';
  bool _salaryNegotiable = true;
  bool _hasOwnVehicle = false;
  List<String> _excludedIndustries = [];
  List<String> _excludedCompanies = [];

  // Collections
  List<WorkExperience> _experiences = [];
  List<Education> _educations = [];
  List<String> _skills = [];
  List<Language> _languages = [];
  List<Certification> _certifications = [];
  List<Project> _projects = [];

  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode()..addListener(_onNameFocus);
    _emailFocus = FocusNode()..addListener(_onEmailFocus);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initFromProfile());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _linkedInCtrl.dispose();
    _githubCtrl.dispose();
    _portfolioCtrl.dispose();
    _salaryCtrl.dispose();
    _commuteCtrl.dispose();
    _excludedIndustryCtrl.dispose();
    _excludedCompanyCtrl.dispose();
    _skillCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  static String _localNumber(String? full) {
    if (full == null || full.isEmpty) return '';
    if (full.startsWith('+54')) return full.substring(3);
    final match = RegExp(r'^\+\d{1,3}').firstMatch(full);
    if (match != null) return full.substring(match.end);
    return full;
  }

  void _initFromProfile() {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (!mounted) return;
    if (profile == null) {
      setState(() => _initialized = true);
      return;
    }
    final info = profile.personalInfo;
    final localNum = _localNumber(info.phone);
    setState(() {
      _initialized = true;
      // Contact
      _nameCtrl.text = info.fullName;
      _emailCtrl.text = info.email;
      _city = info.city;
      _provincia = info.provincia ?? '';
      _postalCode = info.postalCode ?? '';
      _initialLocalNumber = localNum;
      _phoneRaw = localNum.replaceAll(RegExp(r'\D'), '');
      _fullPhone = info.phone ?? '';
      // Links
      _linkedInCtrl.text = info.linkedInUrl ?? '';
      _githubCtrl.text = info.githubUrl ?? '';
      _portfolioCtrl.text = info.portfolioUrl ?? '';
      // Preferences
      _preferredModalities = Set.from(info.preferredModalities);
      _salaryCtrl.text =
          info.expectedSalaryAmount?.toStringAsFixed(0) ?? '';
      _salaryCurrency = info.expectedSalaryCurrency;
      _salaryNegotiable = info.salaryNegotiable;
      _hasOwnVehicle = info.hasOwnVehicle;
      _commuteCtrl.text = info.maxCommuteKm?.toString() ?? '';
      _excludedIndustries = List.from(info.excludedIndustries);
      _excludedCompanies = List.from(info.excludedCompanies);
      // Collections
      _experiences = List.from(profile.workExperience);
      _educations = List.from(profile.education);
      _skills = List.from(profile.skills);
      _languages = List.from(profile.languages);
      _certifications = List.from(profile.certifications);
      _projects = List.from(profile.projects);
    });
  }

  void _onNameFocus() {
    if (!_nameFocus.hasFocus && !_nameTouched) {
      setState(() => _nameTouched = true);
      _nameKey.currentState?.validate();
    }
  }

  void _onEmailFocus() {
    if (!_emailFocus.hasFocus && !_emailTouched) {
      setState(() => _emailTouched = true);
      _emailKey.currentState?.validate();
    }
  }

  String? _validatePhone() {
    final digits = _phoneRaw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Requerido';
    if (digits.length < 7) return 'Número inválido';
    return null;
  }

  void _tryAddSkill(String skill) {
    final s = skill.trim();
    if (s.isEmpty) return;
    if (_skills.length >= _maxSkills) return;
    if (_skills.any((x) => x.toLowerCase() == s.toLowerCase())) return;
    setState(() => _skills.add(s));
    _skillCtrl.clear();
  }

  Future<void> _save() async {
    final phoneErr = _validatePhone();
    setState(() {
      _phoneError = phoneErr;
      _nameTouched = true;
      _emailTouched = true;
    });
    if (!_formKey.currentState!.validate() || phoneErr != null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);

    final existing = ref.read(userProfileProvider).asData?.value;
    final now = DateTime.now();
    final base = existing ??
        UserProfile(
          uid: user.uid,
          personalInfo: PersonalInfo(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            city: _city,
            country: 'Argentina',
          ),
          isComplete: true,
          createdAt: now,
          updatedAt: now,
        );

    final profile = base.copyWith(
      personalInfo: base.personalInfo.copyWith(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _fullPhone.isNotEmpty ? _fullPhone : null,
        city: _city,
        country: 'Argentina',
        provincia: _provincia.isNotEmpty ? _provincia : null,
        postalCode: _postalCode.isNotEmpty ? _postalCode : null,
        linkedInUrl: _linkedInCtrl.text.trim().isEmpty
            ? null
            : _linkedInCtrl.text.trim(),
        githubUrl: _githubCtrl.text.trim().isEmpty
            ? null
            : _githubCtrl.text.trim(),
        portfolioUrl: _portfolioCtrl.text.trim().isEmpty
            ? null
            : _portfolioCtrl.text.trim(),
        preferredModalities: _preferredModalities.toList(),
        expectedSalaryAmount: _salaryCtrl.text.trim().isEmpty
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
      ),
      workExperience: _experiences,
      education: _educations,
      skills: _skills,
      languages: _languages.isEmpty
          ? const [Language(name: 'Español', level: LanguageLevel.nativo)]
          : _languages,
      certifications: _certifications,
      projects: _projects,
      isComplete: true,
      updatedAt: now,
    );

    final result = await ref.read(profileProvider.notifier).save(profile);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
      (_) => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final showCommute =
        _preferredModalities.contains(WorkModality.hybrid) ||
            _preferredModalities.contains(WorkModality.onsite);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Datos de contacto ────────────────────────────────────────────
            _EditSection(
              title: 'Datos de contacto',
              icon: Icons.person_outline,
              children: [
                TextFormField(
                  key: _nameKey,
                  focusNode: _nameFocus,
                  controller: _nameCtrl,
                  autovalidateMode: _nameTouched
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  decoration:
                      const InputDecoration(labelText: 'Nombre completo *'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: _emailKey,
                  focusNode: _emailFocus,
                  controller: _emailCtrl,
                  autovalidateMode: _emailTouched
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _EditPhoneField(
                  initialLocalNumber: _initialLocalNumber,
                  phoneError: _phoneError,
                  onChanged: (raw, full) {
                    setState(() {
                      _phoneRaw = raw;
                      _fullPhone = full ?? '';
                      if (_phoneError != null) {
                        _phoneError = _validatePhone();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Autocomplete<Localidad>(
                  initialValue: TextEditingValue(text: _city),
                  displayStringForOption: (l) => l.localidad,
                  optionsBuilder: (tv) {
                    final q = tv.text.toLowerCase().trim();
                    if (q.length < 2) {
                      return const Iterable<Localidad>.empty();
                    }
                    return kLocalidadesArgentina
                        .where(
                            (l) => l.localidad.toLowerCase().contains(q))
                        .take(6);
                  },
                  onSelected: (loc) {
                    setState(() {
                      _city = loc.localidad;
                      _provincia = loc.provincia;
                      _postalCode = loc.cp;
                      _cityTouched = true;
                    });
                  },
                  optionsViewBuilder: (ctx, onSel, opts) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: opts.length,
                          itemBuilder: (_, i) {
                            final loc = opts.elementAt(i);
                            return ListTile(
                              dense: true,
                              title: Text(loc.localidad),
                              subtitle: Text(loc.provincia),
                              onTap: () => onSel(loc),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  fieldViewBuilder: (ctx, fc, fn, _) => TextFormField(
                    key: _cityKey,
                    controller: fc,
                    focusNode: fn,
                    autovalidateMode: _cityTouched
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    decoration:
                        const InputDecoration(labelText: 'Ciudad *'),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) {
                      setState(() {
                        _city = v;
                        _provincia = '';
                        _postalCode = '';
                      });
                    },
                    onTapOutside: (_) {
                      if (!_cityTouched) {
                        setState(() => _cityTouched = true);
                      }
                      _cityKey.currentState?.validate();
                    },
                    validator: (_) =>
                        _city.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Links ────────────────────────────────────────────────────────
            _EditSection(
              title: 'Links profesionales',
              icon: Icons.link_outlined,
              children: [
                TextField(
                  controller: _linkedInCtrl,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn URL (opcional)',
                    hintText: 'https://linkedin.com/in/tu-perfil',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _githubCtrl,
                  decoration: const InputDecoration(
                    labelText: 'GitHub URL (opcional)',
                    hintText: 'https://github.com/tu-usuario',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portfolioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Portfolio o web personal (opcional)',
                    hintText: 'https://tu-portfolio.com',
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Experiencia ──────────────────────────────────────────────────
            _EditSection(
              title: 'Experiencia laboral',
              icon: Icons.work_outline,
              children: [
                ..._experiences.map((e) => _ItemTile(
                      title: e.position,
                      subtitle:
                          '${e.company}  •  ${e.startDate} → ${e.isCurrent ? "Actual" : (e.endDate ?? "")}',
                      onEdit: () => _showExpDialog(context, initial: e),
                      onDelete: () => setState(() =>
                          _experiences.removeWhere((x) => x.id == e.id)),
                    )),
                TextButton.icon(
                  onPressed: () => _showExpDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar experiencia'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Educación ────────────────────────────────────────────────────
            _EditSection(
              title: 'Educación',
              icon: Icons.school_outlined,
              children: [
                ..._educations.map((e) => _ItemTile(
                      title: e.degree,
                      subtitle:
                          '${e.institution}  •  ${e.startYear} → ${e.isOngoing ? "En curso" : (e.endYear ?? "")}',
                      onEdit: () => _showEduDialog(context, initial: e),
                      onDelete: () => setState(() =>
                          _educations.removeWhere((x) => x.id == e.id)),
                    )),
                TextButton.icon(
                  onPressed: () => _showEduDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar educación'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Habilidades ──────────────────────────────────────────────────
            _EditSection(
              title: 'Habilidades',
              icon: Icons.star_outline,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillCtrl,
                        decoration: const InputDecoration(
                            hintText: 'ej: Excel, liderazgo...'),
                        onSubmitted: _tryAddSkill,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _skillCtrl,
                      builder: (_, val, _) => IconButton.filled(
                        onPressed: val.text.trim().isEmpty
                            ? null
                            : () => _tryAddSkill(_skillCtrl.text),
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
                if (_skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills
                        .map((s) => Chip(
                              label: Text(s),
                              onDeleted: () =>
                                  setState(() => _skills.remove(s)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Idiomas ──────────────────────────────────────────────────────
            _EditSection(
              title: 'Idiomas',
              icon: Icons.language_outlined,
              children: [
                ..._languages.map((l) => _ItemTile(
                      title: l.name,
                      subtitle: l.level.label,
                      onEdit: () => _showLangDialog(context, initial: l),
                      onDelete: () => setState(() =>
                          _languages.removeWhere((x) => x.name == l.name)),
                    )),
                TextButton.icon(
                  onPressed: () => _showLangDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar idioma'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Preferencias laborales ───────────────────────────────────────
            _EditSection(
              title: 'Preferencias laborales',
              icon: Icons.tune_outlined,
              children: [
                Text('Modalidad de trabajo',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: WorkModality.values.map((m) {
                    final isSelected = _preferredModalities.contains(m);
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
                        labelText: 'Distancia máxima de viaje (km)'),
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
                  onChanged: (v) => setState(() => _hasOwnVehicle = v),
                ),
                const SizedBox(height: 8),
                Text('Pretensión salarial (opcional)',
                    style: Theme.of(context).textTheme.labelMedium),
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
                                  value: 'ARS', child: Text('ARS')),
                              DropdownMenuItem(
                                  value: 'USD', child: Text('USD')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _salaryCurrency = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _salaryCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Monto'),
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
                  onChanged: (v) => setState(() => _salaryNegotiable = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Exclusiones ──────────────────────────────────────────────────
            _EditSection(
              title: 'Exclusiones',
              icon: Icons.block_outlined,
              children: [
                Text('Industrias a evitar',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                _ChipListEditor(
                  items: _excludedIndustries,
                  controller: _excludedIndustryCtrl,
                  hint: 'ej: Tabaco, Juego...',
                  onAdd: (v) =>
                      setState(() => _excludedIndustries.add(v)),
                  onDelete: (v) =>
                      setState(() => _excludedIndustries.remove(v)),
                ),
                const SizedBox(height: 12),
                Text('Empresas a evitar',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                _ChipListEditor(
                  items: _excludedCompanies,
                  controller: _excludedCompanyCtrl,
                  hint: 'ej: Empresa XYZ...',
                  onAdd: (v) =>
                      setState(() => _excludedCompanies.add(v)),
                  onDelete: (v) =>
                      setState(() => _excludedCompanies.remove(v)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Certificaciones ──────────────────────────────────────────────
            _EditSection(
              title: 'Certificaciones',
              icon: Icons.verified_outlined,
              children: [
                ..._certifications.map((c) => _ItemTile(
                      title: c.name,
                      subtitle: '${c.issuer}  •  ${c.year}',
                      onEdit: () => _showCertDialog(context, initial: c),
                      onDelete: () => setState(() =>
                          _certifications.removeWhere((x) => x.id == c.id)),
                    )),
                TextButton.icon(
                  onPressed: () => _showCertDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar certificación'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Proyectos ────────────────────────────────────────────────────
            _EditSection(
              title: 'Proyectos destacados',
              icon: Icons.rocket_launch_outlined,
              children: [
                ..._projects.map((p) => _ItemTile(
                      title: p.name,
                      subtitle: p.description,
                      onEdit: () => _showProjectDialog(context, initial: p),
                      onDelete: () => setState(() =>
                          _projects.removeWhere((x) => x.id == p.id)),
                    )),
                TextButton.icon(
                  onPressed: () => _showProjectDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar proyecto'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Dialog launchers ─────────────────────────────────────────────────────────

  void _showExpDialog(BuildContext context, {WorkExperience? initial}) {
    showDialog(
      context: context,
      builder: (_) => _ExpDialog(
        initial: initial,
        onAdd: (e) => setState(() {
          if (initial != null) {
            final idx = _experiences.indexWhere((x) => x.id == initial.id);
            if (idx != -1) _experiences[idx] = e;
          } else {
            _experiences.add(e);
          }
        }),
      ),
    );
  }

  void _showEduDialog(BuildContext context, {Education? initial}) {
    showDialog(
      context: context,
      builder: (_) => _EduDialog(
        initial: initial,
        onAdd: (e) => setState(() {
          if (initial != null) {
            final idx = _educations.indexWhere((x) => x.id == initial.id);
            if (idx != -1) _educations[idx] = e;
          } else {
            _educations.add(e);
          }
        }),
      ),
    );
  }

  void _showLangDialog(BuildContext context, {Language? initial}) {
    showDialog(
      context: context,
      builder: (_) => _LangDialog(
        initial: initial,
        onAdd: (l) => setState(() {
          if (initial != null) {
            final idx = _languages.indexWhere((x) => x.name == initial.name);
            if (idx != -1) _languages[idx] = l;
          } else {
            _languages.add(l);
          }
        }),
      ),
    );
  }

  void _showCertDialog(BuildContext context, {Certification? initial}) {
    showDialog(
      context: context,
      builder: (_) => _CertDialog(
        initial: initial,
        onAdd: (c) => setState(() {
          if (initial != null) {
            final idx = _certifications.indexWhere((x) => x.id == initial.id);
            if (idx != -1) _certifications[idx] = c;
          } else {
            _certifications.add(c);
          }
        }),
      ),
    );
  }

  void _showProjectDialog(BuildContext context, {Project? initial}) {
    showDialog(
      context: context,
      builder: (_) => _ProjectDialog(
        initial: initial,
        onAdd: (p) => setState(() {
          if (initial != null) {
            final idx = _projects.indexWhere((x) => x.id == initial.id);
            if (idx != -1) _projects[idx] = p;
          } else {
            _projects.add(p);
          }
        }),
      ),
    );
  }
}

// ── Layout helpers ────────────────────────────────────────────────────────────

class _EditSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _EditSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.title,
    required this.subtitle,
    this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Editar',
              onPressed: onEdit,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
        ],
      ),
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
                decoration:
                    InputDecoration(hintText: hint, isDense: true),
                onSubmitted: (v) {
                  final t = v.trim();
                  if (t.isNotEmpty && !items.contains(t)) {
                    onAdd(t);
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, val, _) => IconButton.outlined(
                onPressed: val.text.trim().isEmpty
                    ? null
                    : () {
                        final t = val.text.trim();
                        if (t.isNotEmpty && !items.contains(t)) {
                          onAdd(t);
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

// ── Phone field ───────────────────────────────────────────────────────────────

class _EditPhoneField extends StatefulWidget {
  final String initialLocalNumber;
  final String? phoneError;
  final void Function(String raw, String? full) onChanged;

  const _EditPhoneField({
    required this.initialLocalNumber,
    required this.phoneError,
    required this.onChanged,
  });

  @override
  State<_EditPhoneField> createState() => _EditPhoneFieldState();
}

class _EditPhoneFieldState extends State<_EditPhoneField> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialLocalNumber;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      controller: _ctrl,
      initialCountryCode: 'AR',
      disableLengthCheck: true,
      decoration: InputDecoration(
        labelText: 'Teléfono',
        errorText: widget.phoneError,
      ),
      inputFormatters: [LengthLimitingTextInputFormatter(15)],
      onChanged: (phone) {
        final raw = phone.number.trim();
        widget.onChanged(raw, raw.isEmpty ? null : phone.completeNumber);
      },
    );
  }
}

// ── Experience dialog ─────────────────────────────────────────────────────────

class _ExpDialog extends StatefulWidget {
  final WorkExperience? initial;
  final ValueChanged<WorkExperience> onAdd;
  const _ExpDialog({this.initial, required this.onAdd});

  @override
  State<_ExpDialog> createState() => _ExpDialogState();
}

class _ExpDialogState extends State<_ExpDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _posCtrl =
      TextEditingController(text: widget.initial?.position ?? '');
  late final _compCtrl =
      TextEditingController(text: widget.initial?.company ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.initial?.description ?? '');
  bool _autovalidate = false;

  final _now = DateTime.now();
  late int _sm;
  late int _sy;
  int? _em;
  int? _ey;
  late bool _isCurrent;

  static int _parseM(String? date) {
    if (date == null || !date.contains('/')) return DateTime.now().month;
    return int.tryParse(date.split('/').first) ?? DateTime.now().month;
  }

  static int _parseY(String? date) {
    if (date == null || !date.contains('/')) return DateTime.now().year;
    return int.tryParse(date.split('/').last) ?? DateTime.now().year;
  }

  late List<WorkReference> _references;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _sm = _parseM(init?.startDate);
    _sy = _parseY(init?.startDate);
    _isCurrent = init?.isCurrent ?? true;
    _em = init?.endDate != null ? _parseM(init!.endDate) : null;
    _ey = init?.endDate != null ? _parseY(init!.endDate) : null;
    _references = List.from(init?.references ?? []);
  }

  @override
  void dispose() {
    _posCtrl.dispose();
    _compCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddReference(BuildContext context) async {
    final ref = await showDialog<WorkReference>(
      context: context,
      builder: (_) => const WorkReferenceDialog(),
    );
    if (ref != null && mounted) setState(() => _references.add(ref));
  }

  String _fmt(int m, int y) => '${m.toString().padLeft(2, '0')}/$y';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Agregar experiencia' : 'Editar experiencia'),
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
                controller: _posCtrl,
                decoration:
                    const InputDecoration(labelText: 'Puesto / Cargo *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _compCtrl,
                decoration: const InputDecoration(labelText: 'Empresa *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Responsabilidades y logros (opcional)',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              _MonthYearPicker(
                label: 'Fecha de inicio',
                month: _sm,
                year: _sy,
                onChanged: (m, y) => setState(() {
                  _sm = m;
                  _sy = y;
                }),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Trabajo actual'),
                value: _isCurrent,
                onChanged: (v) =>
                    setState(() => _isCurrent = v ?? true),
              ),
              if (!_isCurrent)
                _MonthYearPicker(
                  label: 'Fecha de fin',
                  month: _em ?? _now.month,
                  year: _ey ?? _now.year,
                  onChanged: (m, y) => setState(() {
                    _em = m;
                    _ey = y;
                  }),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Referencias',
                      style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddReference(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              ..._references.map((r) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.name),
                    subtitle: Text('${r.position} · ${r.company}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() =>
                          _references.removeWhere((x) => x.id == r.id)),
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
              widget.onAdd(WorkExperience(
                id: widget.initial?.id ?? const Uuid().v4(),
                company: _compCtrl.text.trim(),
                position: _posCtrl.text.trim(),
                startDate: _fmt(_sm, _sy),
                endDate: _isCurrent
                    ? null
                    : _fmt(_em ?? _now.month, _ey ?? _now.year),
                isCurrent: _isCurrent,
                description: _descCtrl.text.trim().isEmpty
                    ? null
                    : _descCtrl.text.trim(),
                references: _references,
              ));
              Navigator.pop(context);
            }
          },
          child: Text(widget.initial == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

// ── Education dialog ──────────────────────────────────────────────────────────

class _EduDialog extends StatefulWidget {
  final Education? initial;
  final ValueChanged<Education> onAdd;
  const _EduDialog({this.initial, required this.onAdd});

  @override
  State<_EduDialog> createState() => _EduDialogState();
}

class _EduDialogState extends State<_EduDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _degCtrl =
      TextEditingController(text: widget.initial?.degree ?? '');
  late final _fieldCtrl = TextEditingController(
      text: (widget.initial?.field == 'General' ? '' : widget.initial?.field) ?? '');
  late final _instCtrl =
      TextEditingController(text: widget.initial?.institution ?? '');
  bool _autovalidate = false;

  late int _sy;
  int? _ey;
  late bool _isOngoing;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _sy = int.tryParse(init?.startYear ?? '') ?? DateTime.now().year;
    _isOngoing = init?.isOngoing ?? true;
    _ey = init?.endYear != null ? int.tryParse(init!.endYear!) : null;
  }

  @override
  void dispose() {
    _degCtrl.dispose();
    _fieldCtrl.dispose();
    _instCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Agregar educación' : 'Editar educación'),
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
                controller: _degCtrl,
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
                controller: _instCtrl,
                decoration:
                    const InputDecoration(labelText: 'Institución *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _YearPicker(
                label: 'Año de inicio',
                year: _sy,
                onChanged: (y) => setState(() => _sy = y),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('En curso'),
                value: _isOngoing,
                onChanged: (v) =>
                    setState(() => _isOngoing = v ?? true),
              ),
              if (!_isOngoing)
                _YearPicker(
                  label: 'Año de egreso',
                  year: _ey ?? DateTime.now().year,
                  onChanged: (y) => setState(() => _ey = y),
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
              widget.onAdd(Education(
                id: widget.initial?.id ?? const Uuid().v4(),
                institution: _instCtrl.text.trim(),
                degree: _degCtrl.text.trim(),
                field: _fieldCtrl.text.trim().isEmpty
                    ? 'General'
                    : _fieldCtrl.text.trim(),
                startYear: _sy.toString(),
                endYear: _isOngoing
                    ? null
                    : (_ey ?? DateTime.now().year).toString(),
                isOngoing: _isOngoing,
              ));
              Navigator.pop(context);
            }
          },
          child: Text(widget.initial == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

// ── Language dialog ───────────────────────────────────────────────────────────

class _LangDialog extends StatefulWidget {
  final Language? initial;
  final ValueChanged<Language> onAdd;
  const _LangDialog({this.initial, required this.onAdd});

  @override
  State<_LangDialog> createState() => _LangDialogState();
}

class _LangDialogState extends State<_LangDialog> {
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
      title: Text(widget.initial == null ? 'Agregar idioma' : 'Editar idioma'),
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
                        value: l,
                        child: Text(l.label),
                      ))
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
            widget.onAdd(Language(name: name, level: _level));
            Navigator.pop(context);
          },
          child: Text(widget.initial == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

// ── Certification dialog ──────────────────────────────────────────────────────

class _CertDialog extends StatefulWidget {
  final Certification? initial;
  final ValueChanged<Certification> onAdd;
  const _CertDialog({this.initial, required this.onAdd});

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
    final cur = DateTime.now().year;
    final years = List.generate(cur - 1980 + 1, (i) => cur - i);

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
                decoration: const InputDecoration(labelText: 'Nombre *'),
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
                decoration:
                    const InputDecoration(labelText: 'URL (opcional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Año',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
              widget.onAdd(Certification(
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
          child: Text(widget.initial == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

// ── Project dialog ────────────────────────────────────────────────────────────

class _ProjectDialog extends StatefulWidget {
  final Project? initial;
  final ValueChanged<Project> onAdd;
  const _ProjectDialog({this.initial, required this.onAdd});

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.initial?.description ?? '');
  late final _urlCtrl =
      TextEditingController(text: widget.initial?.url ?? '');
  late final _contextCtrl =
      TextEditingController(text: widget.initial?.context ?? '');
  final _techCtrl = TextEditingController();
  bool _autovalidate = false;

  late List<String> _technologies;
  late bool _isCurrent;
  int? _startMonth;
  int? _startYear;
  int? _endMonth;
  int? _endYear;

  static int _parseM(String? date) {
    if (date == null || !date.contains('/')) return DateTime.now().month;
    return int.tryParse(date.split('/').first) ?? DateTime.now().month;
  }

  static int _parseY(String? date) {
    if (date == null || !date.contains('/')) return DateTime.now().year;
    return int.tryParse(date.split('/').last) ?? DateTime.now().year;
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _technologies = List.from(init?.technologies ?? []);
    _isCurrent = init?.isCurrent ?? false;
    if (init?.startDate != null) {
      _startMonth = _parseM(init!.startDate);
      _startYear = _parseY(init.startDate);
    }
    if (init?.endDate != null) {
      _endMonth = _parseM(init!.endDate);
      _endYear = _parseY(init.endDate);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    _contextCtrl.dispose();
    _techCtrl.dispose();
    super.dispose();
  }

  void _addTech() {
    final v = _techCtrl.text.trim();
    if (v.isEmpty ||
        _technologies.any((t) => t.toLowerCase() == v.toLowerCase())) {
      return;
    }
    setState(() => _technologies = [..._technologies, v]);
    _techCtrl.clear();
  }

  String _fmt(int m, int y) => '${m.toString().padLeft(2, '0')}/$y';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Agregar proyecto' : 'Editar proyecto'),
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
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre del proyecto *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contextCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contexto (opcional)',
                  hintText: 'ej: Freelance, Personal, Académico',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL (opcional)',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Text('Tecnologías usadas',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _techCtrl,
                      decoration: const InputDecoration(
                        hintText: 'ej: Flutter, Python...',
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addTech(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _techCtrl,
                    builder: (_, val, _) => IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: val.text.trim().isEmpty ? null : _addTech,
                    ),
                  ),
                ],
              ),
              if (_technologies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _technologies
                      .map((t) => Chip(
                            label: Text(t),
                            onDeleted: () => setState(() => _technologies =
                                _technologies.where((x) => x != t).toList()),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Proyecto en curso'),
                value: _isCurrent,
                onChanged: (v) => setState(() => _isCurrent = v ?? false),
              ),
              _MonthYearPicker(
                label: 'Fecha de inicio (opcional)',
                month: _startMonth ?? now.month,
                year: _startYear ?? now.year,
                onChanged: (m, y) =>
                    setState(() { _startMonth = m; _startYear = y; }),
              ),
              if (!_isCurrent) ...[
                const SizedBox(height: 8),
                _MonthYearPicker(
                  label: 'Fecha de fin (opcional)',
                  month: _endMonth ?? now.month,
                  year: _endYear ?? now.year,
                  onChanged: (m, y) =>
                      setState(() { _endMonth = m; _endYear = y; }),
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
              widget.onAdd(Project(
                id: widget.initial?.id ?? const Uuid().v4(),
                name: _nameCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                technologies: _technologies,
                url: _urlCtrl.text.trim().isEmpty
                    ? null
                    : _urlCtrl.text.trim(),
                context: _contextCtrl.text.trim().isEmpty
                    ? null
                    : _contextCtrl.text.trim(),
                startDate: _startMonth != null && _startYear != null
                    ? _fmt(_startMonth!, _startYear!)
                    : null,
                endDate:
                    (!_isCurrent && _endMonth != null && _endYear != null)
                        ? _fmt(_endMonth!, _endYear!)
                        : null,
                isCurrent: _isCurrent,
              ));
              Navigator.pop(context);
            }
          },
          child: Text(widget.initial == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

// ── Picker helpers ────────────────────────────────────────────────────────────

class _MonthYearPicker extends StatelessWidget {
  final String label;
  final int month;
  final int year;
  final void Function(int m, int y) onChanged;

  const _MonthYearPicker({
    required this.label,
    required this.month,
    required this.year,
    required this.onChanged,
  });

  static const _months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  Widget build(BuildContext context) {
    final cur = DateTime.now().year;
    final years = List.generate(cur - 1960 + 1, (i) => cur - i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _Dropdown<int>(
                value: month,
                items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                        value: i + 1, child: Text(_months[i]))),
                onChanged: (v) {
                  if (v != null) onChanged(v, year);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _Dropdown<int>(
                value: year,
                items: years
                    .map((y) => DropdownMenuItem(
                        value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(month, v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _YearPicker extends StatelessWidget {
  final String label;
  final int year;
  final ValueChanged<int> onChanged;

  const _YearPicker({
    required this.label,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cur = DateTime.now().year;
    final years = List.generate(cur - 1955 + 1, (i) => cur - i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        const SizedBox(height: 4),
        _Dropdown<int>(
          value: year,
          items: years
              .map((y) =>
                  DropdownMenuItem(value: y, child: Text(y.toString())))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
