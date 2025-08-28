// lib/screens/add_contact.dart — versión simple: guarda contacto local y regresa
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({Key? key}) : super(key: key);

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _saving = false;
  String _phoneE164 = '';

  @override
  void initState() {
    super.initState();
    // Si llegan argumentos con datos (por enlace), prellenar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        if (args['name'] is String) _nameCtrl.text = (args['name'] as String).trim();
        if (args['email'] is String) _emailCtrl.text = (args['email'] as String).trim();
        if (args['phone'] is String) {
          _phoneCtrl.text = (args['phone'] as String).trim();
          _phoneE164 = _toE164ish(_phoneCtrl.text);
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // Normaliza "+1 809-555-1234" -> "+18095551234"
  String _toE164ish(String input) {
    final s = input.replaceAll(RegExp(r'\s|-|\(|\)'), '');
    if (s.isEmpty) return s;
    return s.startsWith('+') ? s : '+$s';
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa el nombre';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  String? _validatePhoneOrEmail() {
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (phone.isEmpty && email.isEmpty) return 'Ingresa teléfono o email';
    if (email.isNotEmpty) {
      final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      if (!ok) return 'Email inválido';
    }
    if (phone.isNotEmpty && phone.replaceAll(RegExp(r'\D'), '').length < 6) {
      return 'Teléfono inválido';
    }
    return null;
  }

  Future<void> _save() async {
    final genericError = _validatePhoneOrEmail();
    if (!_formKey.currentState!.validate() || genericError != null) {
      if (genericError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(genericError)));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final rawPhone = _phoneCtrl.text.trim();
      final String? phoneE164 = _phoneE164.isNotEmpty
          ? _phoneE164
          : (rawPhone.isEmpty ? null : _toE164ish(rawPhone));
      final String? emailLower =
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim().toLowerCase();

      // Libreta local
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('contacts');
      final List<Map<String, dynamic>> list = raw == null
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(json.decode(raw) as List);

      final existsLocal = list.any((c) {
        final p = (c['phone'] as String?)?.trim();
        final e = (c['email'] as String?)?.trim();
        final pE164 = (p == null || p.isEmpty) ? null : _toE164ish(p);
        final samePhone = (phoneE164 != null && pE164 != null && pE164 == phoneE164);
        final sameEmail = (emailLower != null && e != null && e.toLowerCase() == emailLower);
        return samePhone || sameEmail;
      });

      if (!existsLocal) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        list.add({
          'id': id,
          'name': name,
          'phone': phoneE164 ?? rawPhone,
          'email': emailLower,
          'avatarUrl': '',
        });
        await prefs.setString('contacts', json.encode(list));
      }

      if (!mounted) return;
      // No navegamos al chat. Volvemos para que principal.dart recargue y muestre el contacto.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar contacto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                IntlPhoneField(
                  initialValue: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : null,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    hintText: '+1 555 123 4567',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'US',
                  onChanged: (pn) {
                    _phoneCtrl.text = pn.completeNumber;
                    _phoneE164 = _toE164ish(pn.completeNumber);
                  },
                  onCountryChanged: (_) {
                    if (_phoneCtrl.text.trim().isNotEmpty) {
                      _phoneE164 = _toE164ish(_phoneCtrl.text.trim());
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email (opcional)',
                    hintText: 'nombre@dominio.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: _saving
                        ? const Text('Procesando...')
                        : const Text('Guardar contacto'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Luego toca el contacto en la lista para abrir o crear el chat.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

