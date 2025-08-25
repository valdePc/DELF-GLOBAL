import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'registro_screen.dart';
import 'principal.dart';
import 'dart:ui';




/// Cambia estos colores a tu gusto y todo el chat se adapta.
class ChatTheme {
  static const primary = Color(0xFF0066FF);
  static const bg = Color(0xFFF3F5F8);
  static const bubbleMe = Color(0xFFDCEBFF);
  static const bubbleOther = Colors.white;
  static const bubbleShadow = Color(0x1A000000);
}

/// Enlace público para invitar (tu GitHub Pages actual del web build).
/// Si cambias hosting, solo cambia aquí.
const APP_INVITE_URL = 'https://valdepc.github.io/DELF-GLOBAL/';

void main() {
  runApp(MyApp());
}

/// Clase principal de la app con soporte para cambiar idioma/tema desde cualquier parte
class MyApp extends StatefulWidget {
  static final GlobalKey<_MyAppState> globalKey = GlobalKey<_MyAppState>();

  MyApp({Key? key}) : super(key: globalKey);

  /// Cambiar el idioma globalmente
  static void setLocale(Locale newLocale) {
    globalKey.currentState?.setLocale(newLocale);
  }

  /// Cambiar el tema globalmente
  static void setTheme(bool darkMode) {
    globalKey.currentState?.setTheme(darkMode);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  bool _darkTheme = false;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Aplica un nuevo idioma y lo guarda
  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idioma', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  /// Aplica un nuevo tema y lo guarda
  void setTheme(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('temaOscuro', darkMode);
    setState(() {
      _darkTheme = darkMode;
    });
  }

  /// Carga idioma, tema y pantalla inicial
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getBool('temaOscuro') ?? false;
    final idiomaGuardado = prefs.getString('idioma');
    final estaLogueado = prefs.getBool('isLoggedIn') ?? false;

    final sistemaLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final idiomaFinal = idiomaGuardado ?? sistemaLocale.languageCode;

    setState(() {
      _darkTheme = savedTheme;
      _locale = Locale(idiomaFinal);
     _home = estaLogueado ? PrincipalScreen() : const RegistroScreen();

    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en'), Locale('es'), Locale('ar'), Locale('bg'),
        Locale('cs'), Locale('de'), Locale('el'), Locale('fi'),
        Locale('fr'), Locale('he'), Locale('hi'), Locale('hr'),
        Locale('id'), Locale('it'), Locale('ja'), Locale('ko'),
        Locale('nl'), Locale('no'), Locale('pl'), Locale('pt'),
        Locale('ro'), Locale('ru'), Locale('sk'), Locale('sl'),
        Locale('sv'), Locale('th'), Locale('uk'), Locale('vi'),
        Locale('zh'), Locale('zh', 'Hant'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'App de Mensajería',
      theme: _darkTheme
          ? ThemeData(
              useMaterial3: false,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              canvasColor: Colors.black,
              cardColor: Colors.black,
              colorScheme: const ColorScheme.dark(
                surface: Colors.black,
                onSurface: Colors.white,
                primary: Colors.white,
                secondary: Colors.blueGrey,
              ),
              appBarTheme: const AppBarTheme(color: Colors.black),
            )
          : ThemeData.light(),
      home: _home ?? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}



