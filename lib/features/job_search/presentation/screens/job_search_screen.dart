import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../job_search/domain/entities/job_portal.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

const _defaultPortals = [
  JobPortal(
    id: 'bumeran',
    name: 'Bumeran',
    url:
        'https://www.bumeran.com.ar/empleos-busqueda-{query}.html',
    isDefault: true,
  ),
  JobPortal(
    id: 'zonajobs',
    name: 'ZonaJobs',
    url:
        'https://www.zonajobs.com.ar/empleos-busqueda-{query}.html',
    isDefault: true,
  ),
  JobPortal(
    id: 'linkedin',
    name: 'LinkedIn Jobs',
    url:
        'https://www.linkedin.com/jobs/search/?keywords={query}',
    isDefault: true,
  ),
  JobPortal(
    id: 'computrabajo',
    name: 'Computrabajo',
    url:
        'https://www.computrabajo.com.ar/trabajo-de-{query}',
    isDefault: true,
  ),
  JobPortal(
    id: 'getonboard',
    name: 'GetOnBoard',
    url: 'https://www.getonbrd.com/jobs-{query}',
    isDefault: true,
  ),
];

class JobSearchScreen extends ConsumerStatefulWidget {
  const JobSearchScreen({super.key});

  @override
  ConsumerState<JobSearchScreen> createState() =>
      _JobSearchScreenState();
}

class _JobSearchScreenState
    extends ConsumerState<JobSearchScreen> {
  List<JobPortal> _portals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPortals();
  }

  Future<void> _loadPortals() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          setState(() {
            _portals = List.from(_defaultPortals);
            _loading = false;
          });
        }
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null && data['jobPortals'] != null) {
        final saved = (data['jobPortals'] as List)
            .map((e) => JobPortal.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
        if (mounted) {
          setState(() {
            _portals = saved;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _portals = List.from(_defaultPortals);
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _portals = List.from(_defaultPortals);
          _loading = false;
        });
      }
    }
  }

  Future<void> _savePortals() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .update({
        'jobPortals':
            _portals.map((p) => p.toJson()).toList()
      });
    } catch (_) {}
  }

  String _domainOf(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  void _showSearchSheet(BuildContext context,
      JobPortal portal, List<String> allSkills) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SearchSheet(
          portal: portal, allSkills: allSkills),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final profile =
        ref.watch(userProfileProvider).asData?.value;
    final allSkills = profile?.skills.toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar empleo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Portales de empleo',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._portals.map((portal) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  portal.name,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 15),
                                ),
                                Text(
                                  _domainOf(portal.url),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                                context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (!portal.isDefault)
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20),
                              onPressed: () {
                                setState(() => _portals
                                    .removeWhere((p) =>
                                        p.id == portal.id));
                                _savePortals();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showSearchSheet(
                              context, portal, allSkills),
                          child: const Text('Visitar'),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPortalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar portal'),
      ),
    );
  }

  void _showAddPortalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddPortalDialog(
        onAdd: (portal) {
          setState(() => _portals.add(portal));
          _savePortals();
        },
      ),
    );
  }
}

// ── Search bottom sheet ───────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  final JobPortal portal;
  final List<String> allSkills;
  const _SearchSheet(
      {required this.portal, required this.allSkills});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late Set<String> _selectedSkills;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSkills = Set.from(widget.allSkills);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final custom = _customCtrl.text.trim();
    final query = custom.isNotEmpty
        ? custom
        : _selectedSkills.join(' ');
    if (query.isEmpty) return;
    final urlStr = widget.portal.url
        .replaceAll('{query}', Uri.encodeComponent(query));
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _customCtrl.text.trim().isNotEmpty ||
        _selectedSkills.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué buscás?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'en ${widget.portal.name}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            if (widget.allSkills.isNotEmpty) ...[
              Text(
                'Tus habilidades',
                style:
                    Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.allSkills.map((s) {
                  final isSelected =
                      _selectedSkills.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      if (isSelected) {
                        _selectedSkills.remove(s);
                      } else {
                        _selectedSkills.add(s);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _customCtrl,
              decoration: const InputDecoration(
                labelText:
                    'O escribí una búsqueda personalizada',
                hintText:
                    'ej: Desarrollador Flutter senior...',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSearch ? _search : null,
                child: const Text('Buscar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add portal dialog ─────────────────────────────────────────────────────────

class _AddPortalDialog extends StatefulWidget {
  final ValueChanged<JobPortal> onAdd;
  const _AddPortalDialog({required this.onAdd});

  @override
  State<_AddPortalDialog> createState() =>
      _AddPortalDialogState();
}

class _AddPortalDialogState
    extends State<_AddPortalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _autovalidate = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar portal'),
      content: Form(
        key: _formKey,
        autovalidateMode: _autovalidate
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? 'Requerido'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL de búsqueda *',
                helperText:
                    'Usá {query} donde va la búsqueda',
              ),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Requerido';
                if (!v.contains('{query}')) {
                  return 'Debe incluir {query}';
                }
                return null;
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
            setState(() => _autovalidate = true);
            if (_formKey.currentState!.validate()) {
              widget.onAdd(JobPortal(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: _nameCtrl.text.trim(),
                url: _urlCtrl.text.trim(),
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
