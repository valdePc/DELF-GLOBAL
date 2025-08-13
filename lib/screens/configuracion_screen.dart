// ARCHIVO: cconfiguracion_screen_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ correcto

import 'reels.dart';
import 'telefono.dart';
import 'grupos.dart';
import 'principal.dart';
import 'app.dart';
import 'registro_screen.dart';


class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  String? _profilePicUrl;
  String _nombreCompleto = 'Nombre de Ejemplo';
  String _fechaNacimiento = '2000-01-01';
  String _telefono = '+1 234567890';

  bool _nombreCambiado = false;
  bool _fotoCambiada = false;

  String _tonoMensaje = 'classic';
  String _tonoLlamada = 'digital';

  bool _mostrarUltimaVez = true;
  bool _modoIncognito = false;
  bool _tieneModoIncognitoPago = false;

  String _idiomaSeleccionado = 'system';
  bool _temaOscuro = false;
  int _selectedIndex = 4;

@override
void initState() {
  super.initState();
  _cargarDatosUsuario();
  _cargarPreferenciasTemaIdioma();
}


  Future<void> _cargarPreferenciasTemaIdioma() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temaOscuro = prefs.getBool('temaOscuro') ?? false;
      _idiomaSeleccionado = prefs.getString('idioma') ?? 'system';
    });
  }

  void _changeLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();

    if (languageCode == null) {
      await prefs.remove('idioma');
      final sistemaLocale = WidgetsBinding.instance.platformDispatcher.locale;
      MyApp.setLocale(Locale(sistemaLocale.languageCode));
      setState(() {
        _idiomaSeleccionado = 'system';
      });
    } else {
      await prefs.setString('idioma', languageCode);
      MyApp.setLocale(Locale(languageCode));
      setState(() {
        _idiomaSeleccionado = languageCode;
      });
    }
  }

  void _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegistroScreen()),

      (route) => false,
    );
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() {
      _nombreCompleto = 'Alice Example';
      _fechaNacimiento = '1995-05-15';
      _telefono = '+1 999888777';
      _mostrarUltimaVez = true;
      _modoIncognito = false;
      _tieneModoIncognitoPago = false;
    });
  }

  Future<void> _guardarCambiosPerfil() async {
    if (!_nombreCambiado && !_fotoCambiada) return;
    setState(() {
      _nombreCambiado = false;
      _fotoCambiada = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.successSave)),
    );
  }

  Future<void> _toggleModoIncognito(bool value) async {
    final localizations = AppLocalizations.of(context)!;
    if (value && !_tieneModoIncognitoPago) {
      final resp = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(localizations.incognitoMode),
          content: Text(localizations.incognitoDialogText),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(localizations.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(localizations.accept)),
          ],
        ),
      );
      if (resp == true) {
        setState(() {
          _tieneModoIncognitoPago = true;
          _modoIncognito = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.paymentSuccess)),
        );
      } else {
        setState(() {
          _modoIncognito = false;
        });
      }
    } else {
      setState(() {
        _modoIncognito = value;
      });
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profilePicUrl = image.path;
        _fotoCambiada = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final List<Widget> screens = [
      ReelsScreen(),
      TelefonoScreen(),
      PrincipalScreen(),
      GruposScreen(),
      ConfiguracionScreen(),
    ];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screens[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.configTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildBloquePerfil(localizations),
              const SizedBox(height: 12),
              _buildBloqueNotificaciones(localizations),
              const SizedBox(height: 12),
              _buildBloquePrivacidad(localizations),
              const SizedBox(height: 12),
              _buildBloqueIdiomaTema(localizations),
              const SizedBox(height: 12),
              _buildBloqueCuenta(localizations),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.video_camera_front_outlined), label: localizations.navReels),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: localizations.navPhone),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: localizations.navProfile),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: localizations.navGroups),
          BottomNavigationBarItem(icon: Icon(Icons.insert_drive_file_outlined), label: localizations.navSettings),
        ],
      ),
    );
  }

  Widget _buildBloquePerfil(AppLocalizations localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _cambiarFotoPerfil,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _profilePicUrl == null ? null : FileImage(File(_profilePicUrl!)),
                child: _profilePicUrl == null ? const Icon(Icons.person, size: 40) : null,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _nombreCompleto,
              decoration: InputDecoration(
                labelText: localizations.fullNameLabel,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _nombreCompleto = value;
                  _nombreCambiado = true;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('${localizations.birthDateLabel}: $_fechaNacimiento', style: const TextStyle(fontSize: 12)),
            Text('${localizations.phoneLabel}: $_telefono', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _guardarCambiosPerfil,
              child: Text(localizations.saveChanges),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloqueNotificaciones(AppLocalizations localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.notifications, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(thickness: 1),
            Row(
              children: [
                const Icon(Icons.music_note, size: 20),
                const SizedBox(width: 8),
                Text(localizations.messageToneLabel, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _tonoMensaje,
                  items: ['classic', 'digital', 'modern'].map((String val) {
                    return DropdownMenuItem(
                      value: val,
                      child: Text(
                        val == 'classic'
                            ? localizations.toneClassic
                            : val == 'digital'
                                ? localizations.toneDigital
                                : localizations.toneModern,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newVal) {
                    setState(() {
                      _tonoMensaje = newVal!;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.ring_volume, size: 20),
                const SizedBox(width: 8),
                Text(localizations.callToneLabel, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _tonoLlamada,
                  items: ['classic', 'digital', 'modern'].map((String val) {
                    return DropdownMenuItem(
                      value: val,
                      child: Text(
                        val == 'classic'
                            ? localizations.toneClassic
                            : val == 'digital'
                                ? localizations.toneDigital
                                : localizations.toneModern,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newVal) {
                    setState(() {
                      _tonoLlamada = newVal!;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloquePrivacidad(AppLocalizations localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.privacy, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(thickness: 1),
            SwitchListTile(
              title: Text(localizations.lastSeenLabel),
              value: _mostrarUltimaVez,
              onChanged: (bool val) {
                setState(() {
                  _mostrarUltimaVez = val;
                });
              },
            ),
            SwitchListTile(
              title: Text(localizations.incognitoModeLabel),
              value: _modoIncognito,
              onChanged: _toggleModoIncognito,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloqueIdiomaTema(AppLocalizations localizations) {
    final List<Map<String, dynamic>> languages = [
      {'name': localizations.languageSystem, 'locale': null, 'flag': '🌐'},
      {'name': 'Español', 'locale': const Locale('es'), 'flag': '🇪🇸'},
      {'name': 'Inglés', 'locale': const Locale('en'), 'flag': '🇺🇸'},
      {'name': 'Francés', 'locale': const Locale('fr'), 'flag': '🇫🇷'},
      {'name': 'Italiano', 'locale': const Locale('it'), 'flag': '🇮🇹'},
      {'name': 'Alemán', 'locale': const Locale('de'), 'flag': '🇩🇪'},
      {'name': 'Chino', 'locale': const Locale('zh'), 'flag': '🇨🇳'},
      {'name': 'Japonés', 'locale': const Locale('ja'), 'flag': '🇯🇵'},
      {'name': 'Coreano', 'locale': const Locale('ko'), 'flag': '🇰🇷'},
      {'name': 'Ruso', 'locale': const Locale('ru'), 'flag': '🇷🇺'},
      {'name': 'Árabe', 'locale': const Locale('ar'), 'flag': '🇸🇦'},
    ];

    final selectedItem = languages.firstWhere(
      (lang) =>
          (_idiomaSeleccionado == 'system' && lang['locale'] == null) ||
          (lang['locale']?.languageCode == _idiomaSeleccionado),
      orElse: () => languages[0],
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.languageAndTheme,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(thickness: 1),
            Row(
              children: [
                const Icon(Icons.language),
                const SizedBox(width: 8),
                Text(localizations.languageLabel),
                const SizedBox(width: 8),
                DropdownButton<Map<String, dynamic>>(
                  value: selectedItem,
                  items: languages.map((lang) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: lang,
                      child: Text('${lang['flag']} ${lang['name']}'),
                    );
                  }).toList(),
                  onChanged: (selected) {
                    if (selected != null) {
                      _changeLanguage(selected['locale']?.languageCode);
                    }
                  },
                ),
              ],
            ),
            SwitchListTile(
              title: Text(localizations.darkThemeLabel),
              value: _temaOscuro,
              onChanged: (bool val) {
                setState(() {
                  _temaOscuro = val;
                });
                MyApp.setTheme(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloqueCuenta(AppLocalizations localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: Text(localizations.logoutLabel),
          onTap: () async {
            bool? confirm = await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(localizations.logoutTitle),
                content: Text(localizations.logoutConfirm),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(localizations.cancel)),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(localizations.accept)),
                ],
              ),
            );
            if (confirm == true) {
              _cerrarSesion(context);
            }
          },
        ),
      ),
    );
  }
}
