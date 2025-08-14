// lib/screens/registro_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'sms_verification.dart';
import 'principal.dart';


class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  RegistroScreenState createState() => RegistroScreenState();
}

class RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String fullName = '';
  String phone = '';
  DateTime? birthdate;
  String password = '';
  String confirmPassword = '';

  bool isRegistering = false;
  bool phoneAlreadyRegistered = false;

  Timer? _debounce;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _selectBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    setState(() => birthdate = picked);
  }

/// Verifica si ya hay un perfil con ese teléfono en Firestore.
  /// (Ojo: desde cliente no podemos consultar usuarios de Auth;
  /// esto es una verificación "best-effort" sobre tu colección `users`.)
  /// 
  
  Future<void> checkPhoneRegistration(String value) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: value)
          .limit(1)
          .get();
      if (!mounted) return;
      setState(() => phoneAlreadyRegistered = snap.docs.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => phoneAlreadyRegistered = false);
    }
  }

  // Envío de código:
  // - Web: simulado (navega y usas 123456)
  // - Móvil: SMS real con verifyPhoneNumber

  /// Envía SMS de verificación en **todas** las plataformas (Web incl.).
  Future<void> sendSmsCode() async {
    final fx = _uuid.v4();
    final l = AppLocalizations.of(context)!;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        // En Android puede autocompletar; aquí no lo usamos para mantener el mismo flujo visual.
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar código: ${e.message ?? e.code}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.registerVerificationSent)),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SmsVerificationScreen(
              fullName: fullName,
              phone: phone,
              birthdate: birthdate,
              // NO usamos password en servidor; solo validamos que coincidan.
              password: password,
              fx: fx,
              verificationId: verificationId,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }


 Future<void> _register() async {
    final l = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.registerPasswordsDontMatch)),
      );
      return;
    }

   // Si ya existe en tu colección de perfiles, avisa (opcional)
    if (phoneAlreadyRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.registerPhoneAlreadyUsed)),
      );
      return;
    }

    setState(() => isRegistering = true);
    try {
      await sendSmsCode();
    } finally {
      if (mounted) setState(() => isRegistering = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final auth = FirebaseAuth.instance;
      final googleProvider = GoogleAuthProvider();

      User? user;
      if (kIsWeb) {
        final cred = await auth.signInWithPopup(googleProvider);
        user = cred.user;
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final cred = await auth.signInWithCredential(credential);
        user = cred.user;
      }

      if (user != null) {
        // Crea/actualiza perfil en Firestore
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await ref.set(
          {
            'uid': user.uid,
            'fullName': user.displayName ?? fullName,
            'phone': user.phoneNumber ?? phone,
            'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
            'provider': 'google',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PrincipalScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al iniciar sesión con Google: $e')),
      );
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(0, 0, 0, 0),
      systemNavigationBarColor: Color.fromARGB(0, 0, 0, 0),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l.registerTitle, style: const TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF17035F), Color(0xFFE92473)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset('assets/delf_logo.png', height: 100, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 24),

                  // Nombre
                  TextFormField(
                    decoration: _inputDecoration(l.registerFullName),
                    style: const TextStyle(color: Colors.black87),
                    textInputAction: TextInputAction.next,
                    onSaved: (v) => fullName = (v ?? '').trim(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l.registerEnterName;
                      if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Teléfono
                  IntlPhoneField(
                    decoration: _inputDecoration(l.registerPhone),
                    initialCountryCode: 'US',
                    style: const TextStyle(color: Colors.black87),
                    dropdownTextStyle: const TextStyle(color: Colors.black87),
                    onChanged: (pn) {
                      phone = pn.completeNumber;
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        if (phone.isNotEmpty) checkPhoneRegistration(phone);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.number.isEmpty) return l.registerEnterPhone;
                      if (value.number.length < 6) return 'Teléfono inválido';
                      return null;
                    },
                  ),
                  if (phoneAlreadyRegistered)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l.registerPhoneAlreadyUsed,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Fecha de nacimiento
                  GestureDetector(
                    onTap: _selectBirthdate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecoration(
                          birthdate == null ? l.registerBirthdate : _formatDate(birthdate!),
                          icon: const Icon(Icons.calendar_today, color: Colors.black87),
                        ),
                        style: const TextStyle(color: Colors.black87),
                        validator: (_) => birthdate == null ? l.registerSelectBirthdate : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contraseña (solo validación local)
                  TextFormField(
                    decoration: _inputDecoration(
                      l.registerPassword,
                      icon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.black87),
                    onSaved: (v) => password = v ?? '',
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.registerEnterPassword;
                      if (v.length < 6) return l.registerPasswordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirmación de contraseña (solo validación local)
                  TextFormField(
                    decoration: _inputDecoration(
                      l.registerConfirmPassword,
                      icon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () => setState(
                            () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    style: const TextStyle(color: Colors.black87),
                    onSaved: (v) => confirmPassword = v ?? '',
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.registerEnterConfirmation;
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Botón Registrar
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: isRegistering
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : ElevatedButton.icon(
                            key: const ValueKey('registerButton'),
                            onPressed: _register,
                            icon: const Icon(Icons.rocket_launch),
                            label: Text(l.registerButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEDEBE9),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 8),

                  // Google
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => isRegistering = true);
                      await signInWithGoogle();
                      if (mounted) setState(() => isRegistering = false);
                    },
                    icon: Image.asset('assets/google.png', height: 24),
                    label: const Text("Continuar con Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: icon,
    );
  }
}