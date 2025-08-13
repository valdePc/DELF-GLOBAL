import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅
import 'airtable_service.dart'; // ✅ mismo folder 'screens'


class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});


@override
RecoveryScreenState createState() => RecoveryScreenState();

}

class RecoveryScreenState extends State<RecoveryScreen> {

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String phone = '';
  String newPassword = '';
  String confirmPassword = '';
  bool codeSent = false;
  bool isProcessing = false;

  Future<void> sendSmsCode() async {
    setState(() => codeSent = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Código de verificación enviado (simulado: 123456)')),
    );
  }

  bool verifySmsCode(String code) {
    return code == '123456';
  }

  Future<void> _recoverPassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (newPassword != confirmPassword) {
        _showMessage('Las contraseñas no coinciden');
        return;
      }

      if (!codeSent) {
        await sendSmsCode();
        return;
      }

      if (!verifySmsCode(_codeController.text.trim())) {
        _showMessage('Código de verificación incorrecto');
        return;
      }

      setState(() => isProcessing = true);
      final updated = await AirtableService.updatePassword(phone, newPassword);
      setState(() => isProcessing = false);

      if (updated) {
        _showMessage('Contraseña actualizada correctamente');
        if (mounted) Navigator.pop(context);
      } else {
        _showMessage('Error al actualizar la contraseña');
      }
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
  //  final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.loginTitle), // Puedes cambiarlo por localizations.recoverTitle
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: localizations.phoneNumber,
                  border: const OutlineInputBorder(),
                ),
                initialCountryCode: 'US',
                onChanged: (phoneNumber) => phone = phoneNumber.completeNumber,
                validator: (value) {
                  if (value == null || value.number.isEmpty) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (codeSent) ...[
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Verificación',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Ingrese el código de verificación' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSaved: (val) => newPassword = val ?? '',
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Ingrese la nueva contraseña';
                  }
                  if (val.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSaved: (val) => confirmPassword = val ?? '',
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Confirme la nueva contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              isProcessing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _recoverPassword,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('Recuperar Contraseña'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
