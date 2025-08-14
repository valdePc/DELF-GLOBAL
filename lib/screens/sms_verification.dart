import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'principal.dart';

class SmsVerificationScreen extends StatefulWidget {
  final String fullName;
  final String phone;
  final DateTime? birthdate;
  final String password;        // validación local únicamente
  final String fx;              // id opcional de registro
  final String verificationId;  // de verifyPhoneNumber()

  const SmsVerificationScreen({
    super.key,
    required this.fullName,
    required this.phone,
    required this.birthdate,
    required this.password,
    required this.fx,
    required this.verificationId,
  });

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final _codeCtrl = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(User user) async {
    final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await usersRef.set(
      {
        'uid': user.uid,
        'fullName': widget.fullName,
        'phone': widget.phone,
        'birthdate': widget.birthdate != null
            ? Timestamp.fromDate(widget.birthdate!)
            : null,
        'provider': 'phone',
        'fx': widget.fx,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final smsCode = _codeCtrl.text.trim();
      if (smsCode.length < 6) {
        throw FirebaseAuthException(code: 'invalid-code', message: 'Código inválido');
      }

      // 1) Construir credencial y firmar con timeout
      final cred = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      final userCred = await FirebaseAuth.instance
          .signInWithCredential(cred)
          .timeout(const Duration(seconds: 20));

      final user = userCred.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'No se pudo obtener el usuario');
      }

      // 2) Ir a la app de inmediato
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PrincipalScreen()),
        (_) => false,
      );

      // 3) Guardar perfil en segundo plano (no bloquea la navegación)
      //    Si falla, mostramos un aviso pero no interrumpimos la sesión.
      unawaited(
        _saveProfile(user).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Perfil no guardado: $e')),
            );
          }
        }),
      );
    } on TimeoutException {
      setState(() => _error = 'Tiempo de espera agotado. Verifica tu conexión e intenta de nuevo.');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = '${e.code}: ${e.message ?? ''}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneShown = widget.phone;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificación')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Ingresa el código SMS que recibiste en el número $phoneShown'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de Verificación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verify,
              child: _isVerifying
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verificar Código'),
            ),
            const SizedBox(height: 12),
            const Text('Puedes reenviar el código en 60 segundos'),
          ],
        ),
      ),
    );
  }
}
