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
import 'package:shared_preferences/shared_preferences.dart';

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
  String phoneE164 = ''; // <- NUEVO (normalizado)
  DateTime? birthdate;
  String password = '';
  String confirmPassword = '';
  String? email; // opcional

  bool isRegistering = false;
  bool phoneAlreadyRegistered = false;

  Timer? _debounce;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _referrerUid;

  @override
  void initState() {
    super.initState();
    _loadReferrer();
  }

  Future<void> _loadReferrer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _referrerUid = prefs.getString('referrer_uid'));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Normaliza algo tipo "+1 809-555-1234" -> "+18095551234"
  String _toE164ish(String input) {
    final s = (input).replaceAll(RegExp(r'\s|-|\(|\)'), '');
    if (s.startsWith('+')) return s;
    return '+$s';
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

  Future<void> checkPhoneRegistration(String e164) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneE164', isEqualTo: e164) // <- CAMBIO: buscar por phoneE164
          .limit(1)
          .get();
      if (!mounted) return;
      setState(() => phoneAlreadyRegistered = snap.docs.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => phoneAlreadyRegistered = false);
    }
  }

  /// Envía SMS de verificación (flujo actual)
  Future<void> sendSmsCode() async {
    final fx = _uuid.v4();
    final l = AppLocalizations.of(context)!;

    // Asegurar que usamos el número normalizado
    final targetNumber = phoneE164.isNotEmpty ? phoneE164 : _toE164ish(phone);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: targetNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        // flujo automático (lo dejas igual)
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
        // Pasamos email (ya la guardaremos lower en _register) y referrerUid
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SmsVerificationScreen(
              fullName: fullName,
              phone: targetNumber, // <- usar E.164 normalizado
              birthdate: birthdate,
              email: email, // <- ya vendrá en minúsculas desde _register()
              referrerUid: _referrerUid,
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

    // Normalizar email y teléfono ANTES de usar
    if (email != null && email!.trim().isNotEmpty) {
      email = email!.trim().toLowerCase(); // <- guardar en minúsculas
    } else {
      email = null;
    }
    phoneE164 = phoneE164.isNotEmpty ? phoneE164 : _toE164ish(phone);

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.registerPasswordsDontMatch)),
      );
      return;
    }

    // Verificar si ya existe por phoneE164
    await checkPhoneRegistration(phoneE164);
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
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final existing = await ref.get();

        // Asegurar fx, emailLower y phoneE164
        final ensuredFx = existing.exists
            ? (existing.data()?['fx'] as String?) ?? _uuid.v4()
            : _uuid.v4();

        final refUid = (_referrerUid != null &&
                _referrerUid!.isNotEmpty &&
                _referrerUid != user.uid)
            ? _referrerUid
            : null;

        final normalizedEmailLower =
            (user.email ?? email)?.trim().toLowerCase();
        final normalizedPhone =
            (user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty)
                ? _toE164ish(user.phoneNumber!)
                : (phoneE164.isNotEmpty
                    ? phoneE164
                    : (phone.isNotEmpty ? _toE164ish(phone) : null));

        // Construir payload
        final data = <String, dynamic>{
          'uid': user.uid,
          'fullName': user.displayName ?? fullName,
          'email': user.email ?? email,
          'emailLower': normalizedEmailLower, // <- NUEVO
          'phone': user.phoneNumber ?? phone,
          if (normalizedPhone != null) 'phoneE164': normalizedPhone, // <- NUEVO
          'birthdate': birthdate != null
              ? Timestamp.fromDate(birthdate!)
              : (existing.data()?['birthdate']),
          'provider': 'google',
          'fx': ensuredFx, // <- NUEVO (garantizar fx)
          if (refUid != null) 'referredBy': refUid,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // createdAt solo si el doc no existía
        if (!existing.exists) {
          data['createdAt'] = FieldValue.serverTimestamp();
        }

        await ref.set(data, SetOptions(merge: true));

        // Limpiar referrer
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('referrer_uid');

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

    final showInviteBanner =
        _referrerUid != null && _referrerUid!.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            Text(l.registerTitle, style: const TextStyle(color: Colors.black87)),
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
                  Center(
                    child: Image.asset('assets/delf_logo.png',
                        height: 100, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 12),

                  if (showInviteBanner)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'Invitación detectada',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Nombre
                  TextFormField(
                    decoration: _inputDecoration(l.registerFullName),
                    style: const TextStyle(color: Colors.black87),
                    textInputAction: TextInputAction.next,
                    onSaved: (v) => fullName = (v ?? '').trim(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.registerEnterName;
                      }
                      if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email (opcional)
                  TextFormField(
                    decoration: _inputDecoration('Correo (opcional)'),
                    style: const TextStyle(color: Colors.black87),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (v) {
                      final s = (v ?? '').trim();
                      email = s.isEmpty ? null : s.toLowerCase(); // <- minúsculas
                    },
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      final ok =
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);
                      return ok ? null : 'Correo inválido';
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
                      phoneE164 = _toE164ish(pn.completeNumber); // <- mantener E.164
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        if (phoneE164.isNotEmpty) {
                          checkPhoneRegistration(phoneE164);
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.number.isEmpty) {
                        return l.registerEnterPhone;
                      }
                      if (value.number.length < 6) return 'Teléfono inválido';
                      return null;
                    },
                  ),
                  if (phoneAlreadyRegistered)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l.registerPhoneAlreadyUsed,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Fecha de nacimiento
                  GestureDetector(
                    onTap: _selectBirthdate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecoration(
                          birthdate == null
                              ? l.registerBirthdate
                              : _formatDate(birthdate!),
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.black87),
                        ),
                        style: const TextStyle(color: Colors.black87),
                        validator: (_) => birthdate == null
                            ? l.registerSelectBirthdate
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    decoration: _inputDecoration(
                      l.registerPassword,
                      icon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.black87),
                    onSaved: (v) => password = v ?? '',
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return l.registerEnterPassword;
                      }
                      if (v.length < 6) return l.registerPasswordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirmación
                  TextFormField(
                    decoration: _inputDecoration(
                      l.registerConfirmPassword,
                      icon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () => setState(() => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible),
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    style: const TextStyle(color: Colors.black87),
                    onSaved: (v) => confirmPassword = v ?? '',
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return l.registerEnterConfirmation;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Botón Registrar
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: isRegistering
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
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
