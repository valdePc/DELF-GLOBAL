import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _guardarContacto() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    // Prepara el nuevo contacto
    final newContact = {
      'id': _uuid.v4(),
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'avatarUrl': '' // Puedes permitir más adelante elegir foto
    };

    // Carga lista existente
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('contacts');
    final List<Map<String, dynamic>> list = raw != null
        ? (json.decode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    // Añade y guarda
    list.add(newContact);
    await prefs.setString('contacts', json.encode(list));

    // Confirmación y regreso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.successSave)),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.addContact)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: localizations.fullName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return localizations.registerEnterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: localizations.phoneNumber,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return localizations.registerEnterPhone;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _guardarContacto,
              icon: const Icon(Icons.save),
              label: Text(localizations.saveChanges),
            ),
          ]),
        ),
      ),
    );
  }
}
