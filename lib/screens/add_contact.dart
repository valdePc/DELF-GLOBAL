// lib/screens/add_contact.dart — FIX: asegura chats/{chatId}.participants y chatId determinístico
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:delf_global/services/user_directory.dart';
import 'package:delf_global/app_config.dart' show buildInviteUrl;

import 'chat_screen.dart';

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

  Future<void> _inviteDialog(String inviteUrl) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No está en la app'),
        content: const Text('Para poder chatear debe registrarse. ¿Copiar enlace de invitación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inviteUrl));
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enlace copiado')),
                );
              }
            },
            child: const Text('Copiar enlace'),
          ),
        ],
      ),
    );
  }

  Future<String?> _fallbackResolveUid({
    String? emailLower,
    String? phoneE164,
    String? legacyPhoneRaw,
  }) async {
    try {
      final col = FirebaseFirestore.instance.collection('users');

      if (emailLower != null && emailLower.isNotEmpty) {
        final q = await col.where('emailLower', isEqualTo: emailLower).limit(1).get();
        if (q.docs.isNotEmpty) return q.docs.first.id;
      }
      if (phoneE164 != null && phoneE164.isNotEmpty) {
        final q = await col.where('phoneE164', isEqualTo: phoneE164).limit(1).get();
        if (q.docs.isNotEmpty) return q.docs.first.id;
      }
      if (legacyPhoneRaw != null && legacyPhoneRaw.isNotEmpty) {
        final q = await col.where('phone', isEqualTo: legacyPhoneRaw).limit(1).get();
        if (q.docs.isNotEmpty) return q.docs.first.id;
      }
    } catch (_) {}
    return null;
  }

  // ID determinístico para 1-a-1: UIDs ordenados y unidos por "_"
  String _pairChatId(String a, String b) {
    final xs = [a, b]..sort();
    return '${xs[0]}_${xs[1]}';
  }

  // Garantiza que el doc chats/{chatId} tenga participants y timestamps
  Future<void> _ensureChatRoot(String chatId, String uidA, String uidB, {
    String? nameForB,
    String? phoneForB,
  }) async {
    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await ref.set({
      'id': chatId,
      'participants': [uidA, uidB],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // Datos opcionales para listados/UX (no afectan reglas)
      if (nameForB != null) 'nameMap': {uidB: nameForB},
      if (phoneForB != null) 'phoneMap': {uidB: phoneForB},
    }, SetOptions(merge: true));
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes registrarte para continuar.')),
      );
      return;
    }

    final genericError = _validatePhoneOrEmail();
    if (!_formKey.currentState!.validate() || genericError != null) {
      if (genericError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(genericError)));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Datos
      final name = _nameCtrl.text.trim();
      final rawPhone = _phoneCtrl.text.trim();
      final String? phoneE164 = _phoneE164.isNotEmpty ? _phoneE164 : (rawPhone.isEmpty ? null : _toE164ish(rawPhone));
      final String? emailLower = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim().toLowerCase();

      // 2) Guardado local (libreta)
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
        list.add({'id': id, 'name': name, 'phone': phoneE164 ?? rawPhone, 'email': emailLower, 'avatarUrl': ''});
        await prefs.setString('contacts', json.encode(list));
      }

      // 3) Resolver UID del otro usuario (debe ser UID de Firebase Auth)
      String? otherUid = await UserDirectory.resolveUidByHandle(phone: phoneE164, email: emailLower);
      if (otherUid == null) {
        otherUid = await _fallbackResolveUid(
          emailLower: emailLower,
          phoneE164: phoneE164,
          legacyPhoneRaw: rawPhone,
        );
      }

      // 4) Si no existe -> invitar
      if (otherUid == null) {
        final inviteUrl = buildInviteUrl(user.uid);
        await _inviteDialog(inviteUrl);
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      // 4.1) Evitar chat contigo mismo
      if (otherUid == user.uid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes iniciar un chat contigo mismo.')),
        );
        return;
      }

// 5) NO crear chat ni navegar. Solo volver para que principal.dart refresque y muestre el contacto.
//    El chat se crea/abre cuando toques el contacto desde la lista.
if (!mounted) return;
Navigator.pop(context, true);


    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('permission-denied')
          ? 'Permiso denegado. Verifica tu sesión y reglas.'
          : 'Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                    icon: const Icon(Icons.chat),
                    label: _saving ? const Text('Procesando...') : const Text('Guardar contacto'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Solo podrás chatear si la otra persona ya está registrada.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
