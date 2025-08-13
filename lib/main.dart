import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'models/message.dart';
import 'screens/registro_screen.dart';
import 'screens/principal.dart';

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
  Widget? _home;

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
    final user = FirebaseAuth.instance.currentUser;
    final estaLogueado = user != null;

    setState(() {
      _locale = Locale(idiomaFinal);
      _darkTheme = isDark;
      _home = estaLogueado ? const PrincipalScreen() : const RegistroScreen();
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
      home: _home ??
          const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
    );
  }
}
