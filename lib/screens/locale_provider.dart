import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es'); // Idioma por defecto: Español
  bool _isDarkMode = false;
  bool _isLoaded = false;

  Locale get locale => _locale;
  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _isLoaded;

  LocaleProvider() {
    _loadPreferences();
  }

  void setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  void clearLocale() async {
    _locale = const Locale('es');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('languageCode');
  }

  void toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar idioma
    final langCode = prefs.getString('languageCode') ?? 'es';
    _locale = Locale(langCode);

    // Cargar tema
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    _isLoaded = true;
    notifyListeners();
  }
}
