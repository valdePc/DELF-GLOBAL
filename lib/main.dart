// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <- IMPORTANTE
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'models/message.dart';
import 'screens/registro_screen.dart';
import 'screens/principal.dart';
import 'screens/add_contact.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    await Hive.initFlutter();
  }
  Hive.registerAdapter(MessageAdapter());

  runApp(MyApp(key: MyApp.globalKey));
}

class MyApp extends StatefulWidget {
  static final GlobalKey<MyAppState> globalKey = GlobalKey<MyAppState>();
  const MyApp({Key? key}) : super(key: key);

  static void setLocale(Locale newLocale) =>
      globalKey.currentState?.setLocale(newLocale);
  static void setTheme(bool darkMode) =>
      globalKey.currentState?.setTheme(darkMode);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale? _locale;
  bool _darkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final idiomaGuardado = prefs.getString('idioma');
    final sistemaLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final idiomaFinal = idiomaGuardado ?? sistemaLocale.languageCode;

    final isDark = prefs.getBool('temaOscuro') ?? false;

    setState(() {
      _locale = Locale(idiomaFinal);
      _darkTheme = isDark;
    });
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idioma', locale.languageCode);
    setState(() => _locale = locale);
  }

  Future<void> setTheme(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('temaOscuro', darkMode);
    setState(() => _darkTheme = darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delf App',
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: _darkTheme
          ? ThemeData.dark(useMaterial3: false)
          : ThemeData.light(useMaterial3: false),

      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '/');

        if (uri != null && uri.path == '/invite') {
          return MaterialPageRoute(
            builder: (_) => _InviteGate(uri: uri),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const _RootGate(),
          settings: settings,
        );
      },
    );
  }
}

/// Si hay sesión → Principal; si no → Registro
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasData) {
          return const PrincipalScreen();
        }
        return const RegistroScreen();
      },
    );
  }
}

/// Deep link de invitación:
/// - Sin sesión → Registro
/// - Con sesión → navega a AddContact prellenando si se puede
class _InviteGate extends StatelessWidget {
  final Uri uri;
  const _InviteGate({required this.uri});

  Future<void> _persistRef(String? ref) async {
    if (ref == null || ref.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('referrer_uid', ref);
  }

  @override
  Widget build(BuildContext context) {
    final refUid = uri.queryParameters['ref'];

    return FutureBuilder<void>(
      future: _persistRef(refUid),
      builder: (_, __) {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return const RegistroScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserPublic(refUid),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final initialArgs = {
              if ((snap.data?['fullName'] ?? '').toString().isNotEmpty)
                'name': snap.data!['fullName'],
              if ((snap.data?['email'] ?? '').toString().isNotEmpty)
                'email': snap.data!['email'],
              if ((snap.data?['phoneE164'] ?? '').toString().isNotEmpty)
                'phone': snap.data!['phoneE164'],
            };

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const AddContactScreen(),
                  settings: RouteSettings(arguments: initialArgs),
                ),
              );
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchUserPublic(String? uid) async {
    if (uid == null || uid.isEmpty) return null;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }
}
