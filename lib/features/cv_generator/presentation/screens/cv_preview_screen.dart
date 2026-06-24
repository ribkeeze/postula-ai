import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/strings_es.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/usage_gate.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/presentation/screens/paywall_screen.dart';
import '../../../evaluation/presentation/providers/evaluation_provider.dart';
import '../providers/cv_provider.dart';
import '../../domain/entities/generated_cv.dart';

class CvPreviewScreen extends ConsumerStatefulWidget {
  final String applicationId;
  const CvPreviewScreen({super.key, required this.applicationId});

  @override
  ConsumerState<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends ConsumerState<CvPreviewScreen> {
  bool _isGeneratingPdf = false;

  Future<List<int>> _buildPdf(GeneratedCv cv, UserProfile? profile) async {
    final pdf = pw.Document();
    final name = _sanitizeForPdf(profile?.personalInfo.fullName ?? '');
    final location = _formatLocation(profile?.personalInfo);
    final contactParts = _sanitizeForPdf(
      [
        profile?.personalInfo.email ?? '',
        if (profile?.personalInfo.phone?.isNotEmpty == true)
          profile!.personalInfo.phone!,
        if (location.isNotEmpty) location,
      ].where((s) => s.isNotEmpty).join(' - '),
    );
    final linkedIn = profile?.linkedIn;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context ctx) {
          final widgets = <pw.Widget>[];

          // Header
          widgets.add(
            pw.Text(
              name,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          );
          // Contact line
          if (contactParts.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(
              pw.Text(
                contactParts,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            );
          }
          // LinkedIn on its own line
          if (linkedIn != null && linkedIn.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 2));
            widgets.add(
              pw.Text(
                _sanitizeForPdf(linkedIn),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blue700,
                ),
              ),
            );
          }
          // CV links (LinkedIn, GitHub, Portfolio from generated CV)
          for (final link in cv.links.where((l) => l.url.isNotEmpty)) {
            widgets.add(pw.SizedBox(height: 2));
            widgets.add(
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: '${_sanitizeForPdf(link.label)}: ',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.TextSpan(
                      text: _sanitizeForPdf(link.url),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.blue700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Divider(thickness: 1, color: PdfColors.grey400));
          widgets.add(pw.SizedBox(height: 10));

          // Resumen Profesional
          widgets.addAll(
            _pdfSection('Resumen Profesional', [
              pw.Text(
                _sanitizeForPdf(cv.personalizedSummary),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ]),
          );

          // Experiencia Laboral
          if (cv.workExperience.isNotEmpty) {
            widgets.addAll(
              _pdfSection('Experiencia Laboral', [
                for (final entry in cv.workExperience) ...[
                  pw.Text(
                    _sanitizeForPdf('${entry.position} - ${entry.company}'),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _sanitizeForPdf(entry.period),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  for (final bullet in entry.bullets)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('- ', style: const pw.TextStyle(fontSize: 10)),
                        pw.Expanded(
                          child: pw.Text(
                            _sanitizeForPdf(_stripBullet(bullet)),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 6),
                ],
              ]),
            );
          }

          // Educacion
          if (cv.education.isNotEmpty) {
            widgets.addAll(
              _pdfSection('Educacion', [
                for (final entry in cv.education) ...[
                  pw.Text(
                    _sanitizeForPdf(
                      _cvEducationTitle(entry.degree, entry.field),
                    ),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _sanitizeForPdf('${entry.institution} - ${entry.period}'),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                ],
              ]),
            );
          }

          // Certificaciones
          if (cv.certifications.isNotEmpty) {
            widgets.addAll(
              _pdfSection('Certificaciones', [
                for (final cert in cv.certifications) ...[
                  pw.Text(
                    _sanitizeForPdf(
                      '${cert.name} - ${cert.issuer} (${cert.year})',
                    ),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (cert.url != null && cert.url!.isNotEmpty)
                    pw.Text(
                      _sanitizeForPdf(cert.url!),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.blue700,
                      ),
                    ),
                  pw.SizedBox(height: 4),
                ],
              ]),
            );
          }

          // Habilidades
          if (cv.skillsHighlighted.isNotEmpty) {
            widgets.addAll(
              _pdfSection('Habilidades', [
                pw.Text(
                  _sanitizeForPdf(cv.skillsHighlighted.join(', ')),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ]),
            );
          }

          // Idiomas
          if (cv.languages.isNotEmpty) {
            widgets.addAll(
              _pdfSection('Idiomas', [
                for (final lang in cv.languages)
                  pw.Text(
                    '- ${_sanitizeForPdf(lang)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ]),
            );
          }

          // Proyectos Destacados
          if (cv.projects.isNotEmpty) {
            widgets.addAll(
              _pdfSection('Proyectos Destacados', [
                for (final p in cv.projects) ...[
                  pw.Text(
                    _sanitizeForPdf(p.name),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (p.context != null || p.period != null)
                    pw.Text(
                      _sanitizeForPdf(
                        [
                          if (p.context != null) p.context!,
                          if (p.period != null) p.period!,
                        ].join(' - '),
                      ),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  if (p.technologies.isNotEmpty)
                    pw.Text(
                      _sanitizeForPdf(
                        'Tecnologias: ${p.technologies.join(", ")}',
                      ),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  if (p.url != null && p.url!.isNotEmpty)
                    pw.Text(
                      _sanitizeForPdf(p.url!),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.blue700,
                      ),
                    ),
                  pw.SizedBox(height: 3),
                  for (final bullet in p.bullets)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('- ', style: const pw.TextStyle(fontSize: 10)),
                        pw.Expanded(
                          child: pw.Text(
                            _sanitizeForPdf(_stripBullet(bullet)),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 6),
                ],
              ]),
            );
          }

          // Referencias
          if (cv.references.isNotEmpty) {
            widgets.addAll(
              _pdfSection('Referencias', [
                for (final ref in cv.references) ...[
                  pw.Text(
                    _sanitizeForPdf(
                      '${ref.name} - ${ref.position}, ${ref.company}',
                    ),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _sanitizeForPdf(ref.contact),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                ],
              ]),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _pdfSection(String title, List<pw.Widget> children) {
    return [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
      pw.Divider(thickness: 0.5, color: PdfColors.blue200),
      pw.SizedBox(height: 6),
      ...children,
      pw.SizedBox(height: 12),
    ];
  }

  String _sanitizeFilename(String text) {
    // Remove or replace invalid filename characters
    return text
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(' ', '_')
        .replaceAll(
          RegExp(r'_+'),
          '_',
        ) // Replace multiple underscores with single
        .toLowerCase();
  }

  String _buildCvFilename(String? fullName, String? jobTitle, String? company) {
    final name = _sanitizeFilename(fullName ?? 'CV');
    final position = _sanitizeFilename(jobTitle ?? 'posicion');
    final empresa = _sanitizeFilename(company ?? 'empresa');
    return 'CV_${name}_${position}_$empresa.pdf';
  }

  Future<void> _generateAndSharePdf(
    BuildContext context,
    GeneratedCv cv,
    UserProfile? profile,
  ) async {
    if (_isGeneratingPdf) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isGeneratingPdf = true);
    try {
      // Fetch evaluation data for filename
      final evalAsyncValue = await ref.read(
        evaluationByIdProvider(widget.applicationId).future,
      );
      final jobTitle = evalAsyncValue.jobTitle;
      final company = evalAsyncValue.company;

      final pdfBytes = await _buildPdf(cv, profile);
      final tempDir = await getTemporaryDirectory();
      final filename = _buildCvFilename(
        profile?.personalInfo.fullName,
        jobTitle,
        company,
      );
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'CV - ${profile?.personalInfo.fullName ?? ""}',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Algo salió mal al generar el PDF. Intentá de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _generateAndDownloadPdf(
    BuildContext context,
    GeneratedCv cv,
    UserProfile? profile,
  ) async {
    if (_isGeneratingPdf) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isGeneratingPdf = true);
    try {
      final evalAsyncValue = await ref.read(
        evaluationByIdProvider(widget.applicationId).future,
      );
      final jobTitle = evalAsyncValue.jobTitle;
      final company = evalAsyncValue.company;

      final pdfBytes = await _buildPdf(cv, profile);
      final filename = _buildCvFilename(
        profile?.personalInfo.fullName,
        jobTitle,
        company,
      );

      await FlutterFileSaver().writeFileAsBytes(
        fileName: filename,
        bytes: Uint8List.fromList(pdfBytes),
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('PDF guardado: $filename')),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Algo salió mal al guardar el PDF. Intentá de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  String _formatLocation(PersonalInfo? info) {
    if (info == null) return '';
    final parts = <String>[];
    if (info.city.isNotEmpty) parts.add(info.city);
    if (info.provincia?.isNotEmpty == true) {
      if (info.postalCode?.isNotEmpty == true) {
        parts.add('${info.provincia} CP ${info.postalCode}');
      } else {
        parts.add(info.provincia!);
      }
    }
    if (info.country.isNotEmpty) parts.add(info.country);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final cvState = ref.watch(cvProvider(widget.applicationId));
    final canGenerate = ref.watch(canGenerateCvProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text(StringsEs.cvTitulo)),
      body: cvState.when(
        data: (cv) {
          if (cv == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    StringsEs.cvSubtitulo,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  UsageGate(
                    trigger: PaywallTrigger.cvGeneration,
                    canUse: canGenerate,
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(cvProvider(widget.applicationId).notifier)
                          .generate(widget.applicationId),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generar CV con IA'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const UsageChip(trigger: PaywallTrigger.cvGeneration),
                ],
              ),
            );
          }

          // CV generado — mostrar preview
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Contacto
              _ContactHeader(profile: profile),
              if (cv.links.any((l) => l.url.isNotEmpty)) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: cv.links
                        .where((l) => l.url.isNotEmpty)
                        .map(
                          (l) => GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse(l.url),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              l.label,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Resumen profesional
              _CvSection(
                title: 'Resumen Profesional',
                child: Text(
                  cv.personalizedSummary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),

              // Experiencia laboral
              if (cv.workExperience.isNotEmpty) ...[
                _CvSection(
                  title: 'Experiencia Laboral',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cv.workExperience
                        .map((e) => _WorkEntryWidget(entry: e))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Educación
              if (cv.education.isNotEmpty) ...[
                _CvSection(
                  title: 'Educación',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cv.education
                        .map((e) => _EducationEntryWidget(entry: e))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Certificaciones
              if (cv.certifications.isNotEmpty) ...[
                _CvSection(
                  title: 'Certificaciones',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cv.certifications
                        .map((c) => _CertificationEntryWidget(entry: c))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Habilidades
              if (cv.skillsHighlighted.isNotEmpty) ...[
                _CvSection(
                  title: 'Habilidades',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cv.skillsHighlighted
                        .map((s) => Chip(label: Text(s)))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Idiomas
              if (cv.languages.isNotEmpty) ...[
                _CvSection(
                  title: 'Idiomas',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cv.languages
                        .map(
                          (l) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              l,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Proyectos Destacados
              if (cv.projects.isNotEmpty) ...[
                _CvSection(
                  title: 'Proyectos Destacados',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cv.projects
                        .map((p) => _ProjectEntryWidget(entry: p))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Referencias
              if (cv.references.isNotEmpty) ...[
                _CvSection(
                  title: 'Referencias',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cv.references
                        .map((r) => _ReferenceEntryWidget(entry: r))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Keywords
              if (cv.keywordsUsed.isNotEmpty) ...[
                Text(
                  'Keywords incluidas del aviso: ${cv.keywordsUsed.join(", ")}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingPdf
                          ? null
                          : () => _generateAndSharePdf(context, cv, profile),
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      label: const Text(StringsEs.cvCompartir),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: _isGeneratingPdf
                        ? null
                        : () => _generateAndDownloadPdf(context, cv, profile),
                    icon: const Icon(Icons.download),
                    tooltip: 'Descargar PDF',
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: () => ref
                        .read(cvProvider(widget.applicationId).notifier)
                        .generate(widget.applicationId),
                    icon: const Icon(Icons.refresh),
                    tooltip: StringsEs.cvRegenerarCV,
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: StringsEs.cvGenerando),
        error: (e, _) => ErrorRetryWidget(
          message: friendlyError(e),
          onRetry: () => ref
              .read(cvProvider(widget.applicationId).notifier)
              .generate(widget.applicationId),
        ),
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  final UserProfile? profile;
  const _ContactHeader({required this.profile});

  String _formatLocation(PersonalInfo info) {
    final parts = <String>[];
    if (info.city.isNotEmpty) parts.add(info.city);
    if (info.provincia?.isNotEmpty == true) {
      if (info.postalCode?.isNotEmpty == true) {
        parts.add('${info.provincia} CP ${info.postalCode}');
      } else {
        parts.add(info.provincia!);
      }
    }
    if (info.country.isNotEmpty) parts.add(info.country);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();
    final info = profile!.personalInfo;
    final location = _formatLocation(info);
    final contactParts = [
      info.email,
      if (info.phone?.isNotEmpty == true) info.phone!,
      if (location.isNotEmpty) location,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (contactParts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                contactParts,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (profile!.linkedIn?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                profile!.linkedIn!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CvSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _CvSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _WorkEntryWidget extends StatelessWidget {
  final CvWorkEntry entry;
  const _WorkEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.position} · ${entry.company}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            entry.period,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ...entry.bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(b)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectEntryWidget extends StatelessWidget {
  final CvProject entry;
  const _ProjectEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (entry.context != null) entry.context!,
      if (entry.period != null) entry.period!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.name, style: Theme.of(context).textTheme.titleSmall),
          if (meta.isNotEmpty)
            Text(
              meta,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (entry.technologies.isNotEmpty)
            Text(
              'Tecnologías: ${entry.technologies.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (entry.url != null && entry.url!.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(entry.url!),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                entry.url!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          if (entry.bullets.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...entry.bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('- ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EducationEntryWidget extends StatelessWidget {
  final CvEducationEntry entry;
  const _EducationEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cvEducationTitle(entry.degree, entry.field),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            '${entry.institution} · ${entry.period}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationEntryWidget extends StatelessWidget {
  final CvCertification entry;
  const _CertificationEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.name, style: Theme.of(context).textTheme.titleSmall),
          Text(
            '${entry.issuer} · ${entry.year}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (entry.url != null && entry.url!.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(entry.url!),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                entry.url!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReferenceEntryWidget extends StatelessWidget {
  final CvReference entry;
  const _ReferenceEntryWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.name, style: Theme.of(context).textTheme.titleSmall),
          Text(
            '${entry.position} · ${entry.company}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (entry.contact.isNotEmpty)
            Text(
              entry.contact,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

String _cvEducationTitle(String degree, String field) {
  if (field.isEmpty) return degree;
  if (degree.toLowerCase().contains(field.toLowerCase())) return degree;
  return '$degree ($field)';
}

String _sanitizeForPdf(String text) {
  return text
      .replaceAll('·', '-')
      .replaceAll('•', '-')
      .replaceAll('→', '-')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('·', '-')
      .replaceAll('•', '-')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll(' ', ' ')
      .replaceAll('​', '')
      .replaceAll('’', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"');
}

String _stripBullet(String text) {
  return text.replaceFirst(RegExp(r'^[•·▪▸→⟶\-–—\*]\s*'), '').trim();
}
