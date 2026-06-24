import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/localidades_argentina.dart';
import '../../../../core/constants/strings_es.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/work_reference_dialog.dart';
import 'login_screen.dart';

// ── Static data ───────────────────────────────────────────────────────────────

const _suggestedSkills = [
  'Excel',
  'Word',
  'PowerPoint',
  'Google Sheets',
  'Outlook',
  'Canva',
  'SAP',
  'SQL',
  'Atención al cliente',
  'Ventas',
  'Facturación',
  'Gestión del tiempo',
  'Trabajo en equipo',
  'Comunicación',
  'Liderazgo',
  'Resolución de problemas',
  'Planificación',
  'Inglés',
  'Portugués',
  'Redes sociales',
  'Marketing digital',
  'Contabilidad',
  'Logística',
  'Recursos humanos',
  'Administración',
  'Python',
  'Java',
  'JavaScript',
  'Photoshop',
];

// ── OnboardingScreen ──────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _commuteCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();

  final List<WorkExperience> _experiences = [];
  final List<Education> _educations = [];
  final List<String> _skills = [];
  final List<Language> _languages = [
    const Language(name: 'Español', level: LanguageLevel.nativo),
  ];
  final List<Certification> _certifications = [];
  final List<Project> _projects = [];

  String _fullPhoneNumber = '';
  String _city = '';
  String _provincia = '';
  String _postalCode = '';

  Set<WorkModality> _preferredModalities = {};
  String _expectedSalaryCurrency = 'ARS';
  bool _salaryNegotiable = true;
  bool _hasOwnVehicle = false;
  List<String> _excludedIndustries = [];
  List<String> _excludedCompanies = [];

  bool get _isAuthenticated => ref.watch(currentUserProvider) != null;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _salaryCtrl.dispose();
    _commuteCtrl.dispose();
    _linkedInCtrl.dispose();
    _githubCtrl.dispose();
    _portfolioCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goBackToLogin() async {
    await FirebaseAuth.instance.signOut();
    // currentUserProvider emits null → _isAuthenticated becomes false
    // → build() returns LoginScreen
  }

  Future<void> _finish() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = UserProfile(
      uid: user.uid,
      personalInfo: PersonalInfo(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _fullPhoneNumber.isNotEmpty ? _fullPhoneNumber : null,
        city: _city,
        country: 'Argentina',
        provincia: _provincia.isNotEmpty ? _provincia : null,
        postalCode: _postalCode.isNotEmpty ? _postalCode : null,
        linkedInUrl: _linkedInCtrl.text.trim().isNotEmpty
            ? _linkedInCtrl.text.trim()
            : null,
        githubUrl: _githubCtrl.text.trim().isNotEmpty
            ? _githubCtrl.text.trim()
            : null,
        portfolioUrl: _portfolioCtrl.text.trim().isNotEmpty
            ? _portfolioCtrl.text.trim()
            : null,
        preferredModalities: _preferredModalities.toList(),
        expectedSalaryAmount: _salaryCtrl.text.trim().isNotEmpty
            ? double.tryParse(_salaryCtrl.text.trim())
            : null,
        expectedSalaryCurrency: _expectedSalaryCurrency,
        salaryNegotiable: _salaryNegotiable,
        hasOwnVehicle: _hasOwnVehicle,
        maxCommuteKm: _commuteCtrl.text.trim().isNotEmpty
            ? int.tryParse(_commuteCtrl.text.trim())
            : null,
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await ref.read(profileProvider.notifier).save(profile);
    if (!mounted) return;

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 6),
        ),
      ),
      (_) => context.go(AppRoutes.evaluate),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) return const LoginScreen();

    // Show spinner while profile loads so the router redirect fires cleanly
    // without a flash of the onboarding form for returning users.
    if (ref.watch(userProfileProvider).isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: back button + step counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: _currentPage == 0 ? 'Cambiar cuenta' : 'Volver',
                    onPressed: _currentPage == 0 ? _goBackToLogin : _prevPage,
                  ),
                  const Spacer(),
                  if (_currentPage < 8)
                    Text(
                      'Paso ${_currentPage + 1} de 8',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: _currentPage < 8 ? (_currentPage + 1) / 8 : 1.0,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _Step1ContactInfo(
                    nameCtrl: _nameCtrl,
                    emailCtrl: _emailCtrl,
                    phoneCtrl: _phoneCtrl,
                    initialCity: _city,
                    onNext: _nextPage,
                    onPhoneChanged: (v) => _fullPhoneNumber = v ?? '',
                    onCityChanged: (v) => _city = v,
                    onProvinciaChanged: (v) => _provincia = v ?? '',
                    onPostalCodeChanged: (v) => _postalCode = v ?? '',
                  ),
                  _Step2Experience(
                    experiences: _experiences,
                    onChanged: (list) => setState(() {
                      _experiences
                        ..clear()
                        ..addAll(list);
                    }),
                    onNext: _nextPage,
                  ),
                  _Step3Education(
                    educations: _educations,
                    onChanged: (list) => setState(() {
                      _educations
                        ..clear()
                        ..addAll(list);
                    }),
                    onNext: _nextPage,
                  ),
                  _Step4Skills(
                    skills: _skills,
                    onChanged: (list) => setState(() {
                      _skills
                        ..clear()
                        ..addAll(list);
                    }),
                    onNext: _nextPage,
                  ),
                  _Step5Languages(
                    languages: _languages,
                    onChanged: (list) => setState(() {
                      _languages
                        ..clear()
                        ..addAll(list);
                    }),
                    onNext: _nextPage,
                  ),
                  _Step6Projects(
                    projects: _projects,
                    onChanged: (list) => setState(() {
                      _projects
                        ..clear()
                        ..addAll(list);
                    }),
                    onNext: _nextPage,
                  ),
                  _Step7WorkPreferences(
                    preferredModalities: _preferredModalities,
                    salaryCtrl: _salaryCtrl,
                    commuteCtrl: _commuteCtrl,
                    currency: _expectedSalaryCurrency,
                    salaryNegotiable: _salaryNegotiable,
                    hasOwnVehicle: _hasOwnVehicle,
                    excludedIndustries: _excludedIndustries,
                    excludedCompanies: _excludedCompanies,
                    onModalitiesChanged: (v) =>
                        setState(() => _preferredModalities = v),
                    onCurrencyChanged: (v) =>
                        setState(() => _expectedSalaryCurrency = v),
                    onSalaryNegotiableChanged: (v) =>
                        setState(() => _salaryNegotiable = v),
                    onHasVehicleChanged: (v) =>
                        setState(() => _hasOwnVehicle = v),
                    onExcludedIndustriesChanged: (v) =>
                        setState(() => _excludedIndustries = v),
                    onExcludedCompaniesChanged: (v) =>
                        setState(() => _excludedCompanies = v),
                    onNext: _nextPage,
                  ),
                  _Step8LinksAndCerts(
                    linkedInCtrl: _linkedInCtrl,
                    githubCtrl: _githubCtrl,
                    portfolioCtrl: _portfolioCtrl,
                    certifications: _certifications,
                    onCertificationsChanged: (list) => setState(() {
                      _certifications
                        ..clear()
                        ..addAll(list);
                    }),
                    onNext: _nextPage,
                  ),
                  _Step9Finish(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Paso 1: Datos de contacto ─────────────────────────────────────────────────

class _Step1ContactInfo extends StatefulWidget {
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl;
  final String initialCity;
  final VoidCallback onNext;
  final ValueChanged<String?> onPhoneChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String?> onProvinciaChanged;
  final ValueChanged<String?> onPostalCodeChanged;

  const _Step1ContactInfo({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.initialCity,
    required this.onNext,
    required this.onPhoneChanged,
    required this.onCityChanged,
    required this.onProvinciaChanged,
    required this.onPostalCodeChanged,
  });

  @override
  State<_Step1ContactInfo> createState() => _Step1ContactInfoState();
}

class _Step1ContactInfoState extends State<_Step1ContactInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormFieldState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _cityKey = GlobalKey<FormFieldState>();

  String _cityText = '';

  // IntlPhoneField doesn't reliably participate in Form.validate(), so we
  // track phone state manually and validate it ourselves.
  String _phoneRaw = '';
  String? _phoneError;

  // Each field only auto-validates after the user has left it at least once.
  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _cityTouched = false;

  late final FocusNode _nameFocus;
  late final FocusNode _emailFocus;

  @override
  void initState() {
    super.initState();
    _cityText = widget.initialCity;
    _nameFocus = FocusNode()..addListener(_onNameFocusChange);
    _emailFocus = FocusNode()..addListener(_onEmailFocusChange);
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _onNameFocusChange() {
    if (!_nameFocus.hasFocus && !_nameTouched) {
      setState(() => _nameTouched = true);
      _nameKey.currentState?.validate();
    }
  }

  void _onEmailFocusChange() {
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            StringsEs.onboardingPaso1Titulo,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: _nameKey,
            focusNode: _nameFocus,
            controller: widget.nameCtrl,
            autovalidateMode: _nameTouched
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            decoration: const InputDecoration(
              labelText: StringsEs.perfilNombre,
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: _emailKey,
            focusNode: _emailFocus,
            controller: widget.emailCtrl,
            autovalidateMode: _emailTouched
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            decoration: const InputDecoration(labelText: StringsEs.perfilEmail),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          IntlPhoneField(
            controller: widget.phoneCtrl,
            initialCountryCode: 'AR',
            disableLengthCheck: true,
            decoration: InputDecoration(
              labelText: StringsEs.perfilTelefono,
              errorText: _phoneError,
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(15)],
            onChanged: (phone) {
              final raw = phone.number.trim();
              setState(() {
                _phoneRaw = raw;
                if (_phoneError != null) _phoneError = _validatePhone();
              });
              widget.onPhoneChanged(raw.isEmpty ? null : phone.completeNumber);
            },
          ),
          const SizedBox(height: 16),
          // City with autocomplete backed by kLocalidadesArgentina
          Autocomplete<Localidad>(
            initialValue: TextEditingValue(text: widget.initialCity),
            displayStringForOption: (l) => l.localidad,
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.toLowerCase().trim();
              if (query.length < 2) return const Iterable<Localidad>.empty();
              return kLocalidadesArgentina
                  .where((l) => l.localidad.toLowerCase().contains(query))
                  .take(6);
            },
            onSelected: (localidad) {
              setState(() {
                _cityText = localidad.localidad;
                _cityTouched = true;
              });
              widget.onCityChanged(localidad.localidad);
              widget.onProvinciaChanged(localidad.provincia);
              widget.onPostalCodeChanged(localidad.cp);
            },
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final loc = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        title: Text(loc.localidad),
                        subtitle: Text(loc.provincia),
                        onTap: () => onSelected(loc),
                      );
                    },
                  ),
                ),
              ),
            ),
            fieldViewBuilder:
                (context, fieldCtrl, focusNode, onFieldSubmitted) =>
                    TextFormField(
                      key: _cityKey,
                      controller: fieldCtrl,
                      focusNode: focusNode,
                      autovalidateMode: _cityTouched
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      decoration: const InputDecoration(
                        labelText: StringsEs.perfilCiudad,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) {
                        setState(() => _cityText = v);
                        widget.onCityChanged(v);
                        widget.onProvinciaChanged(null);
                        widget.onPostalCodeChanged(null);
                      },
                      onTapOutside: (_) {
                        if (!_cityTouched) setState(() => _cityTouched = true);
                        _cityKey.currentState?.validate();
                      },
                      validator: (_) =>
                          _cityText.trim().isEmpty ? 'Requerido' : null,
                    ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final phoneErr = _validatePhone();
              setState(() {
                _phoneError = phoneErr;
                _nameTouched = true;
                _emailTouched = true;
                _cityTouched = true;
              });
              if (_formKey.currentState!.validate() && phoneErr == null) {
                widget.onNext();
              }
            },
            child: const Text(StringsEs.continuar),
          ),
        ],
      ),
    );
  }
}

// ── Paso 2: Experiencia laboral ───────────────────────────────────────────────

class _Step2Experience extends StatelessWidget {
  final List<WorkExperience> experiences;
  final Function(List<WorkExperience>) onChanged;
  final VoidCallback onNext;

  const _Step2Experience({
    required this.experiences,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          StringsEs.onboardingPaso2Titulo,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Agregá tus empleos anteriores. Podés agregar más tarde desde tu perfil.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        ...experiences.map(
          (e) => Card(
            child: ListTile(
              title: Text(e.position),
              subtitle: Text(
                '${e.company}  •  ${e.startDate} → ${e.isCurrent ? 'Actual' : (e.endDate ?? '')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  onChanged(
                    List<WorkExperience>.from(experiences)
                      ..removeWhere((x) => x.id == e.id),
                  );
                },
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text(StringsEs.perfilAgregarExperiencia),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onNext,
          child: const Text(StringsEs.continuar),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            onChanged([]);
            onNext();
          },
          child: const Text('Saltar por ahora'),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ExperienceDialog(
        onAdd: (exp) =>
            onChanged(List<WorkExperience>.from(experiences)..add(exp)),
      ),
    );
  }
}

class _ExperienceDialog extends StatefulWidget {
  final ValueChanged<WorkExperience> onAdd;
  const _ExperienceDialog({required this.onAdd});

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _positionCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _autovalidate = false;

  final _now = DateTime.now();
  late int _startMonth = DateTime.now().month;
  late int _startYear = DateTime.now().year;
  int? _endMonth;
  int? _endYear;
  bool _isCurrent = true;
  final List<WorkReference> _references = [];

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

  String _fmt(int m, int y) => '${m.toString().padLeft(2, '0')}/$y';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar experiencia'),
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
                  labelText: 'Puesto / Cargo *',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(labelText: 'Empresa *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Responsabilidades y logros (opcional)',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 6,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              _MonthYearPicker(
                label: 'Fecha de inicio',
                month: _startMonth,
                year: _startYear,
                onChanged: (m, y) => setState(() {
                  _startMonth = m;
                  _startYear = y;
                }),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Trabajo actual'),
                value: _isCurrent,
                onChanged: (v) => setState(() => _isCurrent = v ?? true),
              ),
              if (!_isCurrent) ...[
                _MonthYearPicker(
                  label: 'Fecha de fin',
                  month: _endMonth ?? _now.month,
                  year: _endYear ?? _now.year,
                  onChanged: (m, y) => setState(() {
                    _endMonth = m;
                    _endYear = y;
                  }),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Referencias',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddReference(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              ..._references.map(
                (r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.name),
                  subtitle: Text('${r.position} · ${r.company}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(
                      () => _references.removeWhere((x) => x.id == r.id),
                    ),
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
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                WorkExperience(
                  id: const Uuid().v4(),
                  company: _companyCtrl.text.trim(),
                  position: _positionCtrl.text.trim(),
                  startDate: _fmt(_startMonth, _startYear),
                  endDate: _isCurrent
                      ? null
                      : _fmt(_endMonth ?? _now.month, _endYear ?? _now.year),
                  isCurrent: _isCurrent,
                  description: _descriptionCtrl.text.trim().isEmpty
                      ? null
                      : _descriptionCtrl.text.trim(),
                  references: _references,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ── Paso 3: Educación ─────────────────────────────────────────────────────────

class _Step3Education extends StatelessWidget {
  final List<Education> educations;
  final Function(List<Education>) onChanged;
  final VoidCallback onNext;

  const _Step3Education({
    required this.educations,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          StringsEs.onboardingPaso3Titulo,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        ...educations.map(
          (e) => Card(
            child: ListTile(
              title: Text(e.degree),
              subtitle: Text(
                '${e.institution}  •  ${e.startYear} → ${e.isOngoing ? 'En curso' : (e.endYear ?? '')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  onChanged(
                    List<Education>.from(educations)
                      ..removeWhere((x) => x.id == e.id),
                  );
                },
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text(StringsEs.perfilAgregarEducacion),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onNext,
          child: const Text(StringsEs.continuar),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            onChanged([]);
            onNext();
          },
          child: const Text('Saltar por ahora'),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _EducationDialog(
        onAdd: (edu) => onChanged(List<Education>.from(educations)..add(edu)),
      ),
    );
  }
}

class _EducationDialog extends StatefulWidget {
  final ValueChanged<Education> onAdd;
  const _EducationDialog({required this.onAdd});

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _degreeCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  bool _autovalidate = false;

  late int _startYear = DateTime.now().year;
  int? _endYear;
  bool _isOngoing = true;

  @override
  void dispose() {
    _degreeCtrl.dispose();
    _fieldCtrl.dispose();
    _institutionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar educación'),
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
                  labelText: 'Título / Carrera *',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fieldCtrl,
                decoration: const InputDecoration(
                  labelText: 'Área / Especialidad (opcional)',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _institutionCtrl,
                decoration: const InputDecoration(labelText: 'Institución *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _YearPicker(
                label: 'Año de inicio',
                year: _startYear,
                onChanged: (y) => setState(() => _startYear = y),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('En curso'),
                value: _isOngoing,
                onChanged: (v) => setState(() => _isOngoing = v ?? true),
              ),
              if (!_isOngoing) ...[
                _YearPicker(
                  label: 'Año de egreso',
                  year: _endYear ?? DateTime.now().year,
                  onChanged: (y) => setState(() => _endYear = y),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                Education(
                  id: const Uuid().v4(),
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
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ── Paso 4: Habilidades ───────────────────────────────────────────────────────

class _Step4Skills extends StatefulWidget {
  final List<String> skills;
  final Function(List<String>) onChanged;
  final VoidCallback onNext;

  const _Step4Skills({
    required this.skills,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<_Step4Skills> createState() => _Step4SkillsState();
}

class _Step4SkillsState extends State<_Step4Skills> {
  final _ctrl = TextEditingController();
  static const _maxSkills = 20;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tryAdd(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;

    if (widget.skills.length >= _maxSkills) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo $_maxSkills habilidades')),
      );
      return;
    }

    if (widget.skills.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"$trimmed" ya está en tu lista')));
      return;
    }

    widget.onChanged([...widget.skills, trimmed]);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          StringsEs.onboardingPaso4Titulo,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Escribí una habilidad o elegí de las sugerencias.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        // Custom skill input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'ej: Excel, Atención al cliente...',
                ),
                onSubmitted: _tryAdd,
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _ctrl,
              builder: (_, val, _) => IconButton.filled(
                onPressed: val.text.trim().isEmpty
                    ? null
                    : () => _tryAdd(_ctrl.text),
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Suggestions
        Text(
          'Sugerencias:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _suggestedSkills.map((skill) {
            final isAdded = widget.skills.any(
              (s) => s.toLowerCase() == skill.toLowerCase(),
            );
            return FilterChip(
              label: Text(skill),
              selected: isAdded,
              onSelected: (_) {
                if (isAdded) {
                  widget.onChanged(
                    widget.skills
                        .where((s) => s.toLowerCase() != skill.toLowerCase())
                        .toList(),
                  );
                } else {
                  _tryAdd(skill);
                }
              },
            );
          }).toList(),
        ),

        // Added skills + counter
        if (widget.skills.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Tus habilidades',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.skills.length}/$_maxSkills',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: widget.skills.length >= _maxSkills
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.skills
                .map(
                  (s) => Chip(
                    label: Text(s),
                    onDeleted: () {
                      widget.onChanged(
                        widget.skills.where((x) => x != s).toList(),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ],

        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.onNext,
          child: const Text(StringsEs.continuar),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            widget.onChanged([]);
            widget.onNext();
          },
          child: const Text('Saltar por ahora'),
        ),
      ],
    );
  }
}

// ── Paso 5: Idiomas ───────────────────────────────────────────────────────────

class _Step5Languages extends StatelessWidget {
  final List<Language> languages;
  final Function(List<Language>) onChanged;
  final VoidCallback onNext;

  const _Step5Languages({
    required this.languages,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tus idiomas', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Agregá los idiomas que manejás además del español.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        ...languages.map(
          (l) => Card(
            child: ListTile(
              title: Text(l.name),
              subtitle: Text(l.level.label),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                onPressed: () => onChanged(
                  languages.where((x) => x.name != l.name).toList(),
                ),
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Agregar idioma'),
        ),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: onNext, child: const Text('Continuar')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            onChanged([]);
            onNext();
          },
          child: const Text('Saltar por ahora'),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _LanguageDialog(onAdd: (lang) => onChanged([...languages, lang])),
    );
  }
}

class _LanguageDialog extends StatefulWidget {
  final ValueChanged<Language> onAdd;
  const _LanguageDialog({required this.onAdd});

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  final _nameCtrl = TextEditingController();
  LanguageLevel _level = LanguageLevel.intermedio;
  bool _showNameError = false;

  static const _suggestions = [
    'Inglés',
    'Portugués',
    'Francés',
    'Alemán',
    'Italiano',
    'Chino',
    'Árabe',
    'Japonés',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar idioma'),
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
                if (_showNameError) setState(() => _showNameError = false);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() {
                        _nameCtrl.text = s;
                        _showNameError = false;
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LanguageLevel>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Nivel'),
              items: LanguageLevel.values
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
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
          child: const Text('Cancelar'),
        ),
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
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ── Paso 6: Preferencias laborales ───────────────────────────────────────────

class _Step7WorkPreferences extends StatefulWidget {
  final Set<WorkModality> preferredModalities;
  final TextEditingController salaryCtrl;
  final TextEditingController commuteCtrl;
  final String currency;
  final bool salaryNegotiable;
  final bool hasOwnVehicle;
  final List<String> excludedIndustries;
  final List<String> excludedCompanies;
  final ValueChanged<Set<WorkModality>> onModalitiesChanged;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<bool> onSalaryNegotiableChanged;
  final ValueChanged<bool> onHasVehicleChanged;
  final ValueChanged<List<String>> onExcludedIndustriesChanged;
  final ValueChanged<List<String>> onExcludedCompaniesChanged;
  final VoidCallback onNext;

  const _Step7WorkPreferences({
    required this.preferredModalities,
    required this.salaryCtrl,
    required this.commuteCtrl,
    required this.currency,
    required this.salaryNegotiable,
    required this.hasOwnVehicle,
    required this.excludedIndustries,
    required this.excludedCompanies,
    required this.onModalitiesChanged,
    required this.onCurrencyChanged,
    required this.onSalaryNegotiableChanged,
    required this.onHasVehicleChanged,
    required this.onExcludedIndustriesChanged,
    required this.onExcludedCompaniesChanged,
    required this.onNext,
  });

  @override
  State<_Step7WorkPreferences> createState() => _Step7WorkPreferencesState();
}

class _Step7WorkPreferencesState extends State<_Step7WorkPreferences> {
  final _industryCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  @override
  void dispose() {
    _industryCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  void _addIndustry() {
    final v = _industryCtrl.text.trim();
    if (v.isEmpty) return;
    widget.onExcludedIndustriesChanged([...widget.excludedIndustries, v]);
    _industryCtrl.clear();
  }

  void _addCompany() {
    final v = _companyCtrl.text.trim();
    if (v.isEmpty) return;
    widget.onExcludedCompaniesChanged([...widget.excludedCompanies, v]);
    _companyCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final showCommute =
        widget.preferredModalities.contains(WorkModality.hybrid) ||
        widget.preferredModalities.contains(WorkModality.onsite);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Preferencias laborales',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Estos datos ayudan a la IA a encontrar ofertas más compatibles con vos.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Modalidad de trabajo',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: WorkModality.values.map((m) {
            final isSelected = widget.preferredModalities.contains(m);
            return FilterChip(
              label: Text(m.label),
              selected: isSelected,
              onSelected: (_) {
                final updated = Set<WorkModality>.from(
                  widget.preferredModalities,
                );
                if (isSelected) {
                  updated.remove(m);
                } else {
                  updated.add(m);
                }
                widget.onModalitiesChanged(updated);
              },
            );
          }).toList(),
        ),

        if (showCommute) ...[
          const SizedBox(height: 16),
          TextField(
            controller: widget.commuteCtrl,
            decoration: const InputDecoration(
              labelText: 'Distancia máxima de viaje (km)',
            ),
            keyboardType: TextInputType.number,
          ),
        ],

        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tengo vehículo propio'),
          value: widget.hasOwnVehicle,
          onChanged: widget.onHasVehicleChanged,
        ),

        const SizedBox(height: 16),
        Text(
          'Pretensión salarial (opcional)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.currency,
                    isExpanded: true,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'ARS', child: Text('ARS')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: (v) {
                      if (v != null) widget.onCurrencyChanged(v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.salaryCtrl,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Es negociable'),
          value: widget.salaryNegotiable,
          onChanged: (v) => widget.onSalaryNegotiableChanged(v ?? true),
        ),

        const SizedBox(height: 24),
        Text(
          'Industrias a excluir (opcional)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Ofertas de estos rubros no aparecerán en tus sugerencias.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.excludedIndustries.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.excludedIndustries
                .map(
                  (s) => Chip(
                    label: Text(s),
                    onDeleted: () => widget.onExcludedIndustriesChanged(
                      widget.excludedIndustries.where((x) => x != s).toList(),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _industryCtrl,
                decoration: const InputDecoration(
                  hintText: 'ej: Banca, Minería...',
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addIndustry(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _industryCtrl,
              builder: (_, val, _) => IconButton.outlined(
                onPressed: val.text.trim().isEmpty ? null : _addIndustry,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Text(
          'Empresas a excluir (opcional)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'No verás ofertas de estas empresas.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.excludedCompanies.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.excludedCompanies
                .map(
                  (s) => Chip(
                    label: Text(s),
                    onDeleted: () => widget.onExcludedCompaniesChanged(
                      widget.excludedCompanies.where((x) => x != s).toList(),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  hintText: 'ej: Empresa XYZ...',
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _addCompany(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _companyCtrl,
              builder: (_, val, _) => IconButton.outlined(
                onPressed: val.text.trim().isEmpty ? null : _addCompany,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.onNext,
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: widget.onNext,
          child: const Text('Saltar por ahora'),
        ),
      ],
    );
  }
}

// ── Paso 7: Links y certificaciones ──────────────────────────────────────────

class _Step8LinksAndCerts extends StatelessWidget {
  final TextEditingController linkedInCtrl;
  final TextEditingController githubCtrl;
  final TextEditingController portfolioCtrl;
  final List<Certification> certifications;
  final Function(List<Certification>) onCertificationsChanged;
  final VoidCallback onNext;

  const _Step8LinksAndCerts({
    required this.linkedInCtrl,
    required this.githubCtrl,
    required this.portfolioCtrl,
    required this.certifications,
    required this.onCertificationsChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Links y certificaciones',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Agregá tus perfiles profesionales y certificaciones relevantes.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: linkedInCtrl,
          decoration: const InputDecoration(
            labelText: 'LinkedIn URL (opcional)',
            hintText: 'https://linkedin.com/in/tu-perfil',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: githubCtrl,
          decoration: const InputDecoration(
            labelText: 'GitHub URL (opcional)',
            hintText: 'https://github.com/tu-usuario',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: portfolioCtrl,
          decoration: const InputDecoration(
            labelText: 'Portfolio o web personal (opcional)',
            hintText: 'https://tu-portfolio.com',
          ),
          keyboardType: TextInputType.url,
        ),

        const SizedBox(height: 24),
        Text('Certificaciones', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ...certifications.map(
          (c) => Card(
            child: ListTile(
              title: Text(c.name),
              subtitle: Text('${c.issuer} · ${c.year}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onCertificationsChanged(
                  certifications.where((x) => x.id != c.id).toList(),
                ),
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _CertificationDialog(
              onAdd: (cert) =>
                  onCertificationsChanged([...certifications, cert]),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Agregar certificación'),
        ),

        const SizedBox(height: 32),
        ElevatedButton(onPressed: onNext, child: const Text('Continuar')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onNext,
          child: const Text('Saltar por ahora'),
        ),
      ],
    );
  }
}

class _CertificationDialog extends StatefulWidget {
  final ValueChanged<Certification> onAdd;
  const _CertificationDialog({required this.onAdd});

  @override
  State<_CertificationDialog> createState() => _CertificationDialogState();
}

class _CertificationDialogState extends State<_CertificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _issuerCtrl = TextEditingController();
  bool _autovalidate = false;
  late int _year = DateTime.now().year;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _issuerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar certificación'),
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
                  labelText: 'Institución emisora *',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _YearPicker(
                label: 'Año de obtención',
                year: _year,
                onChanged: (y) => setState(() => _year = y),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                Certification(
                  id: const Uuid().v4(),
                  name: _nameCtrl.text.trim(),
                  issuer: _issuerCtrl.text.trim(),
                  year: _year,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ── Paso 8: Finalizar ─────────────────────────────────────────────────────────

class _Step9Finish extends StatefulWidget {
  final Future<void> Function() onFinish;
  const _Step9Finish({required this.onFinish});

  @override
  State<_Step9Finish> createState() => _Step9FinishState();
}

class _Step9FinishState extends State<_Step9Finish> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: Color(0xFF0E9F6E),
          ),
          const SizedBox(height: 24),
          Text(
            StringsEs.onboardingPaso5Titulo,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            StringsEs.onboardingCompletado,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      await widget.onFinish();
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('¡Empezar a buscar trabajo!'),
          ),
        ],
      ),
    );
  }
}

// ── Paso 6: Proyectos ─────────────────────────────────────────────────────────

class _Step6Projects extends StatelessWidget {
  final List<Project> projects;
  final Function(List<Project>) onChanged;
  final VoidCallback onNext;

  const _Step6Projects({
    required this.projects,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Tus proyectos destacados',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Proyectos personales, freelance o académicos que muestren tus habilidades.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        ...projects.map(
          (p) => Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text(
                p.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    onChanged(projects.where((x) => x.id != p.id).toList()),
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) =>
                _ProjectDialog(onAdd: (proj) => onChanged([...projects, proj])),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Agregar proyecto'),
        ),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: onNext, child: const Text('Continuar')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            onChanged([]);
            onNext();
          },
          child: const Text('Saltar por ahora'),
        ),
      ],
    );
  }
}

class _ProjectDialog extends StatefulWidget {
  final ValueChanged<Project> onAdd;
  const _ProjectDialog({required this.onAdd});

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  final _techCtrl = TextEditingController();
  bool _autovalidate = false;

  List<String> _technologies = [];
  bool _isCurrent = false;
  int? _startMonth;
  int? _startYear;
  int? _endMonth;
  int? _endYear;

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
      title: const Text('Agregar proyecto'),
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
                decoration: const InputDecoration(
                  labelText: 'Nombre del proyecto *',
                ),
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
              Text(
                'Tecnologías usadas',
                style: Theme.of(context).textTheme.labelMedium,
              ),
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
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          onDeleted: () => setState(
                            () => _technologies = _technologies
                                .where((x) => x != t)
                                .toList(),
                          ),
                        ),
                      )
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
                onChanged: (m, y) => setState(() {
                  _startMonth = m;
                  _startYear = y;
                }),
              ),
              if (!_isCurrent) ...[
                const SizedBox(height: 8),
                _MonthYearPicker(
                  label: 'Fecha de fin (opcional)',
                  month: _endMonth ?? now.month,
                  year: _endYear ?? now.year,
                  onChanged: (m, y) => setState(() {
                    _endMonth = m;
                    _endYear = y;
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                Project(
                  id: const Uuid().v4(),
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
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
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
  final void Function(int month, int year) onChanged;

  const _MonthYearPicker({
    required this.label,
    required this.month,
    required this.year,
    required this.onChanged,
  });

  static const _monthLabels = [
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

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    // Range: current year down to 1960
    final years = List.generate(currentYear - 1960 + 1, (i) => currentYear - i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Month: narrower
            Expanded(
              flex: 2,
              child: _StyledDropdown<int>(
                value: month,
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_monthLabels[i]),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) onChanged(v, year);
                },
              ),
            ),
            const SizedBox(width: 8),
            // Year: wider
            Expanded(
              flex: 3,
              child: _StyledDropdown<int>(
                value: year,
                items: years
                    .map(
                      (y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())),
                    )
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
    final currentYear = DateTime.now().year;
    // Range: current year down to 1955 (long academic careers)
    final years = List.generate(currentYear - 1955 + 1, (i) => currentYear - i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        _StyledDropdown<int>(
          value: year,
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

/// `DropdownButton` wrapped in an `InputDecorator` for form-field appearance.
/// Uses the non-deprecated `DropdownButton.value` (controlled) API.
class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
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
