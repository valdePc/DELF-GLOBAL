// lib/screens/principal.dart — FIX estable (orden correcto: último primero)
// 1) CHATS: ya vienen por Firestore ordenados por updatedAt DESC.
// 2) CONTACTOS: se guardan con createdAt/lastTouchedAt y se ordenan por lastTouchedAt DESC.
//    - Al agregar contacto: se normaliza y sube arriba.
//    - Al abrir/crear chat o invitar: se “bumpea” (lastTouchedAt = now) y sube arriba.
// 3) Sin romper funcionalidades existentes.
// 4) SWIPE CONTACTOS: Derecha = Eliminar (confirma). Izquierda = Archivar / Bloquear (persistente).
// 5) UI polish: contactos premium, anillos de estados con degradé, FAB extendido onScroll,
//    bottom bar con frosted glass, snackbars con icono, confirmaciones en bottom sheet.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // para ImageFilter (blur)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'add_contact.dart';
import 'chat_screen.dart';
import 'configuracion_screen.dart';
import 'grupos.dart';
import 'reels.dart';
import 'status_viewer.dart';
import 'telefono.dart';

import 'package:delf_global/services/chat_service.dart';
import 'package:delf_global/services/user_directory.dart';
import 'package:delf_global/app_config.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

String buildInviteUrl(String refUid) => '$APP_INVITE_URL?ref=$refUid';

/// --- Helper para mostrar el error REAL (evita "Dart exception thrown from converted Future")
String describeError(Object e, StackTrace st) {
  if (e is AsyncError) {
    final inner = e.error;
    final s = e.stackTrace ?? st;
    if (inner is FirebaseException) {
      return '[${inner.plugin}/${inner.code}] ${inner.message ?? 'Firebase error'}';
    }
    return '$inner\n$s';
  }
  if (e is FirebaseException) {
    return '[${e.plugin}/${e.code}] ${e.message ?? 'Firebase error'}';
  }
  return '$e';
}

/// Modelo (libreta local)
class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String avatarUrl;

  /// Timestamps para ordenar
  final int? createdAt;     // millisSinceEpoch
  final int? lastTouchedAt; // millisSinceEpoch

  /// Flags persistentes
  final bool isArchived;
  final bool isBlocked;

  Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarUrl = '',
    this.createdAt,
    this.lastTouchedAt,
    this.isArchived = false,
    this.isBlocked = false,
  });

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        avatarUrl: map['avatarUrl'] as String? ?? '',
        createdAt: map['createdAt'] is int ? (map['createdAt'] as int) : null,
        lastTouchedAt:
            map['lastTouchedAt'] is int ? (map['lastTouchedAt'] as int) : null,
        isArchived: map['isArchived'] == true,
        isBlocked: map['isBlocked'] == true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
        if (createdAt != null) 'createdAt': createdAt,
        if (lastTouchedAt != null) 'lastTouchedAt': lastTouchedAt,
        'isArchived': isArchived,
        'isBlocked': isBlocked,
      };

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    int? createdAt,
    int? lastTouchedAt,
    bool? isArchived,
    bool? isBlocked,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastTouchedAt: lastTouchedAt ?? this.lastTouchedAt,
      isArchived: isArchived ?? this.isArchived,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({Key? key}) : super(key: key);
  @override
  _PrincipalScreenState createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  // Estados (persistencia local)
  List<Map<String, dynamic>> statuses = [];
  // Libreta local de contactos
  List<Contact> contacts = [];
  // Lista de chats mostrados (derivada de Firestore)
  List<Map<String, dynamic>> chats = [];

  final Map<String, Map<String, dynamic>> _userCache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSub;

  int _selectedIndex = 2;

  // --- UI state
  final ScrollController _scroll = ScrollController();
  bool _fabExtended = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeMyChats();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final showExtended = _scroll.positions.isNotEmpty && _scroll.offset <= 8;
    if (showExtended != _fabExtended) {
      setState(() => _fabExtended = showExtended);
    }
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  // ===================== PERSISTENCIA CONTACTOS =====================
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = contacts.map((c) => c.toMap()).toList();
    await prefs.setString('contacts', json.encode(list));
  }

  void _sortContacts() {
    contacts.sort((a, b) {
      int aval = (a.lastTouchedAt ?? a.createdAt ?? 0);
      int bval = (b.lastTouchedAt ?? b.createdAt ?? 0);
      return bval.compareTo(aval); // DESC → último primero
    });
  }

  Future<void> _touchContact(String contactId) async {
    final idx = contacts.indexWhere((c) => c.id == contactId);
    if (idx == -1) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    contacts[idx] = contacts[idx].copyWith(lastTouchedAt: now);
    _sortContacts();
    await _saveContacts();
    if (mounted) setState(() {});
  }

  // Helpers Archivar/Bloquear/Eliminar (persistencia + UX)
  Future<void> _archiveContact(Contact c) async {
    HapticFeedback.lightImpact();
    final idx = contacts.indexWhere((x) => x.id == c.id);
    if (idx == -1) return;
    contacts[idx] = contacts[idx].copyWith(isArchived: true);
    await _saveContacts();
    if (!mounted) return;
    setState(() {});
    _snackWithIcon('Contacto archivado: ${c.name}', Icons.archive_outlined,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            final i2 = contacts.indexWhere((x) => x.id == c.id);
            if (i2 != -1) {
              contacts[i2] = contacts[i2].copyWith(isArchived: false);
              await _saveContacts();
              if (mounted) setState(() {});
            }
          },
        ));
  }

  Future<void> _blockContact(Contact c) async {
    final confirmed = await _confirmSheet(
      title: 'Bloquear contacto',
      message:
          'No podrás enviar ni recibir mensajes de ${c.name} hasta que lo desbloquees.',
      confirmText: 'Bloquear',
      confirmColor: Colors.black87,
      icon: Icons.block,
    );
    if (confirmed != true) return;

    HapticFeedback.lightImpact();
    final idx = contacts.indexWhere((x) => x.id == c.id);
    if (idx == -1) return;
    contacts[idx] = contacts[idx].copyWith(isBlocked: true);
    await _saveContacts();
    if (!mounted) return;
    setState(() {});
    _snackWithIcon('Contacto bloqueado: ${c.name}', Icons.block,
        action: SnackBarAction(
          label: 'Desbloquear',
          onPressed: () async {
            final i2 = contacts.indexWhere((x) => x.id == c.id);
            if (i2 != -1) {
              contacts[i2] = contacts[i2].copyWith(isBlocked: false);
              await _saveContacts();
              if (mounted) setState(() {});
            }
          },
        ));
  }

  Future<void> _deleteContact(Contact c) async {
    final confirmed = await _confirmSheet(
      title: 'Eliminar contacto',
      message: 'Se eliminará “${c.name}” de tu lista de contactos.',
      confirmText: 'Eliminar',
      confirmColor: Colors.red,
      icon: Icons.delete_outline,
    );
    if (confirmed != true) return;

    HapticFeedback.lightImpact();
    // Guardamos copia para UNDO
    final backup = c;
    contacts.removeWhere((x) => x.id == c.id);
    await _saveContacts();
    if (!mounted) return;
    setState(() {});

    _snackWithIcon('Contacto eliminado: ${c.name}', Icons.delete_outline,
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            contacts.add(backup);
            _sortContacts();
            await _saveContacts();
            if (mounted) setState(() {});
          },
        ));
  }

  void _snackWithIcon(String text, IconData icon, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        action: action,
      ),
    );
  }

  Future<bool?> _confirmSheet({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== INVITAR / ABRIR CHAT =====================
  Future<void> _openChatOrInvite(Contact c) async {
    // Bloqueo coherente: no permitir abrir chat si está bloqueado
    if (c.isBlocked) {
      if (!mounted) return;
      _snackWithIcon('Has bloqueado a ${c.name}. Desbloquéalo para chatear.',
          Icons.block);
      return;
    }

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      if (!context.mounted) return;
      _snackWithIcon('Debes iniciar sesión', Icons.info_outline);
      return;
    }

    // 1) Validar que el contacto tenga un handle (tel/email)
    final String? phone =
        (c.phone?.trim().isNotEmpty == true) ? c.phone!.trim() : null;
    final String? email = (c.email?.trim().isNotEmpty == true)
        ? c.email!.trim().toLowerCase()
        : null;

    if (phone == null && email == null) {
      if (!context.mounted) return;
      _snackWithIcon(
          'Este contacto no tiene teléfono ni email. Edita el contacto para agregar uno.',
          Icons.edit_outlined);
      return;
    }

    try {
      // 2) Resolver UID del otro usuario (debe existir en users/)
      String? otherUid =
          await UserDirectory.resolveUidByHandle(phone: phone, email: email);

      // 3) Si no existe -> invitar (sin crashear). Igual lo “bumpeamos”.
      if (otherUid == null) {
        final inviteLink = buildInviteUrl(myUid);
        await _showInviteDialog(
          context,
          nombre: c.name,
          phone: phone,
          email: email,
          inviteLink: inviteLink,
        );
        await _touchContact(c.id); // mover arriba por última interacción
        return;
      }

      // 4) Evitar chat conmigo mismo
      if (otherUid == myUid) {
        if (!context.mounted) return;
        _snackWithIcon('No puedes chatear contigo mismo.', Icons.person_outline);
        return;
      }

      // 5) Crear/abrir 1-a-1 y navegar
      final chatId = await ChatService.getOrCreate1to1(otherUid);
      if (!mounted) return;

      // Bumpeamos contacto por interacción
      await _touchContact(c.id);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            contactName: c.name, // nombre que tú guardaste del otro
            phone: phone ?? (email ?? ''),
            profilePic: '',
          ),
        ),
      );
    } catch (e, st) {
      final msg = describeError(e, st);
      if (!mounted) return;
      _snackWithIcon('No se pudo abrir el chat: $msg', Icons.error_outline);
    }
  }

  Future<void> _showInviteDialog(
    BuildContext context, {
    required String nombre,
    String? phone,
    String? email,
    required String inviteLink,
  }) async {
    final String mensaje =
        '¡Hola $nombre! Te invito a unirte a Delf para chatear conmigo. '
        'Regístrate aquí: $inviteLink';

    Future<void> _inviteViaSms(String? toPhone) async {
      final uri = Uri(
        scheme: 'sms',
        path: (toPhone ?? '').trim(),
        queryParameters: {'body': mensaje},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        _snackWithIcon('No se pudo abrir SMS', Icons.sms_failed_outlined);
      }
    }

    Future<void> _inviteViaEmail(String? toEmail) async {
      final uri = Uri(
        scheme: 'mailto',
        path: (toEmail ?? '').trim(),
        queryParameters: {'subject': 'Únete a Delf', 'body': mensaje},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        _snackWithIcon('No se pudo abrir Email', Icons.email_outlined);
      }
    }

    // Dialog rápido
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('No está en la app'),
        content: Text(
            'Para poder chatear, $nombre debe registrarse. ¿Copiar enlace de invitación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inviteLink));
              if (!context.mounted) return;
              Navigator.pop(context);
              _snackWithIcon('Enlace copiado', Icons.link_outlined);
            },
            child: const Text('Copiar enlace'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    // Opciones extendidas
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 8,
            children: [
              Center(
                child: Text('Invitar a $nombre',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const Divider(),
              if ((phone ?? '').trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.sms),
                  title: const Text('Enviar SMS'),
                  subtitle: Text(phone!),
                  onTap: () {
                    Navigator.pop(context);
                    _inviteViaSms(phone);
                  },
                ),
              if ((email ?? '').trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Enviar correo'),
                  subtitle: Text(email!),
                  onTap: () {
                    Navigator.pop(context);
                    _inviteViaEmail(email);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copiar enlace'),
                subtitle: Text(inviteLink,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: inviteLink));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _snackWithIcon('Enlace copiado', Icons.link_outlined);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== CARGA LOCAL (estados/agenda/contacts) =====================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final statusesString = prefs.getString('statuses');
    statuses = statusesString != null
        ? (json.decode(statusesString) as List).cast<Map<String, dynamic>>()
        : [];

    final contactsString = prefs.getString('contacts');
    final rawContacts = contactsString != null
        ? (json.decode(contactsString) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    contacts = rawContacts.map((m) => Contact.fromMap(m)).toList();

    // Normalizar timestamps y ordenar
    final now = DateTime.now().millisecondsSinceEpoch;
    bool changed = false;
    contacts = contacts.map((c) {
      int? created = c.createdAt ?? now;
      int? touched = c.lastTouchedAt ?? created;
      if (c.createdAt == null || c.lastTouchedAt == null) changed = true;
      return c.copyWith(createdAt: created, lastTouchedAt: touched);
    }).toList();

    _sortContacts();
    if (changed) {
      await _saveContacts();
    }

    if (mounted) setState(() {});
  }

  // ===================== STREAM DE CHATS (Tiempo real) =====================
  void _subscribeMyChats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _chatsSub?.cancel();
    _chatsSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final List<Map<String, dynamic>> next = [];

      for (final d in snapshot.docs) {
        final data = d.data();
        final parts = List<String>.from(data['participants'] ?? const []);
        if (parts.length < 2) continue;

        final otherUid = parts.firstWhere((x) => x != uid, orElse: () => '');
        if (otherUid.isEmpty) continue;

        // Cache de usuario
        _userCache[otherUid] ??= {};
        if (_userCache[otherUid]!.isEmpty) {
          try {
            final u = await UserDirectory.getUserPublic(otherUid);
            _userCache[otherUid] = u ?? {};
          } catch (_) {}
        }
        final u = _userCache[otherUid] ?? {};

        final displayName = (u['fullName'] as String?) ??
            (data['nameMap']?[otherUid] as String?) ??
            'Contacto';
        final photoUrl = (u['photoUrl'] as String?) ?? '';
        final handle =
            (u['email'] as String?) ?? (u['phoneE164'] as String?) ?? '';

        next.add({
          'chatId': data['id'] ?? d.id,
          'contactName': displayName,
          'profilePic': photoUrl,
          'handle': handle, // para subtítulo si no hay último mensaje
          'phone': u['phoneE164'],
          'email': u['email'],
          'lastMessage': data['ultimoMensaje'] ?? '',
          'unreadCount': 0,
        });
      }

      if (mounted) setState(() => chats = next);
    }, onError: (e, st) {
      final msg = (e is FirebaseException)
          ? '[${e.plugin}/${e.code}] ${e.message}'
          : e.toString();
      // ignore: avoid_print
      print('chats stream error: $msg\n$st');
      if (mounted) {
        _snackWithIcon('Error cargando chats: $msg', Icons.error_outline);
      }
    });
  }

  // ===================== ESTADOS (UI) =====================
  Future<void> _addNewStatus() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final newStatus = {
        'contactId': 'me',
        'contactName': 'Tú',
        'imageUrl': pickedFile.path,
        'viewed': false,
      };
      statuses.insert(0, newStatus);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('statuses', json.encode(statuses));
      if (mounted) setState(() {});
    }
  }

  // ===================== LISTAS =====================
  Widget _buildChatListScreen() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var s in statuses) {
      if (s['contactId'] != 'me') {
        grouped.putIfAbsent(s['contactId'], () => []).add(s);
      }
    }
    final statusIds = grouped.keys.toList();

    return Column(
      children: [
        // Carrusel de estados (con anillo degradé)
         Container(
         height: 124, // o 122 si quieres más justo
         padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: statusIds.length + 1,
            itemBuilder: (context, idx) {
              if (idx == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    onTap: _addNewStatus,
                    child: Column(
                      children: [
                        _statusAvatar(
                          imageUrl: null,
                          hasUnviewed: true,
                          isSelf: true,
                        ),
                        const SizedBox(height: 6),
                        const Text('Mi estado', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              final cid = statusIds[idx - 1];
              final myStatuses =
                  grouped[cid] ?? const <Map<String, dynamic>>[];
              if (myStatuses.isEmpty) return const SizedBox.shrink();
              final hasUnviewed = myStatuses.any((s) => s['viewed'] == false);
              final displayStatus = myStatuses.first;

              final matches = contacts.where((c) => c.id == cid);
              final contactName =
                  matches.isNotEmpty ? matches.first.name : 'Contacto';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewerScreen(
                          status: displayStatus,
                          allStatuses: myStatuses,
                          initialIndex: 0,
                        ),
                      ),
                    );
                    if (updated == true) _loadData();
                  },
                  child: Column(
                    children: [
                      _statusAvatar(
                        imageUrl: displayStatus['imageUrl'],
                        hasUnviewed: hasUnviewed,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 78,
                        child: Text(
                          contactName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),

        // Lista combinada: CHATS (si hay) + CONTACTOS (siempre)
        Expanded(
          child: ListView(
            controller: _scroll,
            children: [
              if (chats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('Chats',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                _buildChatsListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                _sectionDivider(),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text('Contactos',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              _buildContactsListView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatsListView(
          {bool shrinkWrap = false, ScrollPhysics? physics}) =>
      ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: chats.length,
        itemBuilder: (context, i) {
          final chat = chats[i];
          return Dismissible(
            key: Key(chat['chatId']?.toString() ?? i.toString()),
            background: _swipeBg(
              alignLeft: true,
              color: Colors.red,
              icon: Icons.delete,
              label: 'Eliminar',
            ),
            secondaryBackground: _swipeBg(
              alignLeft: false,
              color: Colors.blueGrey.shade700,
              icon: Icons.archive,
              label: 'Archivar',
            ),
            confirmDismiss: (direction) async {
              // Aquí podrías implementar borrar/archivar en Firestore si quieres
              _snackWithIcon('Acción no implementada en servidor',
                  Icons.info_outline);
              return false; // por ahora, no borramos del servidor
            },
            child: _chatTile(chat),
          );
        },
      );

  // --- CONTACTOS con Slidable premium
  Widget _buildContactsListView() {
    // Ocultar archivados/bloqueados del listado principal (más fiel a WhatsApp).
    final visibleContacts = contacts
        .where((c) => !c.isArchived && !c.isBlocked)
        .toList(growable: false);

    if (visibleContacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Column(
          children: [
            const Icon(Icons.contact_page_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              'No tienes contactos aún. Toca “+” para agregar uno.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleContacts.length,
      separatorBuilder: (_, __) => _itemDivider(),
      itemBuilder: (context, i) {
        final c = visibleContacts[i];
        return Slidable(
          key: ValueKey('contact_${c.id}'),
          // Deslizar a la derecha → Eliminar (zafacón)
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.30,
            children: [
              SlidableAction(
                onPressed: (_) => _deleteContact(c),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Eliminar',
                borderRadius: BorderRadius.circular(14),
              ),
            ],
          ),
          // Deslizar a la izquierda → Archivar / Bloquear
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.60,
            children: [
              SlidableAction(
                onPressed: (_) => _archiveContact(c),
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                icon: Icons.archive,
                label: 'Archivar',
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 6),
              SlidableAction(
                onPressed: (_) => _blockContact(c),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                icon: Icons.block,
                label: 'Bloquear',
                borderRadius: BorderRadius.circular(14),
              ),
            ],
          ),
          child: _contactTile(c),
        );
      },
    );
  }

  // ===================== NAV =====================
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    late Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const ReelsScreen();
        break;
      case 1:
        targetScreen = const TelefonoScreen();
        break;
      case 3:
        targetScreen = const GruposScreen();
        break;
      case 4:
        targetScreen = const ConfiguracionScreen();
        break;
      default:
        targetScreen = const PrincipalScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showExtended = _fabExtended;
    return Scaffold(
      body: _buildChatListScreen(),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: showExtended
            ? FloatingActionButton.extended(
                key: const ValueKey('fab_ext'),
                onPressed: _onAddContactPressed,
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo contacto'),
              )
            : FloatingActionButton(
                key: const ValueKey('fab_round'),
                onPressed: _onAddContactPressed,
                child: const Icon(Icons.person_add),
              ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xCC1B2735), Color(0xCC415A77)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.white70,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.video_camera_front_outlined), label: 'Reels'),
                BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Teléfono'),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
                BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Grupos'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: 'Configuración'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddContactPressed() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
    if (added == true) {
      await _loadData(); // normaliza/ordena y refleja arriba
    }
  }

  // ===================== WIDGETS UI “premium” =====================

  Widget _statusAvatar({
    required String? imageUrl,
    required bool hasUnviewed,
    bool isSelf = false,
  }) {
    final ringGradient = hasUnviewed
        ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)])
        : LinearGradient(colors: [
            Theme.of(context).dividerColor,
            Theme.of(context).dividerColor
          ]);

    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      width: 78,
      height: 78,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ringGradient,
        boxShadow: [
          if (hasUnviewed)
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Container(
        decoration:
            BoxDecoration(color: bg, shape: BoxShape.circle),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: imageUrl != null
              ? (imageUrl.toString().startsWith('http') || kIsWeb
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Image.file(File(imageUrl), fit: BoxFit.cover))
              : CircleAvatar(
                  backgroundColor: Colors.grey.shade400,
                  child: Icon(
                    isSelf ? Icons.add_a_photo : Icons.person,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _itemDivider() => Padding(
        padding: const EdgeInsets.only(left: 88.0),
        child: Divider(
          height: 0.6,
          thickness: 0.6,
          color: Theme.of(context).dividerColor.withOpacity(0.6),
        ),
      );

  Widget _sectionDivider() => Divider(
        height: 12,
        thickness: 0.8,
        color: Theme.of(context).dividerColor.withOpacity(0.4),
      );

  Widget _contactTile(Contact c) {
    final hasPhoto = c.avatarUrl.isNotEmpty;
    return InkWell(
      onTap: () async {
        try {
          await _openChatOrInvite(c);
        } catch (e, st) {
          final msg = describeError(e, st);
          if (!mounted) return;
          _snackWithIcon('Error al abrir el chat: $msg', Icons.error_outline);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            _avatar(hasPhoto ? null : _initials(c.name), photoUrl: c.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    c.phone ?? c.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.75)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatWhen(c.lastTouchedAt ?? c.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.color
                      ?.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatTile(Map<String, dynamic> chat) {
    final profilePic = (chat['profilePic'] as String?) ?? '';
    final name = chat['contactName'] ?? 'Chat';
    final subtitle = (((chat['lastMessage'] as String?)?.trim() ?? '').isNotEmpty)
        ? (chat['lastMessage'] as String)
        : ((chat['handle'] as String?) ?? '');
    final unread = chat['unreadCount'] ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
            profilePic.isNotEmpty
            ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(profilePic))
  : _avatar(_initials(name)),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.75)),
                      ),
                    ]),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ]
            ],
          ),
        ),
        _itemDivider(),
      ],
    );
  }

  Widget _avatar(String? initials, {String? photoUrl}) {
    if ((photoUrl ?? '').isNotEmpty) {
      return CircleAvatar(radius: 28, backgroundImage: NetworkImage(photoUrl!));
    }
    // Fallback con degradé + iniciales
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          (initials ?? '👤'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '??';
    String first = parts.first.isNotEmpty ? parts.first[0] : '';
    String last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String _formatWhen(int? millis) {
    if (millis == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  Widget _swipeBg({
    required bool alignLeft,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      color: color,
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignLeft) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ] else ...[
              Text(label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
