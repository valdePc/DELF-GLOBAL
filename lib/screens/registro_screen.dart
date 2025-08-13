import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'airtable_service.dart';
import 'sms_verification.dart';
import 'principal.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  RegistroScreenState createState() => RegistroScreenState();
}

class RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();    // ← perfecto
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

 Future<void> sendSmsCode() async {
    // 1) Genera un identificador único antes de iniciar la verificación
    final fx = _uuid.v4();

    // 2) Envía el SMS con Firebase
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar código: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        // 3) Navega al SMSVerificationScreen, pasándole también el fx
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SmsVerificationScreen(
              fullName: fullName,
              phone: phone,
              birthdate: birthdate,
              password: password,
              fx: fx,                     // ← el UUID aquí
              verificationId: verificationId,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> checkPhoneRegistration(String phone) async {
    bool exists = await AirtableService.isPhoneRegistered(phone);
    setState(() {
      phoneAlreadyRegistered = exists;
    });
  }

  Future<void> _selectBirthdate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    setState(() {
      birthdate = picked;
    });
    }

  Future<void> _register() async {
    final localizations = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.registerPasswordsDontMatch)),
        );
        return;
      }

      if (phoneAlreadyRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.registerPhoneAlreadyUsed)),
        );
        return;
      }

      setState(() => isRegistering = true);
      await sendSmsCode();
      setState(() => isRegistering = false);
    }
  }


Future<void> signInWithGoogle() async {
  try {
    final auth = FirebaseAuth.instance;
    final googleProvider = GoogleAuthProvider();

    if (kIsWeb) {
      // 👉 En Web usamos signInWithPopup (o signInWithRedirect)
      final userCredential = await auth.signInWithPopup(googleProvider);
      final user = userCredential.user;

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PrincipalScreen()),
        );
      }
    } else {
      // 👉 En Móvil usamos GoogleSignIn
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PrincipalScreen()),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error al iniciar sesión con Google: $e')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(0, 201, 24, 24),
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
        title: Text(localizations.registerTitle, style: const TextStyle(color: Color.fromARGB(255, 12, 12, 12))),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 23, 3, 95), Color.fromARGB(252, 233, 36, 115)],
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
    // 1) Logo centrado arriba
    Center(
      child: Image.asset(
        'assets/delf_logo.png',  // asegúrate de tener este archivo en assets/
        height: 100,
        fit: BoxFit.contain,
      ),
    ),
    const SizedBox(height: 24),

    // 2) Tu formulario empieza aquí
    TextFormField(
      decoration: _inputDecoration(localizations.registerFullName),
      style: const TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
      onSaved: (val) => fullName = val!.trim(),
      validator: (val) =>
          val == null || val.isEmpty ? localizations.registerEnterName : null,
    ),
    const SizedBox(height: 16),
    IntlPhoneField(
      decoration: _inputDecoration(localizations.registerPhone),
      initialCountryCode: 'US',
      style: const TextStyle(color: Color.fromARGB(255, 2, 2, 2)),
      dropdownTextStyle: const TextStyle(color: Colors.black),
      onChanged: (phoneNumber) {
        phone = phoneNumber.completeNumber;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          checkPhoneRegistration(phone);
        });
      },
      validator: (value) =>
                        value == null || value.number.isEmpty ? localizations.registerEnterPhone : null,
                  ),
                  if (phoneAlreadyRegistered)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        localizations.registerPhoneAlreadyUsed,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectBirthdate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecoration(
                          birthdate == null
                              ? localizations.registerBirthdate
                              : '${birthdate!.year}-${birthdate!.month.toString().padLeft(2, '0')}-${birthdate!.day.toString().padLeft(2, '0')}',
                          icon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 6, 6, 6)),
                        ),
                        style: const TextStyle(color: Color.fromARGB(255, 6, 6, 6)),
                        validator: (_) => birthdate == null
                            ? localizations.registerSelectBirthdate
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: _inputDecoration(
                      localizations.registerPassword,
                      icon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: const Color.fromARGB(179, 3, 3, 3),
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Color.fromARGB(255, 5, 5, 5)),
                    onSaved: (val) => password = val!,
                    validator: (val) {
                      if (val == null || val.isEmpty) return localizations.registerEnterPassword;
                      if (val.length < 6) return localizations.registerPasswordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: _inputDecoration(
                      localizations.registerConfirmPassword,
                      icon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: const Color.fromARGB(179, 16, 12, 12),
                        ),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    style: const TextStyle(color: Color.fromARGB(255, 17, 17, 17)),
                    onSaved: (val) => confirmPassword = val!,
                    validator: (val) =>
                        val == null || val.isEmpty ? localizations.registerEnterConfirmation : null,
                  ),
                  const SizedBox(height: 24),
                 const SizedBox(height: 24),
AnimatedSwitcher(
  duration: const Duration(milliseconds: 400),
  child: isRegistering
      ? const CircularProgressIndicator(
          color: Color.fromARGB(255, 255, 255, 255),
          strokeWidth: 2,
        )
      : ElevatedButton.icon(
          key: const ValueKey('registerButton'),
          onPressed: _register,
          icon: const Icon(Icons.rocket_launch),
          label: Text(localizations.registerButton),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 237, 235, 233),
            foregroundColor: const Color.fromARGB(255, 4, 4, 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
        ),
),

const SizedBox(height: 24),
const Divider(color: Colors.white30),
const SizedBox(height: 8),

ElevatedButton.icon(
  onPressed: () async {
    setState(() => isRegistering = true);
    await signInWithGoogle();
    setState(() => isRegistering = false);
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: icon,
    );
  }
}
