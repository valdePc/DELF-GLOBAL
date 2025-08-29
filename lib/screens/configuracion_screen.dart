// ARCHIVO: cconfiguracion_screen_screen.dart
// Versión con MENÚ INFERIOR “flotante” totalmente funcional y adaptado a esta sesión (índice 4 activo).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  // Perfil
  String? _profilePicUrl;
  String? _initialProfilePicUrl;
  late TextEditingController _nameCtrl;
  String _nombreCompleto = 'Nombre de Ejemplo';
  String _initialNombreCompleto = 'Nombre de Ejemplo';
  String _fechaNacimiento = '2000-01-01';
  String _telefono = '+1 234567890';

  // Flags de cambios
  bool _nombreCambiado = false;
  bool _fotoCambiada = false;

  // Notificaciones
  String _tonoMensaje = 'classic';
  String _tonoLlamada = 'digital';

  // Privacidad
  bool _mostrarUltimaVez = true;
  bool _modoIncognito = false;
  bool _tieneModoIncognitoPago = false;

  // Idioma/Tema
  String _idiomaSeleccionado = 'system';
  bool _temaOscuro = false;

  // Nav (esta pantalla = índice 4)
  int _selectedIndex = 4;

  bool get _hasProfileChanges => _nombreCambiado || _fotoCambiada;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _cargarDatosUsuario();
    _cargarPreferenciasTemaIdioma();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPreferenciasTemaIdioma() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temaOscuro = prefs.getBool('temaOscuro') ?? false;
      _idiomaSeleccionado = prefs.getString('idioma') ?? 'system';
    });
  }

  Future<void> _persistTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('temaOscuro', isDark);
  }

  void _changeLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove('idioma');
      final sistemaLocale = WidgetsBinding.instance.platformDispatcher.locale;
      MyApp.setLocale(Locale(sistemaLocale.languageCode));
      setState(() => _idiomaSeleccionado = 'system');
    } else {
      await prefs.setString('idioma', languageCode);
      MyApp.setLocale(Locale(languageCode));
      setState(() => _idiomaSeleccionado = languageCode);
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
    // Carga de ejemplo (sustituye por tu backend/SharedPrefs reales)
    setState(() {
      _nombreCompleto = 'Alice Example';
      _initialNombreCompleto = _nombreCompleto;
      _nameCtrl.text = _nombreCompleto;

      _fechaNacimiento = '1995-05-15';
      _telefono = '+1 999888777';

      _profilePicUrl = null;
      _initialProfilePicUrl = _profilePicUrl;

      _mostrarUltimaVez = true;
      _modoIncognito = false;
      _tieneModoIncognitoPago = false;

      _nombreCambiado = false;
      _fotoCambiada = false;
    });
  }

  Future<void> _guardarCambiosPerfil() async {
    if (!_hasProfileChanges) return;

    // TODO: Guardar en tu backend/Firestore/lo que uses…
    _initialNombreCompleto = _nombreCompleto;
    _initialProfilePicUrl = _profilePicUrl;

    setState(() {
      _nombreCambiado = false;
      _fotoCambiada = false;
    });

    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.successSave)),
    );
  }

  void _descartarCambiosPerfil() {
    setState(() {
      _nombreCompleto = _initialNombreCompleto;
      _nameCtrl.text = _initialNombreCompleto;
      _profilePicUrl = _initialProfilePicUrl;
      _nombreCambiado = false;
      _fotoCambiada = false;
    });
  }

  Future<void> _toggleModoIncognito(bool value) async {
    final l = AppLocalizations.of(context)!;
    if (value && !_tieneModoIncognitoPago) {
      final resp = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.visibility_off_outlined),
              const SizedBox(width: 8),
              Text(l.incognitoMode),
            ],
          ),
          content: Text(l.incognitoDialogText),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.accept)),
          ],
        ),
      );
      if (resp == true) {
        setState(() {
          _tieneModoIncognitoPago = true;
          _modoIncognito = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.paymentSuccess)),
        );
      } else {
        setState(() => _modoIncognito = false);
      }
    } else {
      setState(() => _modoIncognito = value);
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profilePicUrl = image.path;
        _fotoCambiada = true;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      // Si ya estás en la misma pestaña, opcional: hace “scroll to top” futuro.
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);

    final screens = <Widget>[
      ReelsScreen(),
      TelefonoScreen(),
      PrincipalScreen(),
      GruposScreen(),
      ConfiguracionScreen(), // <- esta
    ];

    // Reemplaza para no apilar pantallas
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screens[index],
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 140),
      ),
    );
  }

  void _previewTone(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔊 $label')),
    );
  }

  Future<void> _showLanguageSheet() async {
    final l = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> languages = [
      {'name': l.languageSystem, 'code': null, 'flag': '🌐'},
      {'name': 'Español', 'code': 'es', 'flag': '🇪🇸'},
      {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
      {'name': 'Français', 'code': 'fr', 'flag': '🇫🇷'},
      {'name': 'Italiano', 'code': 'it', 'flag': '🇮🇹'},
      {'name': 'Deutsch', 'code': 'de', 'flag': '🇩🇪'},
      {'name': '中文', 'code': 'zh', 'flag': '🇨🇳'},
      {'name': '日本語', 'code': 'ja', 'flag': '🇯🇵'},
      {'name': '한국어', 'code': 'ko', 'flag': '🇰🇷'},
      {'name': 'Русский', 'code': 'ru', 'flag': '🇷🇺'},
      {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
    ];

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final item = languages[i];
              final isSelected = (_idiomaSeleccionado == 'system' && item['code'] == null) ||
                  (_idiomaSeleccionado == item['code']);
              return ListTile(
                leading: Text(item['flag'], style: const TextStyle(fontSize: 22)),
                title: Text(item['name']),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () {
                  Navigator.pop(context);
                  _changeLanguage(item['code']);
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: languages.length,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.configTitle),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            child: Column(
              children: [
                _buildBloquePerfil(l),
                const SizedBox(height: 12),
                _buildBloqueNotificaciones(l),
                const SizedBox(height: 12),
                _buildBloquePrivacidad(l),
                const SizedBox(height: 12),
                _buildBloqueIdiomaTema(l),
                const SizedBox(height: 12),
                _buildBloqueCuenta(l),
              ],
            ),
          ),

          // Barra de guardado pegajosa (aparece solo si hay cambios)
          if (_hasProfileChanges)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 82),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.saveChanges,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _descartarCambiosPerfil,
                      child: Text(l.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _guardarCambiosPerfil,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l.accept),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNav(context, l),
    );
  }

  // ======== Secciones ========

  Widget _buildBloquePerfil(AppLocalizations l) {
    return _sectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _cambiarFotoPerfil,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _profilePicUrl == null ? null : FileImage(File(_profilePicUrl!)),
                  child: _profilePicUrl == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: _cambiarFotoPerfil,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white), // lapiz de editar perfil
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: l.fullNameLabel,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) {
              _nombreCompleto = v;
              final changed = v != _initialNombreCompleto;
              if (changed != _nombreCambiado) {
                setState(() => _nombreCambiado = changed);
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.cake_outlined, '${l.birthDateLabel}: $_fechaNacimiento'),
              const SizedBox(width: 8),
              _infoChip(Icons.phone_outlined, '${l.phoneLabel}: $_telefono'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueNotificaciones(AppLocalizations l) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(l.notifications),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: Text(l.messageToneLabel),
            subtitle: Text(
              _tonoMensaje == 'classic'
                  ? l.toneClassic
                  : _tonoMensaje == 'digital'
                      ? l.toneDigital
                      : l.toneModern,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Preview',
                  onPressed: () => _previewTone(
                    _tonoMensaje == 'classic'
                        ? l.toneClassic
                        : _tonoMensaje == 'digital'
                            ? l.toneDigital
                            : l.toneModern,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (val) => setState(() => _tonoMensaje = val),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'classic', child: Text(l.toneClassic)),
                    PopupMenuItem(value: 'digital', child: Text(l.toneDigital)),
                    PopupMenuItem(value: 'modern', child: Text(l.toneModern)),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.ring_volume),
            title: Text(l.callToneLabel),
            subtitle: Text(
              _tonoLlamada == 'classic'
                  ? l.toneClassic
                  : _tonoLlamada == 'digital'
                      ? l.toneDigital
                      : l.toneModern,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Preview',
                  onPressed: () => _previewTone(
                    _tonoLlamada == 'classic'
                        ? l.toneClassic
                        : _tonoLlamada == 'digital'
                            ? l.toneDigital
                            : l.toneModern,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (val) => setState(() => _tonoLlamada = val),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'classic', child: Text(l.toneClassic)),
                    PopupMenuItem(value: 'digital', child: Text(l.toneDigital)),
                    PopupMenuItem(value: 'modern', child: Text(l.toneModern)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloquePrivacidad(AppLocalizations l) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(l.privacy),
          const Divider(),
          SwitchListTile(
            value: _mostrarUltimaVez,
            onChanged: (val) => setState(() => _mostrarUltimaVez = val),
            title: Text(l.lastSeenLabel),
            secondary: const Icon(Icons.access_time),
          ),
          SwitchListTile(
            value: _modoIncognito,
            onChanged: _toggleModoIncognito,
            title: Row(
              children: [
                Text(l.incognitoModeLabel),
                const SizedBox(width: 8),
                if (!_tieneModoIncognitoPago)
                  const Chip(
                    label: Text('PRO', style: TextStyle(color: Colors.red)),
                    backgroundColor: Color(0xFF8B5CF6),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
            secondary: const Icon(Icons.visibility_off_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueIdiomaTema(AppLocalizations l) {
    final String idiomaTexto = () {
      if (_idiomaSeleccionado == 'system') return l.languageSystem;
      switch (_idiomaSeleccionado) {
        case 'es':
          return 'Español';
        case 'en':
          return 'English';
        case 'fr':
          return 'Français';
        case 'it':
          return 'Italiano';
        case 'de':
          return 'Deutsch';
        case 'zh':
          return '中文';
        case 'ja':
          return '日本語';
        case 'ko':
          return '한국어';
        case 'ru':
          return 'Русский';
        case 'ar':
          return 'العربية';
        default:
          return l.languageSystem;
      }
    }();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(l.languageAndTheme),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.languageLabel),
            subtitle: Text(idiomaTexto),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguageSheet,
          ),
          SwitchListTile(
            value: _temaOscuro,
            onChanged: (val) {
              setState(() => _temaOscuro = val);
              MyApp.setTheme(val); // Mantiene tu firma actual
              _persistTheme(val);
            },
            title: Text(l.darkThemeLabel),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueCuenta(AppLocalizations l) {
    return _sectionCard(
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: Text(l.logoutLabel),
        onTap: () async {
          bool? confirm = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l.logoutTitle),
              content: Text(l.logoutConfirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.accept)),
              ],
            ),
          );
          if (confirm == true) _cerrarSesion(context);
        },
      ),
    );
  }

  // ======== Helpers de UI ========

  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    );
  }

  Widget _titleRow(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ======== MENÚ INFERIOR “flotante” ========

  Widget _buildFloatingBottomNav(BuildContext context, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF1F2937) // gris azulado oscuro
        : Colors.pink; // MODIFIKE
    final border = isDark
        ? Colors.purple.withOpacity(0.06) // MODIFIKE
        : Colors.black.withOpacity(0.06);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.video_camera_front_outlined),
                  activeIcon: const Icon(Icons.video_camera_front),
                  label: l.navReels,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.phone_outlined),
                  activeIcon: const Icon(Icons.phone),
                  label: l.navPhone,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: l.navProfile,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.group_outlined),
                  activeIcon: const Icon(Icons.group),
                  label: l.navGroups,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  label: l.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
