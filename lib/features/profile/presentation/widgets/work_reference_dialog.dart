import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_profile.dart';

class WorkReferenceDialog extends StatefulWidget {
  const WorkReferenceDialog({super.key});

  @override
  State<WorkReferenceDialog> createState() => _WorkReferenceDialogState();
}

class _WorkReferenceDialogState extends State<WorkReferenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _posCtrl = TextEditingController();
  final _compCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _autovalidate = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _posCtrl.dispose();
    _compCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar referencia'),
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
                    const InputDecoration(labelText: 'Nombre completo *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _posCtrl,
                decoration: const InputDecoration(labelText: 'Cargo *'),
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
                controller: _phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration:
                    const InputDecoration(labelText: 'Email (opcional)'),
                keyboardType: TextInputType.emailAddress,
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
              Navigator.pop(
                context,
                WorkReference(
                  id: const Uuid().v4(),
                  name: _nameCtrl.text.trim(),
                  position: _posCtrl.text.trim(),
                  company: _compCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim().isEmpty
                      ? null
                      : _phoneCtrl.text.trim(),
                  email: _emailCtrl.text.trim().isEmpty
                      ? null
                      : _emailCtrl.text.trim(),
                ),
              );
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
